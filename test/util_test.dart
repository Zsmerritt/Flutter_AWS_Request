import 'package:aws_request/src/util.dart';
import 'package:test/test.dart';

void main() {
  group('AwsRequestException', () {
    test('constructor', () {
      AwsRequestException exception = AwsRequestException(
        message: '',
        stackTrace: StackTrace.empty,
      );
      expect(exception.message, '');
      expect(exception.stackTrace, StackTrace.empty);
    });
    test('toString - empty', () {
      AwsRequestException exception = AwsRequestException(
        message: '',
        stackTrace: StackTrace.empty,
      );
      expect(exception.toString(), 'AwsRequestException - message: ');
    });
    test('toString - filled', () {
      AwsRequestException exception = AwsRequestException(
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
        AwsRequestType.GET,
        AwsRequestType.POST,
        AwsRequestType.DELETE,
        AwsRequestType.PATCH,
        AwsRequestType.PUT,
        AwsRequestType.HEAD
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
    test('both null', () {
      Map<String, dynamic> validation = validateRequest(null, null);
      expect(validation, {
        'valid': false,
        'error':
            'No Service Provided. Please pass in a service or set it in the constructor.'
      });
    });
    test('null service', () {
      Map<String, dynamic> validation = validateRequest(null, 'null');
      expect(validation, {
        'valid': false,
        'error':
            'No Service Provided. Please pass in a service or set it in the constructor.'
      });
    });
    test('null target', () {
      Map<String, dynamic> validation = validateRequest('null', null);
      expect(validation, {
        'valid': false,
        'error':
            'No Target Provided. Please pass in a service or set it in the constructor.'
      });
    });
    test('null target', () {
      Map<String, dynamic> validation = validateRequest('null', 'null');
      expect(validation, {'valid': true, 'error': null});
    });
  });
}
