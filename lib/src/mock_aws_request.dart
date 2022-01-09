import 'package:http/http.dart';

import 'request.dart';
import 'util.dart';

class MockAwsRequest {
  /// The aws service you are sending a request to
  String? service;

  /// The api you are targeting
  String? target;

  /// AWS access key
  String awsAccessKey;

  /// AWS secret key
  String awsSecretKey;

  /// The region to send the request to
  String region;

  /// The timeout on the request
  Duration timeout;

  /// The function used to specify responses
  Future<Response> Function(Request) mockFunction;

  MockAwsRequest(
    this.awsAccessKey,
    this.awsSecretKey,
    this.region, {
    required this.mockFunction,
    this.service,
    this.target,
    this.timeout: const Duration(seconds: 10),
  });

  /// Statically Builds, signs, and sends aws http requests.
  ///
  /// type: request type [GET, POST, PUT, etc]
  ///
  /// service: aws service you are sending request to
  ///
  /// target: The api you are targeting (ie Logs_XXXXXXXX.PutLogEvents)
  ///
  /// signedHeaders: a list of headers aws requires in the signature.
  ///
  ///    Default included signed headers are: [content-type, host, x-amz-date, x-amz-target]
  ///
  ///    (You do not need to provide these in headers)
  ///
  /// headers: any required headers. Any non-default headers included in the signedHeaders must be added here.
  ///
  /// jsonBody: the body of the request, formatted as json
  ///
  /// queryPath: the aws query path
  ///
  /// queryString: the aws query string, formatted like ['abc=123&def=456']. Must be url encoded
  static Future<Response> staticSend(
      {required String awsAccessKey,
      required String awsSecretKey,
      required String region,
      required String service,
      required String target,
      required AwsRequestType type,
      required Future<Response> Function(Request) mockFunction,
      List<String> signedHeaders: const [],
      Map<String, String> headers: defaultHeaders,
      String jsonBody: '',
      String queryPath: '/',
      Map<String, dynamic>? queryString,
      Duration timeout: const Duration(seconds: 10)}) async {
    return AwsHttpRequest.send(
      awsAccessKey: awsAccessKey,
      awsSecretKey: awsSecretKey,
      region: region,
      type: type,
      service: service,
      target: target,
      signedHeaders: signedHeaders,
      headers: headers,
      jsonBody: jsonBody,
      canonicalUri: queryPath,
      canonicalQuery: queryString,
      timeout: timeout,
      mockRequest: true,
      mockFunction: mockFunction,
    );
  }

  /// Builds, signs, and sends aws http requests.
  ///
  /// type: request type [GET, POST, PUT, etc]
  ///
  /// service: aws service you are sending request to
  ///
  /// target: The api you are targeting (ie Logs_XXXXXXXX.PutLogEvents)
  ///
  /// signedHeaders: a list of headers aws requires in the signature.
  ///
  ///    Default included signed headers are: [content-type, host, x-amz-date, x-amz-target]
  ///
  ///    (You do not need to provide these in headers)
  ///
  /// headers: any required headers. Any non-default headers included in the signedHeaders must be added here.
  ///
  /// jsonBody: the body of the request, formatted as json
  ///
  /// queryPath: the aws query path
  ///
  /// queryString: the aws query string, formatted like ['abc=123&def=456']. Must be url encoded
  Future<Response> send({
    required AwsRequestType type,
    String? service,
    String? target,
    List<String> signedHeaders: const [],
    Map<String, String> headers = defaultHeaders,
    String jsonBody: '',
    String queryPath: '/',
    Map<String, dynamic>? queryString,
  }) async {
    // validate request
    Map<String, dynamic> validation = validateRequest(
      service ?? this.service,
      target ?? this.target,
    );
    if (!validation['valid']) {
      throw new AwsRequestException(
          message: 'AwsRequestException: ${validation['error']}',
          stackTrace: StackTrace.current);
    }
    return AwsHttpRequest.send(
      awsAccessKey: awsAccessKey,
      awsSecretKey: awsSecretKey,
      region: region,
      type: type,
      service: service ?? this.service!,
      target: target ?? this.target!,
      signedHeaders: signedHeaders,
      headers: headers,
      jsonBody: jsonBody,
      canonicalUri: queryPath,
      canonicalQuery: queryString,
      timeout: timeout,
      mockRequest: true,
      mockFunction: mockFunction,
    );
  }
}
