import 'package:aws_request/aws_request.dart';
import 'package:aws_request/testing.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

void main() {
  group('constructors', () {
    test('minimum constructor', () {
      MockAwsRequest awsRequest = new MockAwsRequest(
        'awsAccessKey',
        'awsSecretKey',
        'region',
        mockFunction: (Request) async {
          return Response('', 200);
        },
      );
      expect(awsRequest.awsAccessKey, 'awsAccessKey');
      expect(awsRequest.awsSecretKey, 'awsSecretKey');
      expect(awsRequest.region, 'region');
      expect(awsRequest.service == null, true);
      expect(awsRequest.target == null, true);
      expect(awsRequest.timeout.inSeconds, 10);
    });
    test('maximum constructor', () {
      MockAwsRequest awsRequest = new MockAwsRequest(
        'awsAccessKey',
        'awsSecretKey',
        'region',
        service: 'service',
        target: 'target',
        timeout: Duration(seconds: 100),
        mockFunction: (Request) async {
          return Response('', 200);
        },
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
      test('minimum', () {
        try {
          MockAwsRequest.staticSend(
            awsAccessKey: 'awsAccessKey',
            awsSecretKey: 'awsSecretKey',
            region: 'region',
            service: 'service',
            target: 'target',
            type: AwsRequestType.GET,
            mockFunction: (Request) async {
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
            target: 'target',
            type: AwsRequestType.GET,
            signedHeaders: ['a'],
            headers: {'a': 'a'},
            jsonBody: '{"test":"true"}',
            queryPath: '/',
            queryString: {"test": "true"},
            timeout: Duration(seconds: 5),
            mockFunction: (Request) async {
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
          MockAwsRequest awsRequest = new MockAwsRequest(
            'awsAccessKey',
            'awsSecretKey',
            'region',
            mockFunction: (Request) async {
              return Response('', 200);
            },
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
      test('pass validation - values in constructor', () {
        try {
          MockAwsRequest awsRequest = new MockAwsRequest(
            'awsAccessKey',
            'awsSecretKey',
            'region',
            service: 'service',
            target: 'target',
            mockFunction: (Request) async {
              return Response('', 200);
            },
          );
          awsRequest.send(
            AwsRequestType.GET,
          );
        } catch (e) {
          print(e);
          fail('Validation not correct');
        }
      });
      test('pass validation - values in function', () {
        try {
          MockAwsRequest awsRequest = new MockAwsRequest(
            'awsAccessKey',
            'awsSecretKey',
            'region',
            mockFunction: (Request) async {
              return Response('', 200);
            },
          );
          awsRequest.send(
            AwsRequestType.GET,
            service: 'service',
            target: 'target',
          );
        } catch (e) {
          print(e);
          fail('Validation not correct');
        }
      });
      test('pass validation - values in both', () {
        try {
          MockAwsRequest awsRequest = new MockAwsRequest(
            'awsAccessKey',
            'awsSecretKey',
            'region',
            service: 'service_1',
            target: 'target_1',
            mockFunction: (Request) async {
              return Response('', 200);
            },
          );
          awsRequest.send(
            AwsRequestType.GET,
            service: 'service',
            target: 'target',
          );
        } catch (e) {
          print(e);
          fail('Validation not correct');
        }
      });
      test('pass validation - values set later', () {
        try {
          MockAwsRequest awsRequest = new MockAwsRequest(
            'awsAccessKey',
            'awsSecretKey',
            'region',
            mockFunction: (Request) async {
              return Response('', 200);
            },
          );
          awsRequest.service = 'service';
          awsRequest.target = 'target';
          awsRequest.send(
            AwsRequestType.GET,
          );
        } catch (e) {
          print(e);
          fail('Validation not correct');
        }
      });
      test('maximum', () {
        try {
          MockAwsRequest awsRequest = new MockAwsRequest(
            'awsAccessKey',
            'awsSecretKey',
            'region',
            mockFunction: (Request) async {
              return Response('', 200);
            },
          );
          awsRequest.send(
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
          fail('Could not send request');
        }
      });
    });
  });
}
