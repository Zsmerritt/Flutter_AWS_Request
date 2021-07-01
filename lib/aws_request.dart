library aws_request;

import 'dart:convert';
import 'package:universal_io/io.dart';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

class AwsRequestException implements Exception {
  String message;
  String cause; /// deprecated
  AwsRequestException(String message):
    this.cause = message,
    this.message = message;
}

class AwsRequest {
  // Public
  /// The aws service you are sending a request to
  String? service;

  /// The your instance of the service plus the operation (ie Logs_XXXXXXXX.PutLogEvents)
  String? target;

  // Private
  String _awsAccessKey;
  String _awsSecretKey;
  String _region;
  HttpClient _httpClient = new HttpClient();
  static const Map<String, String> _defaultHeaders = {
    'User-Agent': 'Dart/2.10 (dart:io)',
    'Accept-Encoding': 'gzip, deflate',
    'Accept': '*/*',
    'Connection': 'keep-alive',
    'Content-Type': 'application/x-amz-json-1.1',
  };

  AwsRequest(this._awsAccessKey, this._awsSecretKey, this._region);

  /// Builds, signs, and sends aws http requests.
  /// type: request type [GET, POST, PUT, etc]
  /// service: aws service you are sending request to
  /// target: your instance of that service plus the operation [Logs_XXXXXXXX.PutLogEvents]
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
    String jsonBody = '',
    String queryPath = '/',
    String queryString = '',
  }) async {
    return _send(type, service, target, signedHeaders, headers, jsonBody,
        queryPath, queryString);
  }

  String _getTarget([String? target]) {
    if (target == null) {
      target = this.target;
    }
    return target!;
  }

  String _getService([String? service]) {
    if (service == null) {
      service = this.service;
    }
    return service!;
  }

  Map<String, String?> _getSignedHeaders(
      Map<String, String> headers,
      List<String>? signedHeaderNames,
      String target,
      String host,
      String amzDate) {
    Map<String, String?> signedHeaders = {
      'host': host,
      'x-amz-date': amzDate,
      'x-amz-target': target
    };
    if (signedHeaderNames != null) {
      signedHeaderNames.forEach((key) {
        if (!signedHeaders.containsKey(key) && headers.containsKey(key)) {
          signedHeaders[key] = headers[key];
        } else {
          throw AwsRequestException(
              'AwsRequest ERROR: Signed Header Not Found: '
              '$key could not be found in the included headers. '
              'Provided header keys are ${headers.keys.toList()}'
              'All headers besides [content-type, host, x-amz-date, x-amz-target] '
              'that are included in signedHeaders must be included in headers');
        }
      });
    }
    if (headers.containsKey('content-type')) {
      signedHeaders['content-type'] = headers['content-type'];
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

  String _getSignature(String key, String dateStamp, String regionName,
      String serviceName, String stringToSign) {
    List<int> kDate = _sign(utf8.encode('AWS4' + key), dateStamp);
    List<int> kRegion = _sign(kDate, regionName);
    List<int> kService = _sign(kRegion, serviceName);
    List<int> kSigning = _sign(kService, 'aws4_request');
    return _sign(kSigning, stringToSign, hex: true);
  }

  String _getCanonicalRequest(
      String requestBody,
      Map<String, String?> signedHeaders,
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
        'POST\n$canonicalUri\n$canonicalQuerystring\n$canonicalHeadersString\n$signedHeaderKeys\n$payloadHash';
    return canonicalRequest;
  }

  String _getAuth(String amzDate, String canonicalRequest, String region) {
    String algorithm = 'AWS4-HMAC-SHA256';
    String dateStamp = DateFormat('yyyyMMdd').format(DateTime.now().toUtc());
    String credentialScope = '$dateStamp/$region/logs/aws4_request';
    String stringToSign =
        '$algorithm\n$amzDate\n$credentialScope\n${sha256.convert(utf8.encode(canonicalRequest)).toString()}';
    String signature = _getSignature(
        this._awsSecretKey, dateStamp, region, 'logs', stringToSign);
    return '$algorithm Credential=${this._awsAccessKey}/$credentialScope, SignedHeaders=content-type;host;x-amz-date;x-amz-target, Signature=$signature';
  }

  Map<String, String> _getHeaders(String host, String requestBody,
      Map<String, String> headers, String target, String amzDate, String auth) {
    Map<String, String> defaultHeaders = {
      'User-Agent': 'Dart/2.10 (dart:io)',
      'Accept-Encoding': 'gzip, deflate',
      'Accept': '*/*',
      'Connection': 'keep-alive',
      'Content-Type': 'application/x-amz-json-1.1',
      'Authorization': auth,
      'X-Amz-Date': amzDate,
      'x-amz-target': target,
      'host': host,
      'content-length': utf8.encode(requestBody).length.toString(),
    };
    defaultHeaders.addAll(headers);
    return defaultHeaders;
  }

  String _constructUrl(
      String host, String canonicalUri, String canonicalQuerystring) {
    String url = 'https://$host$canonicalUri';
    if (canonicalQuerystring != '') {
      url = '$url?$canonicalQuerystring';
    }
    return url;
  }

  Map<String, dynamic> _validateRequest(String? service, String? target) {
    if (this.service == null && service == null) {
      return {
        'valid': false,
        'error':
            'No Service Provided. Please pass in a service or set one with AwsRequest.setService(String serviceName)'
      };
    }
    if (this.target == null && target == null) {
      return {
        'valid': false,
        'error':
            'No Target Provided. Please pass in a service or set one with AwsRequest.setTarget(String targetName)'
      };
    }
    return {'valid': true, 'error': null};
  }

  Future<HttpClientRequest> _getRequest(String type, String url) async {
    HttpClientRequest request;
    if (type == 'GET') {
      request = await _httpClient.getUrl(Uri.parse(url));
    } else if (type == 'POST') {
      request = await _httpClient.postUrl(Uri.parse(url));
    } else if (type == 'DELETE') {
      request = await _httpClient.deleteUrl(Uri.parse(url));
    } else if (type == 'PATCH') {
      request = await _httpClient.patchUrl(Uri.parse(url));
    } else if (type == 'PUT') {
      request = await _httpClient.putUrl(Uri.parse(url));
    } else {
      throw AwsRequestException(
          'AwsRequest: ERROR: Request type not supported. Options are: [GET, POST, DELETE, PATCH, PUT]');
    }
    return request;
  }

  Future<HttpClientResponse> _send(
    String type,
    String? service,
    String? target,
    List<String>? signedHeaders,
    Map<String, String> headers,
    String jsonBody,
    String canonicalUri,
    String canonicalQuerystring,
  ) async {
    // set default variables that cant be constant
    service = _getService(service);
    target = _getTarget(target);

    // validate request
    Map<String, dynamic> validation = _validateRequest(service, target);
    if (validation['valid']) {
      // create needed variables
      String host = '$service.${this._region}.amazonaws.com';
      String url = _constructUrl(host, canonicalUri, canonicalQuerystring);
      String amzDate =
          DateFormat("yyyyMMdd'T'HHmmss'Z'").format(DateTime.now().toUtc());
      Map<String, String?> signedHeadersMap =
          _getSignedHeaders(headers, signedHeaders, target, host, amzDate);

      // generate canonical request, auth, and headers
      String canonicalRequest = _getCanonicalRequest(
          jsonBody, signedHeadersMap, canonicalUri, canonicalQuerystring);
      String auth = _getAuth(amzDate, canonicalRequest, this._region);
      Map<String, String> updatedHeaders =
          _getHeaders(host, jsonBody, headers, target, amzDate, auth);

      // generate request and add headers
      HttpClientRequest request = await _getRequest(type, url);
      updatedHeaders.forEach((key, value) {
        request.headers.set(key, value);
      });

      // encode body and send request
      request.add(utf8.encode(jsonBody));
      HttpClientResponse result = await request.close();
      return result;
    } else {
      throw new AwsRequestException(
          'AwsRequestException: ${validation['error']}');
    }
  }
}
