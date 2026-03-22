import 'dart:async';
import 'dart:convert';

import 'package:aws_request/src/request.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

void main() {
  group('sortedQueryParameters', () {
    test('null returns null', () {
      expect(AwsHttpRequest.sortedQueryParameters(null), isNull);
    });

    test('sorts by key then value', () {
      final Map<String, String>? sorted = AwsHttpRequest.sortedQueryParameters(
        <String, String>{'b': '2', 'a': '1'},
      );
      expect(sorted!.keys.toList(), <String>['a', 'b']);
      expect(sorted['a'], '1');
      expect(sorted['b'], '2');
    });
  });

  group('getSignedHeaders', () {
    test('getSignedHeaders', () {
      const Map<String, String> correctSignedHeaders = {
        'host': 'host',
        'x-amz-date': 'amzDate',
        'signed_header': 'signed_header',
      };
      final Map<String, String> generatedSignedHeaders =
          AwsHttpRequest.getSignedHeaders(
        headers: {
          'signed_header': 'signed_header',
          'unsigned_header': 'unsigned_header',
        },
        signedHeaderNames: ['signed_header'],
        host: 'host',
        amzDate: 'amzDate',
      );
      expect(generatedSignedHeaders, correctSignedHeaders);
    });

    test('getSignedHeaders failure', () {
      try {
        AwsHttpRequest.getSignedHeaders(
          headers: {
            'signed_header': 'signed_header',
            'unsigned_header': 'unsigned_header',
          },
          signedHeaderNames: ['signed_header', 'missing_header'],
          host: 'host',
          amzDate: 'amzDate',
        );
      } catch (e) {
        expect(e, isA<AwsRequestException>());
        return;
      }
      fail("Something went wrong. The last line didn't cause an error");
    });

    test('getSignedHeaders content-type', () {
      const Map<String, String> correctSignedHeaders = {
        'host': 'host',
        'x-amz-date': 'amzDate',
        'signed_header': 'signed_header',
        'content-type': 'content-type'
      };
      final Map<String, String> generatedSignedHeaders =
          AwsHttpRequest.getSignedHeaders(
        headers: {
          'signed_header': 'signed_header',
          'unsigned_header': 'unsigned_header',
          'content-type': 'content-type'
        },
        signedHeaderNames: ['signed_header'],
        host: 'host',
        amzDate: 'amzDate',
      );
      expect(generatedSignedHeaders, correctSignedHeaders);
    });

    test('getSignedHeaders skips already-included keys', () {
      const Map<String, String> correctSignedHeaders = {
        'host': 'host',
        'x-amz-date': 'amzDate',
      };
      final Map<String, String> generatedSignedHeaders =
          AwsHttpRequest.getSignedHeaders(
        headers: {},
        signedHeaderNames: ['host'],
        host: 'host',
        amzDate: 'amzDate',
      );
      expect(generatedSignedHeaders, correctSignedHeaders);
    });

    test('getSignedHeaders resolves signedHeaderNames case-insensitively', () {
      const Map<String, String> correctSignedHeaders = {
        'host': 'host',
        'x-amz-date': 'amzDate',
        'x-amz-security-token': 'token',
      };
      final Map<String, String> generatedSignedHeaders =
          AwsHttpRequest.getSignedHeaders(
        headers: {'X-Amz-Security-Token': 'token'},
        signedHeaderNames: ['x-amz-security-token'],
        host: 'host',
        amzDate: 'amzDate',
      );
      expect(generatedSignedHeaders, correctSignedHeaders);
    });
  });

  group('sign', () {
    test('bytes', () {
      final List<int> result =
          AwsHttpRequest.sign(key: utf8.encode('AWS4KEY'), msg: 'stringMessage')
              .bytes;
      expect([
        106,
        73,
        3,
        202,
        103,
        45,
        38,
        137,
        136,
        2,
        133,
        175,
        91,
        138,
        142,
        8,
        39,
        50,
        141,
        255,
        56,
        242,
        179,
        229,
        170,
        75,
        186,
        230,
        36,
        127,
        215,
        155
      ], result);
    });
  });

  test('getSignature', () {
    final String signature = AwsHttpRequest.getSignature(
      key: 'key',
      dateStamp: 'dateStamp',
      regionName: 'regionName',
      serviceName: 'serviceName',
      stringToSign: 'stringToSign',
    );
    expect(
      'ba57e18ee959b8eb152d5ba3349eee5afd95812e0f2ff44b41dee9f8686c824d',
      signature,
    );
  });

  group('getCanonicalRequest', () {
    test('getCanonicalRequest - 1', () {
      final String requestString = AwsHttpRequest.getCanonicalRequest(
        type: AwsRequestType.post.name.toUpperCase(),
        requestBody: 'requestBody',
        signedHeaders: {'signedHeaderKey': 'signedHeaderValue'},
        canonicalUri: 'canonical/Uri',
        canonicalQuerystring: 'canonicalQuerystring=canonicalQuerystring',
      );
      expect(
        '''
POST
canonical/Uri
canonicalQuerystring=canonicalQuerystring
signedHeaderKey:signedHeaderValue

signedHeaderKey
fcf523fac03a2e3a814b7f97bf8c9533d657677c72ff3870afd69cef3b559c60''',
        requestString,
      );
    });
    test('getCanonicalRequest - 2', () {
      final String requestString = AwsHttpRequest.getCanonicalRequest(
        type: AwsRequestType.delete.name.toUpperCase(),
        requestBody: '',
        signedHeaders: {
          'signedHeaderKey': 'signedHeaderValue',
          'signedHeaderKey1': 'signedHeaderValue1',
          'signedHeaderKey2': 'signedHeaderValue2',
        },
        canonicalUri: 'canonical/Uri',
        canonicalQuerystring: '/',
      );
      expect(
        '''
DELETE
canonical/Uri
/
signedHeaderKey1:signedHeaderValue1
signedHeaderKey2:signedHeaderValue2
signedHeaderKey:signedHeaderValue

signedHeaderKey;signedHeaderKey1;signedHeaderKey2
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855''',
        requestString,
      );
    });
  });

  group('getAuth', () {
    test('empty credentials', () {
      const String amzDate = '20260101T000000Z';
      const String dateStamp = '20260101';
      final String auth = AwsHttpRequest.getAuth(
        awsSecretKey: '',
        awsAccessKey: '',
        amzDate: amzDate,
        canonicalRequest: '',
        region: '',
        service: '',
        signedHeaders: {},
      );
      final String stringToSign =
          'AWS4-HMAC-SHA256\n$amzDate\n$dateStamp///aws4_request\n'
          '${sha256.convert(utf8.encode('')).toString()}';
      final String signature = AwsHttpRequest.getSignature(
        key: '',
        dateStamp: dateStamp,
        regionName: '',
        serviceName: '',
        stringToSign: stringToSign,
      );
      expect(
        'AWS4-HMAC-SHA256 Credential=/$dateStamp///aws4_request, SignedHeaders=, Signature=$signature',
        auth,
      );
    });
    test('strings', () {
      const String amzDate = '20260315T120000Z';
      const String dateStamp = '20260315';
      final String auth = AwsHttpRequest.getAuth(
        awsSecretKey: 'awsSecretKey',
        awsAccessKey: 'awsAccessKey',
        amzDate: amzDate,
        canonicalRequest: 'canonicalRequest',
        region: 'region',
        service: 'service',
        signedHeaders: {'signedHeaders': 'signedHeaders'},
      );
      final String stringToSign =
          'AWS4-HMAC-SHA256\n$amzDate\n$dateStamp/region/service/aws4_request\n'
          '${sha256.convert(utf8.encode('canonicalRequest')).toString()}';
      final String signature = AwsHttpRequest.getSignature(
        key: 'awsSecretKey',
        dateStamp: dateStamp,
        regionName: 'region',
        serviceName: 'service',
        stringToSign: stringToSign,
      );
      expect(
        'AWS4-HMAC-SHA256 Credential=awsAccessKey/$dateStamp/region/service/aws4_request, SignedHeaders=signedHeaders, Signature=$signature',
        auth,
      );
    });
    test('headers unsorted', () {
      const String amzDate = '20260315T120000Z';
      const String dateStamp = '20260315';
      final String auth = AwsHttpRequest.getAuth(
        awsSecretKey: 'awsSecretKey',
        awsAccessKey: 'awsAccessKey',
        amzDate: amzDate,
        canonicalRequest: 'canonicalRequest',
        region: 'region',
        service: 'service',
        signedHeaders: {
          'c': 'c',
          'b': 'b',
          'a': 'a',
        },
      );
      final String stringToSign =
          'AWS4-HMAC-SHA256\n$amzDate\n$dateStamp/region/service/aws4_request\n'
          '${sha256.convert(utf8.encode('canonicalRequest')).toString()}';
      final String signature = AwsHttpRequest.getSignature(
        key: 'awsSecretKey',
        dateStamp: dateStamp,
        regionName: 'region',
        serviceName: 'service',
        stringToSign: stringToSign,
      );
      expect(
        'AWS4-HMAC-SHA256 Credential=awsAccessKey/$dateStamp/region/service/aws4_request, SignedHeaders=a;b;c, Signature=$signature',
        auth,
      );
    });
  });

  group('getHeaders', () {
    test('strings', () {
      final Map<String, String> res = AwsHttpRequest.getHeaders(
        headers: {'c': 'c'},
        amzDate: 'amzDate',
        auth: 'auth',
      );
      expect(
        {
          'Accept': '*/*',
          'Content-Type': 'application/x-amz-json-1.1',
          'Authorization': 'auth',
          'x-amz-date': 'amzDate',
          'c': 'c',
        },
        res,
      );
    });
    test('overwrite string', () {
      final Map<String, String> res = AwsHttpRequest.getHeaders(
        headers: {
          'Accept': '',
          'Content-Type': '',
          'Authorization': '',
          'x-amz-date': '',
        },
        amzDate: 'amzDate',
        auth: 'auth',
      );
      expect(
        {
          'Accept': '',
          'Content-Type': '',
          'Authorization': 'auth',
          'x-amz-date': 'amzDate',
        },
        res,
      );
    });
  });

  group('getRequest', () {
    Future<Response> mockFunction(Request request) async {
      return Response(request.method, 200);
    }

    test('AwsRequestType.DELETE', () {
      return AwsHttpRequest.getRequest(
        type: AwsRequestType.delete,
        url: Uri.parse('https://www.example.com'),
        headers: {},
        body: '',
        timeout: const Duration(seconds: 10),
        mockRequest: true,
        mockFunction: mockFunction,
      ).then((value) {
        expect(value.body, 'DELETE');
      });
    });
    test('AwsRequestType.GET', () {
      return AwsHttpRequest.getRequest(
        type: AwsRequestType.get,
        url: Uri.parse('https://www.example.com'),
        headers: {},
        body: '',
        timeout: const Duration(seconds: 10),
        mockRequest: true,
        mockFunction: mockFunction,
      ).then((value) {
        expect(value.body, 'GET');
      });
    });
    test('AwsRequestType.HEAD', () {
      return AwsHttpRequest.getRequest(
        type: AwsRequestType.head,
        url: Uri.parse('https://www.example.com'),
        headers: {},
        body: '',
        timeout: const Duration(seconds: 10),
        mockRequest: true,
        mockFunction: mockFunction,
      ).then((value) {
        expect(value.body, 'HEAD');
      });
    });
    test('AwsRequestType.PATCH', () {
      return AwsHttpRequest.getRequest(
        type: AwsRequestType.patch,
        url: Uri.parse('https://www.example.com'),
        headers: {},
        body: '',
        timeout: const Duration(seconds: 10),
        mockRequest: true,
        mockFunction: mockFunction,
      ).then((value) {
        expect(value.body, 'PATCH');
      });
    });
    test('AwsRequestType.POST', () {
      return AwsHttpRequest.getRequest(
        type: AwsRequestType.post,
        url: Uri.parse('https://www.example.com'),
        headers: {},
        body: '',
        timeout: const Duration(seconds: 10),
        mockRequest: true,
        mockFunction: mockFunction,
      ).then((value) {
        expect(value.body, 'POST');
      });
    });
    test('AwsRequestType.PUT', () {
      return AwsHttpRequest.getRequest(
        type: AwsRequestType.put,
        url: Uri.parse('https://www.example.com'),
        headers: {},
        body: '',
        timeout: const Duration(seconds: 10),
        mockRequest: true,
        mockFunction: mockFunction,
      ).then((value) {
        expect(value.body, 'PUT');
      });
    });

    test('failure', () {
      return AwsHttpRequest.getRequest(
        type: AwsRequestType.get,
        url: Uri.parse('https://www.example.com'),
        headers: {},
        body: '',
        timeout: const Duration(seconds: 10),
        mockRequest: true,
      ).then<Future<Response>>((val) {
        fail('Mock client not detected!');
      }, onError: (e) {
        expect(e, isA<AwsRequestException>());
        return Future(() => Response('body', 400));
      });
    });

    test('check MockClient', () {
      final Request request = Request(
        'GET',
        Uri.parse('https://www.example.com'),
      );

      Future<Response> innerMockFunction(Request request) async {
        return Response(
          '',
          500,
          request: request,
        );
      }

      return AwsHttpRequest.getRequest(
        type: AwsRequestType.get,
        url: Uri.parse('https://www.example.com'),
        headers: {},
        body: '',
        timeout: const Duration(seconds: 10),
        mockFunction: innerMockFunction,
        mockRequest: true,
      ).then((val) {
        expect(
          val.request!.url,
          request.url,
        );
        expect(
          val.request!.method,
          request.method,
        );
        expect(
          val.statusCode,
          500,
        );
      });
    });
  });

  group('send', () {
    Future<Response> mockFunction(Request request) async {
      await Future.delayed(const Duration(milliseconds: 1));
      return Response(request.method, 500);
    }

    group('HTTP Methods', () {
      test('GET', () {
        return AwsHttpRequest.send(
          awsSecretKey: 'awsSecretKey',
          awsAccessKey: 'awsAccessKey',
          type: AwsRequestType.get,
          service: 'service',
          region: 'region',
          timeout: const Duration(seconds: 10),
          headers: {},
          jsonBody: 'jsonBody',
          canonicalUri: 'canonicalUri',
          mockRequest: true,
          mockFunction: mockFunction,
        ).then((val) {
          expect(val.body, 'GET');
        });
      });
      test('POST', () {
        return AwsHttpRequest.send(
          awsSecretKey: 'awsSecretKey',
          awsAccessKey: 'awsAccessKey',
          type: AwsRequestType.post,
          service: 'service',
          region: 'region',
          timeout: const Duration(seconds: 10),
          headers: {},
          jsonBody: 'jsonBody',
          canonicalUri: 'canonicalUri',
          mockRequest: true,
          mockFunction: mockFunction,
        ).then((val) {
          expect(val.body, 'POST');
        });
      });
      test('DELETE', () {
        return AwsHttpRequest.send(
          awsSecretKey: 'awsSecretKey',
          awsAccessKey: 'awsAccessKey',
          type: AwsRequestType.delete,
          service: 'service',
          region: 'region',
          timeout: const Duration(seconds: 10),
          headers: {},
          jsonBody: 'jsonBody',
          canonicalUri: 'canonicalUri',
          mockRequest: true,
          mockFunction: mockFunction,
        ).then((val) {
          expect(val.body, 'DELETE');
        });
      });
      test('PUT', () {
        return AwsHttpRequest.send(
          awsSecretKey: 'awsSecretKey',
          awsAccessKey: 'awsAccessKey',
          type: AwsRequestType.put,
          service: 'service',
          region: 'region',
          timeout: const Duration(seconds: 10),
          headers: {},
          jsonBody: 'jsonBody',
          canonicalUri: 'canonicalUri',
          mockRequest: true,
          mockFunction: mockFunction,
        ).then((val) {
          expect(val.body, 'PUT');
        });
      });
      test('PATCH', () {
        return AwsHttpRequest.send(
          awsSecretKey: 'awsSecretKey',
          awsAccessKey: 'awsAccessKey',
          type: AwsRequestType.patch,
          service: 'service',
          region: 'region',
          timeout: const Duration(seconds: 10),
          headers: {},
          jsonBody: 'jsonBody',
          canonicalUri: 'canonicalUri',
          mockRequest: true,
          mockFunction: mockFunction,
        ).then((val) {
          expect(val.body, 'PATCH');
        });
      });
      test('HEAD', () {
        return AwsHttpRequest.send(
          awsSecretKey: 'awsSecretKey',
          awsAccessKey: 'awsAccessKey',
          type: AwsRequestType.head,
          service: 'service',
          region: 'region',
          timeout: const Duration(seconds: 10),
          headers: {},
          jsonBody: 'jsonBody',
          canonicalUri: 'canonicalUri',
          mockRequest: true,
          mockFunction: mockFunction,
        ).then((val) {
          expect(val.body, 'HEAD');
        });
      });
    });
    test('custom endpoint', () {
      Future<Response> endpointMock(Request request) async {
        return Response(request.url.host, 200);
      }

      return AwsHttpRequest.send(
        awsSecretKey: 'awsSecretKey',
        awsAccessKey: 'awsAccessKey',
        type: AwsRequestType.get,
        service: 'service',
        region: 'region',
        timeout: const Duration(seconds: 10),
        headers: {},
        jsonBody: '',
        canonicalUri: '/',
        endpoint: 'mybucket.s3.us-east-1.amazonaws.com',
        mockRequest: true,
        mockFunction: endpointMock,
      ).then((val) {
        expect(val.body, 'mybucket.s3.us-east-1.amazonaws.com');
      });
    });
    test('default endpoint', () {
      Future<Response> endpointMock(Request request) async {
        return Response(request.url.host, 200);
      }

      return AwsHttpRequest.send(
        awsSecretKey: 'awsSecretKey',
        awsAccessKey: 'awsAccessKey',
        type: AwsRequestType.get,
        service: 'logs',
        region: 'us-east-1',
        timeout: const Duration(seconds: 10),
        headers: {},
        jsonBody: '',
        canonicalUri: '/',
        mockRequest: true,
        mockFunction: endpointMock,
      ).then((val) {
        expect(val.body, 'logs.us-east-1.amazonaws.com');
      });
    });
    test('Timeout', () async {
      try {
        await AwsHttpRequest.send(
          awsSecretKey: 'awsSecretKey',
          awsAccessKey: 'awsAccessKey',
          type: AwsRequestType.head,
          service: 'service',
          region: 'region',
          timeout: const Duration(microseconds: 0),
          headers: {},
          jsonBody: 'jsonBody',
          canonicalUri: 'canonicalUri',
          mockRequest: true,
          mockFunction: mockFunction,
        );
      } catch (e) {
        expect(e, isA<TimeoutException>());
        return;
      }
      fail('Timeout did not occur!');
    });

    test('rejects empty awsAccessKey', () async {
      try {
        await AwsHttpRequest.send(
          awsSecretKey: 'awsSecretKey',
          awsAccessKey: '',
          type: AwsRequestType.get,
          service: 'service',
          region: 'region',
          timeout: const Duration(seconds: 10),
          headers: {},
          jsonBody: '',
          canonicalUri: '/',
          mockRequest: true,
          mockFunction: mockFunction,
        );
      } catch (e) {
        expect(e, isA<AwsRequestException>());
        return;
      }
      fail('expected AwsRequestException');
    });

    test('canonical query string matches Uri.query encoding', () {
      final Map<String, String> sorted = Map<String, String>.fromEntries(
        <MapEntry<String, String>>[
          const MapEntry('b', '2'),
          const MapEntry('a', '1'),
        ]..sort((MapEntry<String, String> a, MapEntry<String, String> b) =>
            a.key.compareTo(b.key)),
      );
      final Uri url = Uri(
        scheme: 'https',
        host: 'host',
        path: '/',
        queryParameters: sorted,
      );
      expect(url.query, 'a=1&b=2');
    });
  });
}
