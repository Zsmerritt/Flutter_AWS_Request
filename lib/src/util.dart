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

String awsRequestType(AwsRequestType type) {
  switch (type) {
    case AwsRequestType.GET:
      return 'GET';
    case AwsRequestType.POST:
      return 'POST';
    case AwsRequestType.DELETE:
      return 'DELETE';
    case AwsRequestType.PATCH:
      return 'PATCH';
    case AwsRequestType.PUT:
      return 'PUT';
  }
}

enum AwsRequestType { GET, POST, DELETE, PATCH, PUT }

/// Default headers included automatically with every request.
/// These can be overridden by passing in a Map with the same keys
const Map<String, String> defaultHeaders = {
  'User-Agent': 'Dart (dart:universal_io)',
  'Accept-Encoding': 'gzip, deflate',
  'Accept': '*/*',
  'Connection': 'keep-alive',
  'Content-Type': 'application/x-amz-json-1.1',
};
