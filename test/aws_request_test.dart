import 'package:aws_request/aws_request.dart';
import 'package:test/test.dart';

void main() {
  group('constructors', () {
    test('minimum constructor', () {
      final AwsRequest awsRequest = AwsRequest(
        'awsAccessKey',
        'awsSecretKey',
        'region',
      );
      expect(awsRequest.awsAccessKey, 'awsAccessKey');
      expect(awsRequest.awsSecretKey, 'awsSecretKey');
      expect(awsRequest.region, 'region');
      expect(awsRequest.service == null, true);
      expect(awsRequest.timeout.inSeconds, 10);
    });
    test('maximum constructor', () {
      final AwsRequest awsRequest = AwsRequest(
        'awsAccessKey',
        'awsSecretKey',
        'region',
        service: 'service',
        timeout: const Duration(seconds: 100),
      );
      expect(awsRequest.awsAccessKey, 'awsAccessKey');
      expect(awsRequest.awsSecretKey, 'awsSecretKey');
      expect(awsRequest.region, 'region');
      expect(awsRequest.service, 'service');
      expect(awsRequest.timeout.inSeconds, 100);
    });
  });
  group('functions', () {
    group('staticSend', () {
      test('minimum', () async {
        try {
          await AwsRequest.staticSend(
            awsAccessKey: 'awsAccessKey',
            awsSecretKey: 'awsSecretKey',
            region: 'region',
            service: 'service',
            type: AwsRequestType.get,
          );
        } catch (e) {
          expect(e.toString().contains('Failed host lookup'), true);
          return;
        }
        fail('Could not send request');
      });
      test('maximum', () async {
        try {
          await AwsRequest.staticSend(
            awsAccessKey: 'awsAccessKey',
            awsSecretKey: 'awsSecretKey',
            region: 'region',
            service: 'service',
            type: AwsRequestType.get,
            signedHeaders: ['a'],
            headers: {'a': 'a'},
            jsonBody: '{"test":"true"}',
            queryPath: '/',
            queryString: {'test': 'true'},
            timeout: const Duration(seconds: 5),
          );
        } catch (e) {
          expect(e.toString().contains('Failed host lookup'), true);
          return;
        }
        fail('Could not send request');
      });
    });
    group('send', () {
      test('fail validation', () async {
        try {
          final AwsRequest awsRequest = AwsRequest(
            'awsAccessKey',
            'awsSecretKey',
            'region',
          );
          await awsRequest.send(
            AwsRequestType.get,
          );
        } catch (e) {
          expect(e, isA<AwsRequestException>());
          return;
        }
        fail('Validation not correct');
      });
      test('pass validation - values in constructor', () async {
        try {
          final AwsRequest awsRequest = AwsRequest(
            'awsAccessKey',
            'awsSecretKey',
            'region',
            service: 'service',
          );
          await awsRequest.send(
            AwsRequestType.get,
          );
        } catch (e) {
          expect(e.toString().contains('Failed host lookup'), true);
          return;
        }
        fail('Validation not correct');
      });
      test('pass validation - values in function', () async {
        try {
          final AwsRequest awsRequest = AwsRequest(
            'awsAccessKey',
            'awsSecretKey',
            'region',
          );
          await awsRequest.send(
            AwsRequestType.get,
            service: 'service',
          );
        } catch (e) {
          expect(e.toString().contains('Failed host lookup'), true);
          return;
        }
        fail('Validation not correct');
      });
      test('pass validation - values in both', () async {
        try {
          final AwsRequest awsRequest = AwsRequest(
            'awsAccessKey',
            'awsSecretKey',
            'region',
            service: 'service_1',
          );
          await awsRequest.send(
            AwsRequestType.get,
            service: 'service',
          );
        } catch (e) {
          expect(e.toString().contains('Failed host lookup'), true);
          return;
        }
        fail('Validation not correct');
      });
      test('pass validation - values set later', () async {
        try {
          final AwsRequest awsRequest = AwsRequest(
            'awsAccessKey',
            'awsSecretKey',
            'region',
          )..service = 'service';
          await awsRequest.send(
            AwsRequestType.get,
          );
        } catch (e) {
          expect(e.toString().contains('Failed host lookup'), true);
          return;
        }
        fail('Validation not correct');
      });
      test('maximum', () async {
        try {
          final AwsRequest awsRequest = AwsRequest(
            'awsAccessKey',
            'awsSecretKey',
            'region',
          );
          await awsRequest.send(
            AwsRequestType.get,
            service: 'service',
            signedHeaders: ['a'],
            headers: {'a': 'a'},
            jsonBody: '{"test":"true"}',
            queryPath: '/',
            queryString: {'test': 'true'},
            timeout: const Duration(seconds: 5),
          );
        } catch (e) {
          expect(e.toString().contains('Failed host lookup'), true);
          return;
        }
        fail('Could not send request');
      });
    });
  });
}
