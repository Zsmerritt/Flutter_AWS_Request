// Copyright (c) 2021, Zachary Merritt.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

library mock_aws_request;

import 'package:aws_request/src/request.dart';
import 'package:http/http.dart';

export 'package:aws_request/src/request.dart'
    show AwsRequestType, AwsRequestException;

/// A mock version of [AwsRequest] for tests.
///
/// Credential fields are mutable to mirror [AwsRequest]; do not log instances
/// that hold secrets.
class MockAwsRequest {
  /// The aws service you are sending a request to
  String? service;

  /// AWS access key
  String awsAccessKey;

  /// AWS secret key
  String awsSecretKey;

  /// The region to send the request to
  String region;

  /// The timeout on the request
  Duration timeout;

  /// Optional custom endpoint hostname
  String? endpoint;

  /// The function used to specify responses
  Future<Response> Function(Request) mockFunction;

  MockAwsRequest({
    required this.awsAccessKey,
    required this.awsSecretKey,
    required this.region,
    required this.mockFunction,
    this.service,
    this.timeout = const Duration(seconds: 10),
    this.endpoint,
  });

  /// Statically Builds, signs, and mocks an aws http request.
  ///
  /// type: request type [GET, POST, PUT, etc]
  ///
  /// service: aws service you are sending request to
  ///
  /// signedHeaders: a list of headers aws requires in the signature.
  ///
  ///    Default included signed headers are: [content-type, host, x-amz-date]
  ///
  ///    (You do not need to provide these in headers)
  ///
  /// headers: any required headers. Any non-default headers included in the signedHeaders must be added here.
  ///
  /// jsonBody: the body of the request, formatted as json
  ///
  /// queryPath: the aws query path
  ///
  /// queryString: the url query string as a Map
  static Future<Response> staticSend({
    required String awsAccessKey,
    required String awsSecretKey,
    required String region,
    required String service,
    required AwsRequestType type,
    required Future<Response> Function(Request) mockFunction,
    List<String> signedHeaders = const [],
    Map<String, String> headers = defaultHeaders,
    String jsonBody = '',
    String queryPath = '/',
    Map<String, String>? queryString,
    Duration timeout = const Duration(seconds: 10),
    String? endpoint,
  }) async {
    return AwsHttpRequest.send(
      awsAccessKey: awsAccessKey,
      awsSecretKey: awsSecretKey,
      region: region,
      type: type,
      service: service,
      signedHeaders: signedHeaders,
      headers: headers,
      jsonBody: jsonBody,
      canonicalUri: queryPath,
      canonicalQuery: queryString,
      timeout: timeout,
      endpoint: endpoint,
      mockRequest: true,
      mockFunction: mockFunction,
    );
  }

  /// Builds, signs, and mocks aws http requests.
  ///
  /// type: request type [GET, POST, PUT, etc]
  ///
  /// service: aws service you are sending request to
  ///
  /// signedHeaders: a list of headers aws requires in the signature.
  ///
  ///    Default included signed headers are: [content-type, host, x-amz-date]
  ///
  ///    (You do not need to provide these in headers)
  ///
  /// headers: any required headers. Any non-default headers included in the signedHeaders must be added here.
  ///
  /// jsonBody: the body of the request, formatted as json
  ///
  /// queryPath: the aws query path
  ///
  /// queryString: the url query string as a Map
  ///
  /// timeout: overrides constructor request timeout
  Future<Response> send({
    required AwsRequestType type,
    String? service,
    List<String> signedHeaders = const [],
    Map<String, String> headers = defaultHeaders,
    String jsonBody = '',
    String queryPath = '/',
    Map<String, String>? queryString,
    Duration? timeout,
    String? endpoint,
  }) async {
    validateRequest(service ?? this.service);
    return AwsHttpRequest.send(
      awsAccessKey: awsAccessKey,
      awsSecretKey: awsSecretKey,
      region: region,
      type: type,
      service: service ?? this.service!,
      signedHeaders: signedHeaders,
      headers: headers,
      jsonBody: jsonBody,
      canonicalUri: queryPath,
      canonicalQuery: queryString,
      timeout: timeout ?? this.timeout,
      endpoint: endpoint ?? this.endpoint,
      mockRequest: true,
      mockFunction: mockFunction,
    );
  }
}
