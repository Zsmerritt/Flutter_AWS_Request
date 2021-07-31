library aws_request;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:universal_io/io.dart';

class AwsRequestException implements Exception {
  String message;
  String cause;

  AwsRequestException(String message)
      : this.cause = message,
        this.message = message;
}

class AwsRequest {
  // Public
  /// The aws service you are sending a request to
  String? service;

  /// The api you are targeting (ie Logs_XXXXXXXX.PutLogEvents)
  String? target;

  // Private
  String _awsAccessKey;
  String _awsSecretKey;
  String _region;
  HttpClient _httpClient = new HttpClient();
  static const Map<String, String> _defaultHeaders = {
    'User-Agent': 'Dart (dart:io)',
    'Accept-Encoding': 'gzip, deflate',
    'Accept': '*/*',
    'Connection': 'keep-alive',
    'Content-Type': 'application/x-amz-json-1.1',
  };

  AwsRequest(
    this._awsAccessKey,
    this._awsSecretKey,
    this._region, {
    this.service,
    this.target,
  });

  /// Builds, signs, and sends aws http requests.
  /// type: request type [GET, POST, PUT, etc]
  /// service: aws service you are sending request to
  /// target: The api you are targeting (ie Logs_XXXXXXXX.PutLogEvents)
  /// signedHeaders: a list of headers aws requires in the signature.
  ///    Default included signed headers are: [content-type, host, x-amz-date, x-amz-target]
  ///    (You do not need to provide these in headers)
  /// headers: any required headers. Any non-default headers included in the signedHeaders must be added here.
  /// jsonBody: the body of the request, formatted as json
  /// queryPath: the aws query path
  /// queryString: the aws query string, formatted like ['abc=123&def=456']. Must be url encoded
  Future<HttpClientResponse> send(
    String type, {
    String? service,
    String? target,
    List<String>? signedHeaders,
    Map<String, String> headers = AwsRequest._defaultHeaders,
    String jsonBody: '',
    String queryPath: '/',
    String queryString: '',
  }) async {
    return _send(
      type: type,
      service: service,
      target: target,
      signedHeaders: signedHeaders,
      headers: headers,
      jsonBody: jsonBody,
      canonicalUri: queryPath,
      canonicalQuerystring: queryString,
    );
  }

  Map<String, String> _getSignedHeaders(
      Map<String, String> headers,
      List<String> signedHeaderNames,
      String target,
      String host,
      String amzDate) {
    Map<String, String> signedHeaders = {
      'host': host,
      'x-amz-date': amzDate,
      'x-amz-target': target
    };
    for (String key in signedHeaderNames) {
      if (!signedHeaders.containsKey(key) && headers.containsKey(key)) {
        signedHeaders[key] = headers[key]!;
      } else {
        throw AwsRequestException('AwsRequest ERROR: Signed Header Not Found: '
            '$key could not be found in the included headers. '
            'Provided header keys are ${headers.keys.toList()}'
            'All headers besides [content-type, host, x-amz-date, x-amz-target] '
            'that are included in signedHeaders must be included in headers');
      }
    }
    if (headers.containsKey('content-type')) {
      signedHeaders['content-type'] = headers['content-type']!;
    } else {
      signedHeaders['content-type'] = 'application/x-amz-json-1.1';
    }
    return signedHeaders;
  }

  dynamic _sign(List<int> key, String msg, {bool? hex}) {
    if (hex != null && hex) {
      return Hmac(sha256, key).convert(utf8.encode(msg)).toString();
    } else {
      return Hmac(sha256, key).convert(utf8.encode(msg)).bytes;
    }
  }

  String _getSignature(
    String key,
    String dateStamp,
    String regionName,
    String serviceName,
    String stringToSign,
  ) {
    List<int> kDate = _sign(utf8.encode('AWS4' + key), dateStamp);
    List<int> kRegion = _sign(kDate, regionName);
    List<int> kService = _sign(kRegion, serviceName);
    List<int> kSigning = _sign(kService, 'aws4_request');
    return _sign(kSigning, stringToSign, hex: true);
  }

  String _getCanonicalRequest(
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

  String _getAuth(
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
    String signature = _getSignature(
      this._awsSecretKey,
      dateStamp,
      region,
      service,
      stringToSign,
    );
    List<String> keyList = signedHeaders.keys.toList();
    keyList.sort();
    String signedHeaderKeys = keyList.join(';');
    return '$algorithm Credential=${this._awsAccessKey}/$credentialScope, '
        'SignedHeaders=$signedHeaderKeys, '
        'Signature=$signature';
  }

  Map<String, String> _getHeaders(
    String host,
    String requestBody,
    Map<String, String> headers,
    String target,
    String amzDate,
    String auth,
  ) {
    return {
      'User-Agent': 'Dart (dart:io)',
      'Accept-Encoding': 'gzip, deflate',
      'Accept': '*/*',
      'Connection': 'keep-alive',
      'Content-Type': 'application/x-amz-json-1.1',
      'Authorization': auth,
      'X-Amz-Date': amzDate,
      'x-amz-target': target,
      'host': host,
      'content-length': utf8.encode(requestBody).length.toString(),
      ...headers
    };
  }

  String _constructUrl(
    String host,
    String canonicalUri,
    String canonicalQuerystring,
  ) {
    if (canonicalQuerystring != '') {
      return 'https://$host$canonicalUri?$canonicalQuerystring';
    }
    return 'https://$host$canonicalUri';
  }

  Map<String, dynamic> _validateRequest(
    String? service,
    String? target,
  ) {
    if (service == null) {
      return {
        'valid': false,
        'error':
            'No Service Provided. Please pass in a service or set one with '
                'AwsRequest.setService(String serviceName)'
      };
    }
    if (target == null) {
      return {
        'valid': false,
        'error': 'No Target Provided. Please pass in a service or set one with '
            'AwsRequest.setTarget(String targetName)'
      };
    }
    return {'valid': true, 'error': null};
  }

  Future<HttpClientRequest> _getRequest(String type, String url) async {
    switch (type) {
      case 'GET':
        return await _httpClient.getUrl(Uri.parse(url));
      case 'POST':
        return await _httpClient.postUrl(Uri.parse(url));
      case 'DELETE':
        return await _httpClient.deleteUrl(Uri.parse(url));
      case 'PATCH':
        return await _httpClient.patchUrl(Uri.parse(url));
      case 'PUT':
        return await _httpClient.putUrl(Uri.parse(url));
      default:
        throw AwsRequestException(
            'AwsRequest: ERROR: Request type not supported. '
            'Options are: [GET, POST, DELETE, PATCH, PUT]');
    }
  }

  Future<HttpClientResponse> _send({
    required String type,
    String? service,
    String? target,
    List<String>? signedHeaders,
    required Map<String, String> headers,
    required String jsonBody,
    required String canonicalUri,
    required String canonicalQuerystring,
  }) async {
    service ??= this.service;
    target ??= this.target;
    signedHeaders ??= [];

    // validate request
    Map<String, dynamic> validation = _validateRequest(
      service,
      target,
    );
    if (!validation['valid']) {
      throw new AwsRequestException(
          'AwsRequestException: ${validation['error']}');
    }
    // create needed variables
    String host = '$service.${this._region}.amazonaws.com';
    String url = _constructUrl(
      host,
      canonicalUri,
      canonicalQuerystring,
    );
    String amzDate =
        DateFormat("yyyyMMdd'T'HHmmss'Z'").format(DateTime.now().toUtc());
    Map<String, String> signedHeadersMap = _getSignedHeaders(
      headers,
      signedHeaders,
      target!,
      host,
      amzDate,
    );

    // generate canonical request, auth, and headers
    String canonicalRequest = _getCanonicalRequest(
      type,
      jsonBody,
      signedHeadersMap,
      canonicalUri,
      canonicalQuerystring,
    );
    String auth = _getAuth(
      amzDate,
      canonicalRequest,
      this._region,
      service!,
      signedHeadersMap,
    );
    Map<String, String> updatedHeaders = _getHeaders(
      host,
      jsonBody,
      headers,
      target,
      amzDate,
      auth,
    );

    // generate request and add headers
    HttpClientRequest request = await _getRequest(type, url);
    updatedHeaders.forEach((key, value) {
      request.headers.set(key, value);
    });

    // encode body and send request
    request.add(utf8.encode(jsonBody));
    return await request.close();
  }
}
