// Copyright (c) 2021, Zachary Merritt.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

library aws_request;

import 'package:aws_request/src/request.dart';
import 'package:http/http.dart';

export 'package:aws_request/src/request.dart'
    show AwsRequestType, AwsRequestException;

/// A class to easily send API requests to AWS services.
///
/// [awsAccessKey], [awsSecretKey], and [region] are mutable so callers can
/// rotate credentials or change region without constructing a new instance.
/// Do not log or expose instances that hold secrets.
///
/// **Temporary credentials (STS, IAM roles, assumed roles):** Supported. Use
/// the temporary access key ID for [awsAccessKey] and the temporary secret
/// for [awsSecretKey] (same as long-lived keys). You must also send the
/// session token: add `X-Amz-Security-Token` to [headers] and include
/// `x-amz-security-token` in [signedHeaders] so it participates in the SigV4
/// signature. Example:
/// `headers: {'X-Amz-Security-Token': sessionToken}`,
/// `signedHeaders: ['x-amz-security-token']`.
class AwsRequest {
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

  /// Optional custom endpoint hostname (e.g., 'mybucket.s3.us-east-1.amazonaws.com').
  /// When null, the standard '{service}.{region}.amazonaws.com' pattern is used.
  String? endpoint;

  AwsRequest({
    required this.awsAccessKey,
    required this.awsSecretKey,
    required this.region,
    this.service,
    this.timeout = const Duration(seconds: 10),
    this.endpoint,
  });

  /// Statically Builds, signs, and sends aws http requests.
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
  /// endpoint: custom hostname override (e.g., 'mybucket.s3.us-east-1.amazonaws.com').
  /// Defaults to '{service}.{region}.amazonaws.com' when null.
  static Future<Response> staticSend({
    required String awsAccessKey,
    required String awsSecretKey,
    required String region,
    required String service,
    required AwsRequestType type,
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
    );
  }

  /// Builds, signs, and sends aws http requests.
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
  ///
  /// endpoint: custom hostname override. Defaults to constructor value,
  /// then '{service}.{region}.amazonaws.com' when null.
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
    );
  }
}
