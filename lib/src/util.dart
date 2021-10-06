/// Special exception class to identify exceptions from AwsRequest
class AwsRequestException implements Exception {
  String? message;
  StackTrace? stackTrace;
  String? type;
  String? raw;

  /// A custom error to identify AwsRequest errors more easily
  ///
  /// message: the cause of the error
  /// stackTrace: the stack trace of the error
  AwsRequestException(
      {required this.message, required this.stackTrace, this.type, this.raw});

  /// AwsRequestException toString
  String toString() {
    if (type != null) {
      return "AwsRequestException - type: $type, message: $message";
    }
    return "AwsRequestException - message: $message";
  }
}

/// Enum of supported HTTP methods
enum AwsRequestType { GET, POST, DELETE, PATCH, PUT, HEAD }

/// Default headers included automatically with every request.
/// These can be overridden by passing in a Map with the same keys
const Map<String, String> defaultHeaders = {
  'User-Agent': 'Dart (dart:http)',
  'Accept-Encoding': 'gzip, deflate',
  'Accept': '*/*',
  'Connection': 'keep-alive',
  'Content-Type': 'application/x-amz-json-1.1',
};
