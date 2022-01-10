import 'package:aws_request/aws_request.dart';
import 'package:test/test.dart';

void main() {
  group('constructors', () {
    test('minimum constructor', () {
      AwsRequest awsRequest = new AwsRequest(
        'awsAccessKey',
        'awsSecretKey',
        'region',
      );
      expect(awsRequest.awsAccessKey, 'awsAccessKey');
      expect(awsRequest.awsSecretKey, 'awsSecretKey');
      expect(awsRequest.region, 'region');
      expect(awsRequest.service == null, true);
      expect(awsRequest.target == null, true);
      expect(awsRequest.timeout.inSeconds, 10);
    });
    test('maximum constructor', () {
      AwsRequest awsRequest = new AwsRequest(
        'awsAccessKey',
        'awsSecretKey',
        'region',
        service: 'service',
        target: 'target',
        timeout: Duration(seconds: 100),
      );
      expect(awsRequest.awsAccessKey, 'awsAccessKey');
      expect(awsRequest.awsSecretKey, 'awsSecretKey');
      expect(awsRequest.region, 'region');
      expect(awsRequest.service, 'service');
      expect(awsRequest.target, 'target');
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
            target: 'target',
            type: AwsRequestType.GET,
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
            target: 'target',
            type: AwsRequestType.GET,
            signedHeaders: ['a'],
            headers: {'a': 'a'},
            jsonBody: '{"test":"true"}',
            queryPath: '/',
            queryString: {"test": "true"},
            timeout: Duration(seconds: 5),
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
          AwsRequest awsRequest = new AwsRequest(
            'awsAccessKey',
            'awsSecretKey',
            'region',
          );
          await awsRequest.send(
            AwsRequestType.GET,
          );
        } catch (e) {
          expect(e, isA<AwsRequestException>());
          return;
        }
        fail('Validation not correct');
      });
      test('pass validation - values in constructor', () async {
        try {
          AwsRequest awsRequest = new AwsRequest(
            'awsAccessKey',
            'awsSecretKey',
            'region',
            service: 'service',
            target: 'target',
          );
          await awsRequest.send(
            AwsRequestType.GET,
          );
        } catch (e) {
          expect(e.toString().contains('Failed host lookup'), true);
          return;
        }
        fail('Validation not correct');
      });
      test('pass validation - values in function', () async {
        try {
          AwsRequest awsRequest = new AwsRequest(
            'awsAccessKey',
            'awsSecretKey',
            'region',
          );
          await awsRequest.send(
            AwsRequestType.GET,
            service: 'service',
            target: 'target',
          );
        } catch (e) {
          expect(e.toString().contains('Failed host lookup'), true);
          return;
        }
        fail('Validation not correct');
      });
      test('pass validation - values in both', () async {
        try {
          AwsRequest awsRequest = new AwsRequest(
            'awsAccessKey',
            'awsSecretKey',
            'region',
            service: 'service_1',
            target: 'target_1',
          );
          await awsRequest.send(
            AwsRequestType.GET,
            service: 'service',
            target: 'target',
          );
        } catch (e) {
          expect(e.toString().contains('Failed host lookup'), true);
          return;
        }
        fail('Validation not correct');
      });
      test('pass validation - values set later', () async {
        try {
          AwsRequest awsRequest = new AwsRequest(
            'awsAccessKey',
            'awsSecretKey',
            'region',
          );
          awsRequest.service = 'service';
          awsRequest.target = 'target';
          await awsRequest.send(
            AwsRequestType.GET,
          );
        } catch (e) {
          expect(e.toString().contains('Failed host lookup'), true);
          return;
        }
        fail('Validation not correct');
      });
      test('maximum', () async {
        try {
          AwsRequest awsRequest = new AwsRequest(
            'awsAccessKey',
            'awsSecretKey',
            'region',
          );
          await awsRequest.send(
            AwsRequestType.GET,
            service: 'service',
            target: 'target',
            signedHeaders: ['a'],
            headers: {'a': 'a'},
            jsonBody: '{"test":"true"}',
            queryPath: '/',
            queryString: {"test": "true"},
            timeout: Duration(seconds: 5),
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
