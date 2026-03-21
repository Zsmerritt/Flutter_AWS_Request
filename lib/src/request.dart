import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';

part 'util.dart';

class AwsHttpRequest {
  static String _formatAmzDate(DateTime dt) {
    final DateTime utc = dt.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}'
        '${utc.month.toString().padLeft(2, '0')}'
        '${utc.day.toString().padLeft(2, '0')}'
        'T'
        '${utc.hour.toString().padLeft(2, '0')}'
        '${utc.minute.toString().padLeft(2, '0')}'
        '${utc.second.toString().padLeft(2, '0')}'
        'Z';
  }

  static Map<String, String> getSignedHeaders({
    required Map<String, String> headers,
    required List<String> signedHeaderNames,
    required String host,
    required String amzDate,
  }) {
    final Map<String, String> signedHeaders = {
      'host': host,
      'x-amz-date': amzDate,
    };
    for (final String key in signedHeaderNames) {
      if (signedHeaders.containsKey(key)) {
        continue;
      }
      if (headers.containsKey(key)) {
        signedHeaders[key] = headers[key]!;
      } else {
        throw AwsRequestException(
            message: 'AwsRequest ERROR: Signed Header Not Found: '
                '$key could not be found in the included headers. '
                'Provided header keys are ${headers.keys.toList()} '
                'All headers besides [content-type, host, x-amz-date] '
                'that are included in signedHeaders must be included in headers',
            stackTrace: StackTrace.current);
      }
    }
    if (headers.containsKey('content-type')) {
      signedHeaders['content-type'] = headers['content-type']!;
    } else {
      signedHeaders['content-type'] = 'application/x-amz-json-1.1';
    }
    return signedHeaders;
  }

  static Digest sign({required List<int> key, required String msg}) {
    return Hmac(sha256, key).convert(utf8.encode(msg));
  }

  static String getSignature({
    required String key,
    required String dateStamp,
    required String regionName,
    required String serviceName,
    required String stringToSign,
  }) {
    final List<int> kDate = Hmac(sha256, utf8.encode('AWS4$key'))
        .convert(utf8.encode(dateStamp))
        .bytes;
    final List<int> kRegion = sign(key: kDate, msg: regionName).bytes;
    final List<int> kService = sign(key: kRegion, msg: serviceName).bytes;
    final List<int> kSigning = sign(key: kService, msg: 'aws4_request').bytes;
    return sign(key: kSigning, msg: stringToSign).toString();
  }

  static String getCanonicalRequest({
    required String type,
    required String requestBody,
    required Map<String, String> signedHeaders,
    required String canonicalUri,
    required String canonicalQuerystring,
  }) {
    final List<String> canonicalHeaders = [];
    signedHeaders.forEach((key, value) {
      canonicalHeaders.add('$key:$value\n');
    });
    canonicalHeaders.sort();
    final String canonicalHeadersString = canonicalHeaders.join('');
    final List<String> keyList = signedHeaders.keys.toList()..sort();
    final String signedHeaderKeys = keyList.join(';');
    final String payloadHash =
        sha256.convert(utf8.encode(requestBody)).toString();
    final String canonicalRequest =
        '$type\n$canonicalUri\n$canonicalQuerystring\n$canonicalHeadersString\n'
        '$signedHeaderKeys\n$payloadHash';
    return canonicalRequest;
  }

  static String getAuth({
    required String awsSecretKey,
    required String awsAccessKey,
    required String amzDate,
    required String canonicalRequest,
    required String region,
    required String service,
    required Map<String, String> signedHeaders,
  }) {
    const String algorithm = 'AWS4-HMAC-SHA256';
    final String dateStamp = amzDate.substring(0, 8);
    final String credentialScope = '$dateStamp/$region/$service/aws4_request';
    final String stringToSign = '$algorithm\n$amzDate\n$credentialScope\n'
        '${sha256.convert(utf8.encode(canonicalRequest)).toString()}';
    final String signature = getSignature(
      key: awsSecretKey,
      dateStamp: dateStamp,
      regionName: region,
      serviceName: service,
      stringToSign: stringToSign,
    );
    final List<String> keyList = signedHeaders.keys.toList()..sort();
    final String signedHeaderKeys = keyList.join(';');
    return '$algorithm Credential=$awsAccessKey/$credentialScope, '
        'SignedHeaders=$signedHeaderKeys, '
        'Signature=$signature';
  }

  static Map<String, String> getHeaders({
    required Map<String, String> headers,
    required String amzDate,
    required String auth,
  }) {
    return {
      ...defaultHeaders,
      ...headers,
      ...{
        'Authorization': auth,
        'x-amz-date': amzDate,
      }
    };
  }

  static Future<Response> getRequest({
    required AwsRequestType type,
    required Uri url,
    required Map<String, String> headers,
    required String body,
    required Duration timeout,
    bool mockRequest = false,
    Future<Response> Function(Request)? mockFunction,
  }) async {
    if (mockRequest && mockFunction == null) {
      throw AwsRequestException(
        message: 'Mocking function request to mock AwsRequests',
        stackTrace: StackTrace.current,
      );
    }
    final Client client = mockRequest ? MockClient(mockFunction!) : Client();
    try {
      final Future<Response> future;
      switch (type) {
        case AwsRequestType.get:
          future = client.get(
            url,
            headers: headers,
          );
          break;
        case AwsRequestType.post:
          future = client.post(
            url,
            headers: headers,
            body: utf8.encode(body),
          );
          break;
        case AwsRequestType.delete:
          future = client.delete(
            url,
            headers: headers,
            body: utf8.encode(body),
          );
          break;
        case AwsRequestType.patch:
          future = client.patch(
            url,
            headers: headers,
            body: utf8.encode(body),
          );
          break;
        case AwsRequestType.put:
          future = client.put(
            url,
            headers: headers,
            body: utf8.encode(body),
          );
          break;
        case AwsRequestType.head:
          future = client.head(
            url,
            headers: headers,
          );
          break;
      }
      return await future.timeout(timeout, onTimeout: () {
        throw TimeoutException('AwsRequest Timed Out', timeout);
      });
    } finally {
      client.close();
    }
  }

  static Future<Response> send({
    required String awsSecretKey,
    required String awsAccessKey,
    required AwsRequestType type,
    required String service,
    required String region,
    required Duration timeout,
    List<String> signedHeaders = const [],
    required Map<String, String> headers,
    required String jsonBody,
    required String canonicalUri,
    Map<String, String>? canonicalQuery,
    String? endpoint,
    bool mockRequest = false,
    Future<Response> Function(Request)? mockFunction,
  }) async {
    final String host = endpoint ?? '$service.$region.amazonaws.com';
    final Uri url = Uri(
      scheme: 'https',
      host: host,
      path: canonicalUri,
      queryParameters: canonicalQuery,
    );
    final String amzDate = _formatAmzDate(DateTime.now());
    final Map<String, String> signedHeadersMap = getSignedHeaders(
      headers: headers,
      signedHeaderNames: signedHeaders,
      host: host,
      amzDate: amzDate,
    );

    final String canonicalRequest = getCanonicalRequest(
      type: type.name.toUpperCase(),
      requestBody: jsonBody,
      signedHeaders: signedHeadersMap,
      canonicalUri: canonicalUri,
      canonicalQuerystring: url.query,
    );
    final String auth = getAuth(
      awsSecretKey: awsSecretKey,
      awsAccessKey: awsAccessKey,
      amzDate: amzDate,
      canonicalRequest: canonicalRequest,
      region: region,
      service: service,
      signedHeaders: signedHeadersMap,
    );
    final Map<String, String> updatedHeaders = getHeaders(
      headers: headers,
      amzDate: amzDate,
      auth: auth,
    );

    return getRequest(
      type: type,
      url: url,
      headers: updatedHeaders,
      body: jsonBody,
      timeout: timeout,
      mockRequest: mockRequest,
      mockFunction: mockFunction,
    );
  }
}
