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
      expect(
        exception.toString(),
        'AwsRequestException - message: \n${StackTrace.empty}',
      );
    });
    test('toString - filled', () {
      final StackTrace trace = StackTrace.current;
      final AwsRequestException exception = AwsRequestException(
        message: 'test message',
        stackTrace: trace,
      );
      expect(
        exception.toString(),
        'AwsRequestException - message: test message\n$trace',
      );
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
      expect(
        () => validateRequest(null),
        throwsA(isA<AwsRequestException>()),
      );
    });
    test('Not null', () {
      expect(() => validateRequest('service'), returnsNormally);
    });
  });
}
