import 'package:aws_request/testing.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

void main() {
  group('constructors', () {
    test('minimum constructor', () {
      final MockAwsRequest awsRequest = MockAwsRequest(
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
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
        awsAccessKey: 'awsAccessKey',
        awsSecretKey: 'awsSecretKey',
        region: 'region',
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
      test('minimum', () async {
        await MockAwsRequest.staticSend(
          awsAccessKey: 'awsAccessKey',
          awsSecretKey: 'awsSecretKey',
          region: 'region',
          service: 'service',
          type: AwsRequestType.get,
          mockFunction: (Request request) async {
            return Response('', 200);
          },
        );
      });
      test('maximum', () async {
        await MockAwsRequest.staticSend(
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
      });
    });
    group('send', () {
      test('fail validation', () async {
        try {
          final MockAwsRequest awsRequest = MockAwsRequest(
            awsAccessKey: 'awsAccessKey',
            awsSecretKey: 'awsSecretKey',
            region: 'region',
            mockFunction: (Request request) async {
              return Response('', 200);
            },
          );
          await awsRequest.send(type: AwsRequestType.get);
        } catch (e) {
          expect(e, isA<AwsRequestException>());
          return;
        }
        fail('Validation not correct');
      });
      test('pass validation - values in constructor', () async {
        await MockAwsRequest(
          awsAccessKey: 'awsAccessKey',
          awsSecretKey: 'awsSecretKey',
          region: 'region',
          service: 'service',
          mockFunction: (Request request) async {
            return Response('', 200);
          },
        ).send(type: AwsRequestType.get);
      });
      test('pass validation - values in function', () async {
        await MockAwsRequest(
          awsAccessKey: 'awsAccessKey',
          awsSecretKey: 'awsSecretKey',
          region: 'region',
          mockFunction: (Request request) async {
            return Response('', 200);
          },
        ).send(
          type: AwsRequestType.get,
          service: 'service',
        );
      });
      test('pass validation - values in both', () async {
        await MockAwsRequest(
          awsAccessKey: 'awsAccessKey',
          awsSecretKey: 'awsSecretKey',
          region: 'region',
          service: 'service_1',
          mockFunction: (Request request) async {
            return Response('', 200);
          },
        ).send(
          type: AwsRequestType.get,
          service: 'service',
        );
      });
      test('pass validation - values set later', () async {
        try {
          final MockAwsRequest awsRequest = MockAwsRequest(
            awsAccessKey: 'awsAccessKey',
            awsSecretKey: 'awsSecretKey',
            region: 'region',
            mockFunction: (Request request) async {
              return Response('', 200);
            },
          )..service = 'service';
          await awsRequest.send(type: AwsRequestType.get);
        } catch (e) {
          print(e);
          fail('Validation not correct');
        }
      });
      test('maximum', () async {
        await MockAwsRequest(
          awsAccessKey: 'awsAccessKey',
          awsSecretKey: 'awsSecretKey',
          region: 'region',
          mockFunction: (Request request) async {
            return Response('', 200);
          },
        ).send(
          type: AwsRequestType.get,
          service: 'service',
          signedHeaders: ['a'],
          headers: {'a': 'a'},
          jsonBody: '{"test":"true"}',
          queryPath: '/',
          queryString: {'test': 'true'},
          timeout: const Duration(seconds: 5),
        );
      });
    });
  });
}
