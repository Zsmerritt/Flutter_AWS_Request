part of 'request.dart';

/// Special exception class to identify exceptions from AwsRequest
class AwsRequestException implements Exception {
  String message;
  StackTrace stackTrace;

  /// A custom error to identify AwsRequest errors more easily
  ///
  /// message: the cause of the error
  /// stackTrace: the stack trace of the error
  AwsRequestException({required this.message, required this.stackTrace});

  /// AwsRequestException toString
  @override
  String toString() {
    return 'AwsRequestException - message: $message';
  }
}

/// Enum of supported HTTP methods
enum AwsRequestType { get, post, delete, patch, put, head }

/// Default headers included automatically with every request.
/// These can be overridden by passing in a Map with the same keys
const Map<String, String> defaultHeaders = {
  'Accept': '*/*',
  'Content-Type': 'application/x-amz-json-1.1',
};

Map<String, dynamic> validateRequest(
  String? service,
  String? target,
) {
  if (service == null) {
    return {
      'valid': false,
      'error':
          'No Service Provided. Please pass in a service or set it in the constructor.'
    };
  }
  if (target == null) {
    return {
      'valid': false,
      'error':
          'No Target Provided. Please pass in a service or set it in the constructor.'
    };
  }
  return {'valid': true, 'error': null};
}
