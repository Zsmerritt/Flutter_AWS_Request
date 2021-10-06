import 'package:http/http.dart';

import 'request.dart';
import 'util.dart';

class AwsRequest {
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
    required String awsAccessKey,
    required String awsSecretKey,
    required String region,
    required String service,
    required String target,
    required AwsRequestType type,
    List<String> signedHeaders: const [],
    Map<String, String> headers = defaultHeaders,
    String jsonBody: '',
    String queryPath: '/',
    Map<String, dynamic>? queryString,
  }) async {
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
      timeout: const Duration(seconds: 10),
    );
  }
}
