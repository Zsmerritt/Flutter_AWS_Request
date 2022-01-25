import 'package:aws_request/src/request.dart';
import 'package:test/test.dart';

void main() {
  group('AwsRequestException', () {
    test('constructor', () {
      final AwsRequestException exception = AwsRequestException(
        message: '',
        stackTrace: StackTrace.empty,
      );
      expect(exception.message, '');
      expect(exception.stackTrace, StackTrace.empty);
    });
    test('toString - empty', () {
      final AwsRequestException exception = AwsRequestException(
        message: '',
        stackTrace: StackTrace.empty,
      );
      expect(exception.toString(), 'AwsRequestException - message: ');
    });
    test('toString - filled', () {
      final AwsRequestException exception = AwsRequestException(
        message: 'test message',
        stackTrace: StackTrace.current,
      );
      expect(
          exception.toString(), 'AwsRequestException - message: test message');
    });
  });
  group('AwsRequestType', () {
    test('values', () {
      expect(AwsRequestType.values, [
        AwsRequestType.get,
        AwsRequestType.post,
        AwsRequestType.delete,
        AwsRequestType.patch,
        AwsRequestType.put,
        AwsRequestType.head
      ]);
    });
  });
  group('defaultHeaders', () {
    test('values', () {
      expect(defaultHeaders, {
        'Accept': '*/*',
        'Content-Type': 'application/x-amz-json-1.1',
      });
    });
  });
  group('validateRequest', () {
    test('null', () {
      final Map<String, dynamic> validation = validateRequest(null);
      expect(validation, {
        'valid': false,
        'error':
            'No Service Provided. Please pass in a service or set it in the constructor.'
      });
    });
    test('Not null', () {
      final Map<String, dynamic> validation = validateRequest('null');
      expect(validation, {'valid': true, 'error': null});
    });
  });
}
