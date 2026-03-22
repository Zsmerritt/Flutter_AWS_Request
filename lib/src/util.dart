part of 'request.dart';

/// Special exception class to identify exceptions from AwsRequest
class AwsRequestException implements Exception {
  final String message;
  final StackTrace stackTrace;

  /// A custom error to identify AwsRequest errors more easily
  ///
  /// message: the cause of the error
  /// stackTrace: the stack trace of the error
  AwsRequestException({required this.message, required this.stackTrace});

  /// AwsRequestException toString
  @override
  String toString() {
    return 'AwsRequestException - message: $message\n$stackTrace';
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

void validateRequest(String? service) {
  if (service == null) {
    throw AwsRequestException(
      message:
          'AwsRequestException: No Service Provided. Please pass in a service or set it in the constructor.',
      stackTrace: StackTrace.current,
    );
  }
}
