import 'package:aws_request/testing.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

void main() {
  group('constructors', () {
    test('minimum constructor', () {
      final MockAwsRequest awsRequest = MockAwsRequest(
        'awsAccessKey',
        'awsSecretKey',
        'region',
        mockFunction: (Request request) async {
          return Response('', 200);
        },
      );
      expect(awsRequest.awsAccessKey, 'awsAccessKey');
      expect(awsRequest.awsSecretKey, 'awsSecretKey');
      expect(awsRequest.region, 'region');
      expect(awsRequest.service == null, true);
      expect(awsRequest.timeout.inSeconds, 10);
    });
    test('maximum constructor', () {
      final MockAwsRequest awsRequest = MockAwsRequest(
        'awsAccessKey',
        'awsSecretKey',
        'region',
        service: 'service',
        timeout: const Duration(seconds: 100),
        mockFunction: (Request request) async {
          return Response('', 200);
        },
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
      test('minimum', () {
        try {
          MockAwsRequest.staticSend(
            awsAccessKey: 'awsAccessKey',
            awsSecretKey: 'awsSecretKey',
            region: 'region',
            service: 'service',
            type: AwsRequestType.get,
            mockFunction: (Request request) async {
              return Response('', 200);
            },
          );
        } catch (e) {
          fail('Could not send request');
        }
      });
      test('maximum', () {
        try {
          MockAwsRequest.staticSend(
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
            mockFunction: (Request request) async {
              return Response('', 200);
            },
          );
        } catch (e) {
          fail('Could not send request');
        }
      });
    });
    group('send', () {
      test('fail validation', () async {
        try {
          final MockAwsRequest awsRequest = MockAwsRequest(
            'awsAccessKey',
            'awsSecretKey',
            'region',
            mockFunction: (Request request) async {
              return Response('', 200);
            },
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
      test('pass validation - values in constructor', () {
        try {
          MockAwsRequest(
            'awsAccessKey',
            'awsSecretKey',
            'region',
            service: 'service',
            mockFunction: (Request request) async {
              return Response('', 200);
            },
          ).send(AwsRequestType.get);
        } catch (e) {
          print(e);
          fail('Validation not correct');
        }
      });
      test('pass validation - values in functi`on', () {
        try {
          MockAwsRequest(
            'awsAccessKey',
            'awsSecretKey',
            'region',
            mockFunction: (Request request) async {
              return Response('', 200);
            },
          ).send(
            AwsRequestType.get,
            service: 'service',
          );
        } catch (e) {
          print(e);
          fail('Validation not correct');
        }
      });
      test('pass validation - values in both', () {
        try {
          MockAwsRequest(
            'awsAccessKey',
            'awsSecretKey',
            'region',
            service: 'service_1',
            mockFunction: (Request request) async {
              return Response('', 200);
            },
          ).send(
            AwsRequestType.get,
            service: 'service',
          );
        } catch (e) {
          print(e);
          fail('Validation not correct');
        }
      });
      test('pass validation - values set later', () {
        try {
          MockAwsRequest(
            'awsAccessKey',
            'awsSecretKey',
            'region',
            mockFunction: (Request request) async {
              return Response('', 200);
            },
          )
            ..service = 'service'
            ..send(AwsRequestType.get);
        } catch (e) {
          print(e);
          fail('Validation not correct');
        }
      });
      test('maximum', () {
        try {
          MockAwsRequest(
            'awsAccessKey',
            'awsSecretKey',
            'region',
            mockFunction: (Request request) async {
              return Response('', 200);
            },
          ).send(
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
          fail('Could not send request');
        }
      });
    });
  });
}
