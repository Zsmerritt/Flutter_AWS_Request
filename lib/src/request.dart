import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:intl/intl.dart';

import 'util.dart';

class AwsHttpRequest {
  static Map<String, String> getSignedHeaders(
      Map<String, String> headers,
      List<String> signedHeaderNames,
      String target,
      String host,
      String amzDate) {
    Map<String, String> signedHeaders = {
      'host': host,
      'x-amz-date': amzDate,
      'x-amz-target': target,
    };
    for (String key in signedHeaderNames) {
      if (!signedHeaders.containsKey(key) && headers.containsKey(key)) {
        signedHeaders[key] = headers[key]!;
      } else {
        throw AwsRequestException(
            message: 'AwsRequest ERROR: Signed Header Not Found: '
                '$key could not be found in the included headers. '
                'Provided header keys are ${headers.keys.toList()} '
                'All headers besides [content-type, host, x-amz-date, x-amz-target] '
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

  static dynamic sign(List<int> key, String msg, {bool? hex}) {
    if (hex != null && hex) {
      return Hmac(sha256, key).convert(utf8.encode(msg)).toString();
    } else {
      return Hmac(sha256, key).convert(utf8.encode(msg)).bytes;
    }
  }

  static String getSignature(
    String key,
    String dateStamp,
    String regionName,
    String serviceName,
    String stringToSign,
  ) {
    List<int> kDate = sign(utf8.encode('AWS4' + key), dateStamp);
    List<int> kRegion = sign(kDate, regionName);
    List<int> kService = sign(kRegion, serviceName);
    List<int> kSigning = sign(kService, 'aws4_request');
    return sign(kSigning, stringToSign, hex: true);
  }

  static String getCanonicalRequest(
      String type,
      String requestBody,
      Map<String, String> signedHeaders,
      String canonicalUri,
      String canonicalQuerystring) {
    List<String> canonicalHeaders = [];
    signedHeaders.forEach((key, value) {
      canonicalHeaders.add('$key:$value\n');
    });
    canonicalHeaders.sort();
    String canonicalHeadersString = canonicalHeaders.join('');
    List<String> keyList = signedHeaders.keys.toList();
    keyList.sort();
    String signedHeaderKeys = keyList.join(';');
    String payloadHash = sha256.convert(utf8.encode(requestBody)).toString();
    String canonicalRequest =
        '$type\n$canonicalUri\n$canonicalQuerystring\n$canonicalHeadersString\n'
        '$signedHeaderKeys\n$payloadHash';
    return canonicalRequest;
  }

  static String getAuth(
    String awsSecretKey,
    String awsAccessKey,
    String amzDate,
    String canonicalRequest,
    String region,
    String service,
    Map<String, String> signedHeaders,
  ) {
    String algorithm = 'AWS4-HMAC-SHA256';
    String dateStamp = DateFormat('yyyyMMdd').format(DateTime.now().toUtc());
    String credentialScope = '$dateStamp/$region/$service/aws4_request';
    String stringToSign = '$algorithm\n$amzDate\n$credentialScope\n'
        '${sha256.convert(utf8.encode(canonicalRequest)).toString()}';
    String signature = getSignature(
      awsSecretKey,
      dateStamp,
      region,
      service,
      stringToSign,
    );
    List<String> keyList = signedHeaders.keys.toList();
    keyList.sort();
    String signedHeaderKeys = keyList.join(';');
    return '$algorithm Credential=$awsAccessKey/$credentialScope, '
        'SignedHeaders=$signedHeaderKeys, '
        'Signature=$signature';
  }

  static Map<String, String> getHeaders(
    String host,
    String requestBody,
    Map<String, String> headers,
    String target,
    String amzDate,
    String auth,
    Duration timeout,
  ) {
    return {
      ...defaultHeaders,
      ...headers,
      ...{
        // We never want these keys overwritten
        'Authorization': auth,
        'X-Amz-Date': amzDate,
        'x-amz-target': target,
      }
    };
  }

  static Future<Response> getRequest(
    AwsRequestType type,
    Uri url,
    Map<String, String> headers,
    String body,
    Duration timeout, {
    bool mockRequest: false,
    Future<Response> Function(Request)? mockFunction,
  }) async {
    if (mockRequest && mockFunction == null) {
      throw new AwsRequestException(
        message: 'Mocking function request to mock AwsRequests',
        stackTrace: StackTrace.current,
      );
    }
    dynamic client = mockRequest ? MockClient(mockFunction!) : Client();
    Future<Response> response;
    switch (type) {
      case AwsRequestType.GET:
        response = client.get(
          url,
          headers: headers,
        );
        break;
      case AwsRequestType.POST:
        response = client.post(
          url,
          headers: headers,
          body: utf8.encode(body),
        );
        break;
      case AwsRequestType.DELETE:
        response = client.delete(
          url,
          headers: headers,
          body: utf8.encode(body),
        );
        break;
      case AwsRequestType.PATCH:
        response = client.patch(
          url,
          headers: headers,
          body: utf8.encode(body),
        );
        break;
      case AwsRequestType.PUT:
        response = client.put(
          url,
          headers: headers,
          body: utf8.encode(body),
        );
        break;
      case AwsRequestType.HEAD:
        response = client.head(
          url,
          headers: headers,
        );
        break;
    }
    return response.timeout(timeout, onTimeout: () {
      client.close();
      throw TimeoutException('AwsRequest Timed Out', timeout);
    });
  }

  static Future<Response> send({
    required String awsSecretKey,
    required String awsAccessKey,
    required AwsRequestType type,
    required String service,
    required String target,
    required String region,
    required Duration timeout,
    List<String> signedHeaders: const [],
    required Map<String, String> headers,
    required String jsonBody,
    required String canonicalUri,
    Map<String, String>? canonicalQuery,
    bool mockRequest: false,
    Future<Response> Function(Request)? mockFunction,
  }) async {
    String host = '$service.$region.amazonaws.com';
    Uri url = Uri(
      scheme: 'https',
      host: host,
      path: canonicalUri,
      queryParameters: canonicalQuery,
    );
    String amzDate =
        DateFormat("yyyyMMdd'T'HHmmss'Z'").format(DateTime.now().toUtc());
    Map<String, String> signedHeadersMap = getSignedHeaders(
      headers,
      signedHeaders,
      target,
      host,
      amzDate,
    );

    // generate canonical request, auth, and headers
    String canonicalRequest = getCanonicalRequest(
      type.toString().split('.').last,
      jsonBody,
      signedHeadersMap,
      canonicalUri,
      url.query,
    );
    String auth = getAuth(
      awsSecretKey,
      awsAccessKey,
      amzDate,
      canonicalRequest,
      region,
      service,
      signedHeadersMap,
    );
    Map<String, String> updatedHeaders = getHeaders(
      host,
      jsonBody,
      headers,
      target,
      amzDate,
      auth,
      timeout,
    );

    // generate request and add headers
    return await getRequest(
      type,
      url,
      updatedHeaders,
      jsonBody,
      timeout,
      mockRequest: mockRequest,
      mockFunction: mockFunction,
    );
  }
}
