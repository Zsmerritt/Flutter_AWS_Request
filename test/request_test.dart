import 'dart:convert';

import 'package:aws_request/aws_request.dart';
import 'package:aws_request/src/request.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:test/test.dart';

void main() {
  group('getSignedHeaders', () {
    test('getSignedHeaders', () {
      const Map<String, String> correctSignedHeaders = {
        'host': 'host',
        'x-amz-date': 'amzDate',
        'x-amz-target': 'target',
        'signed_header': 'signed_header',
        'content-type': 'application/x-amz-json-1.1'
      };
      Map<String, String> generatedSignedHeaders =
          AwsHttpRequest.getSignedHeaders(
        {
          'signed_header': 'signed_header',
          'unsigned_header': 'unsigned_header',
        },
        ['signed_header'],
        'target',
        'host',
        'amzDate',
      );
      expect(generatedSignedHeaders, correctSignedHeaders);
    });

    test('getSignedHeaders failure', () {
      try {
        AwsHttpRequest.getSignedHeaders(
          {
            'signed_header': 'signed_header',
            'unsigned_header': 'unsigned_header',
          },
          ['signed_header', 'missing_header'],
          'target',
          'host',
          'amzDate',
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
        'x-amz-target': 'target',
        'signed_header': 'signed_header',
        'content-type': 'content-type'
      };
      Map<String, String> generatedSignedHeaders =
          AwsHttpRequest.getSignedHeaders(
        {
          'signed_header': 'signed_header',
          'unsigned_header': 'unsigned_header',
          'content-type': 'content-type'
        },
        ['signed_header'],
        'target',
        'host',
        'amzDate',
      );
      expect(generatedSignedHeaders, correctSignedHeaders);
    });
  });

  group('sign', () {
    test('bytes', () {
      List<int> result =
          AwsHttpRequest.sign(utf8.encode('AWS4KEY'), 'stringMessage');
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

    test('hex', () {
      String result2 = AwsHttpRequest.sign(
        utf8.encode('AWS4KEY'),
        'stringMessage',
        hex: true,
      );
      expect(
        '6a4903ca672d2689880285af5b8a8e0827328dff38f2b3e5aa4bbae6247fd79b',
        result2,
      );
    });
  });

  test('getSignature', () {
    String signature = AwsHttpRequest.getSignature(
      'key',
      'dateStamp',
      'regionName',
      'serviceName',
      'stringToSign',
    );
    expect(
      'ba57e18ee959b8eb152d5ba3349eee5afd95812e0f2ff44b41dee9f8686c824d',
      signature,
    );
  });

  group('getCanonicalRequest', () {
    test('getCanonicalRequest - 1', () {
      String requestString = AwsHttpRequest.getCanonicalRequest(
        'type',
        'requestBody',
        {'signedHeaderKey': 'signedHeaderValue'},
        'canonical/Uri',
        'canonicalQuerystring=canonicalQuerystring',
      );
      expect(
        """type
canonical/Uri
canonicalQuerystring=canonicalQuerystring
signedHeaderKey:signedHeaderValue

signedHeaderKey
fcf523fac03a2e3a814b7f97bf8c9533d657677c72ff3870afd69cef3b559c60""",
        requestString,
      );
    });
    test('getCanonicalRequest - 2', () {
      String requestString = AwsHttpRequest.getCanonicalRequest(
        'type',
        '',
        {
          'signedHeaderKey': 'signedHeaderValue',
          'signedHeaderKey1': 'signedHeaderValue1',
          'signedHeaderKey2': 'signedHeaderValue2',
        },
        'canonical/Uri',
        '/',
      );
      expect(
        """type
canonical/Uri
/
signedHeaderKey1:signedHeaderValue1
signedHeaderKey2:signedHeaderValue2
signedHeaderKey:signedHeaderValue

signedHeaderKey;signedHeaderKey1;signedHeaderKey2
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855""",
        requestString,
      );
    });
  });

  group('getAuth', () {
    String dateStamp = DateFormat('yyyyMMdd').format(DateTime.now().toUtc());

    test('empty', () {
      String auth = AwsHttpRequest.getAuth(
        '',
        '',
        '',
        '',
        '',
        '',
        {},
      );
      expect(
        'AWS4-HMAC-SHA256 Credential=/$dateStamp///aws4_request, SignedHeaders=, Signature=8d2cf0ee32715f0e09317b55d3d6961d4f47fb5fd7dedbbe9dc8db0a31c07dca',
        auth,
      );
    });
    test('strings', () {
      String auth = AwsHttpRequest.getAuth(
        'awsSecretKey',
        'awsAccessKey',
        'amzDate',
        'canonicalRequest',
        'region',
        'service',
        {'signedHeaders': 'signedHeaders'},
      );
      expect(
        'AWS4-HMAC-SHA256 Credential=awsAccessKey/$dateStamp/region/service/aws4_request, SignedHeaders=signedHeaders, Signature=ae34525315a3082d37b4a7e0c2de1d9b499b38a965d1a086b122174e5a249473',
        auth,
      );
    });
    test('headers unsorted', () {
      String auth = AwsHttpRequest.getAuth(
        'awsSecretKey',
        'awsAccessKey',
        'amzDate',
        'canonicalRequest',
        'region',
        'service',
        {
          'c': 'c',
          'b': 'b',
          'a': 'a',
        },
      );
      expect(
        'AWS4-HMAC-SHA256 Credential=awsAccessKey/$dateStamp/region/service/aws4_request, SignedHeaders=a;b;c, Signature=ae34525315a3082d37b4a7e0c2de1d9b499b38a965d1a086b122174e5a249473',
        auth,
      );
    });
  });

  group('getHeaders', () {
    test('strings', () {
      Map<String, String> res = AwsHttpRequest.getHeaders(
        'host',
        'requestBody',
        {'c': 'c'},
        'target',
        'amzDate',
        'auth',
        Duration(),
      );
      expect(
        {
          'User-Agent': 'Dart (dart:io)',
          'Accept-Encoding': 'gzip, deflate',
          'Accept': '*/*',
          'Connection': 'keep-alive',
          'Keep-Alive': 'timeout=1, max=1000',
          'Content-Type': 'application/x-amz-json-1.1',
          'Authorization': 'auth',
          'X-Amz-Date': 'amzDate',
          'x-amz-target': 'target',
          'host': 'host',
          'content-length': '11',
          'c': 'c',
        },
        res,
      );
    });
    test('overwrite string', () {
      Map<String, String> res = AwsHttpRequest.getHeaders(
        'host',
        'requestBody',
        {
          'User-Agent': '',
          'Accept-Encoding': '',
          'Accept': '',
          'Connection': '',
          'Keep-Alive': '',
          'Content-Type': '',
          'Authorization': '',
          'X-Amz-Date': '',
          'x-amz-target': '',
          'host': '',
          'content-length': '',
        },
        'target',
        'amzDate',
        'auth',
        Duration(),
      );
      expect(
        {
          'User-Agent': '',
          'Accept-Encoding': '',
          'Accept': '',
          'Connection': '',
          'Keep-Alive': '',
          'Content-Type': '',
          'Authorization': 'auth',
          'X-Amz-Date': 'amzDate',
          'x-amz-target': 'target',
          'host': 'host',
          'content-length': '11',
        },
        res,
      );
    });
    test('increased timeout', () {
      Map<String, String> res = AwsHttpRequest.getHeaders(
        'host',
        'requestBody',
        {},
        'target',
        'amzDate',
        'auth',
        Duration(seconds: 123456789),
      );
      expect(
        {
          'User-Agent': 'Dart (dart:io)',
          'Accept-Encoding': 'gzip, deflate',
          'Accept': '*/*',
          'Connection': 'keep-alive',
          'Keep-Alive': 'timeout=123456789, max=1000',
          'Content-Type': 'application/x-amz-json-1.1',
          'Authorization': 'auth',
          'X-Amz-Date': 'amzDate',
          'x-amz-target': 'target',
          'host': 'host',
          'content-length': '11',
        },
        res,
      );
    });
    test('increased timeout', () {
      Map<String, String> res = AwsHttpRequest.getHeaders(
        'host',
        'requestBody',
        {},
        'target',
        'amzDate',
        'auth',
        Duration(milliseconds: 10),
      );
      expect(
        {
          'User-Agent': 'Dart (dart:io)',
          'Accept-Encoding': 'gzip, deflate',
          'Accept': '*/*',
          'Connection': 'keep-alive',
          'Keep-Alive': 'timeout=1, max=1000',
          'Content-Type': 'application/x-amz-json-1.1',
          'Authorization': 'auth',
          'X-Amz-Date': 'amzDate',
          'x-amz-target': 'target',
          'host': 'host',
          'content-length': '11',
        },
        res,
      );
    });
  });

  group('getRequest', () {
    test('AwsRequestType.DELETE', () {
      return AwsHttpRequest.getRequest(
        AwsRequestType.DELETE,
        Uri.parse('https://www.google.com'),
        {},
        '',
        Duration(seconds: 10),
      ).then((value) {}, onError: (err) {
        fail('Missing type! AwsRequestType.DELETE, $err');
      });
    });
    test('AwsRequestType.GET', () {
      return AwsHttpRequest.getRequest(
        AwsRequestType.GET,
        Uri.parse('https://www.google.com'),
        {},
        '',
        Duration(seconds: 10),
      ).then((value) {}, onError: (err) {
        fail('Missing type! AwsRequestType.GET, $err');
      });
    });
    test('AwsRequestType.HEAD', () {
      return AwsHttpRequest.getRequest(
        AwsRequestType.HEAD,
        Uri.parse('https://www.google.com'),
        {},
        '',
        Duration(seconds: 10),
      ).then((value) {}, onError: (err) {
        fail('Missing type! AwsRequestType.HEAD, $err');
      });
    });
    test('AwsRequestType.PATCH', () {
      return AwsHttpRequest.getRequest(
        AwsRequestType.PATCH,
        Uri.parse('https://www.google.com'),
        {},
        '',
        Duration(seconds: 10),
      ).then((value) {}, onError: (err) {
        fail('Missing type! AwsRequestType.PATCH, $err');
      });
    });
    test('AwsRequestType.POST', () {
      return AwsHttpRequest.getRequest(
        AwsRequestType.POST,
        Uri.parse('https://www.google.com'),
        {},
        '',
        Duration(seconds: 10),
      ).then((value) {}, onError: (err) {
        fail('Missing type! AwsRequestType.POST, $err');
      });
    });
    test('AwsRequestType.PUT', () {
      return AwsHttpRequest.getRequest(
        AwsRequestType.PUT,
        Uri.parse('https://www.google.com'),
        {},
        '',
        Duration(seconds: 10),
      ).then((value) {}, onError: (err) {
        fail('Missing type! AwsRequestType.PUT, $err');
      });
    });

    test('failure', () {
      return AwsHttpRequest.getRequest(
        AwsRequestType.GET,
        Uri.parse('https://www.google.com'),
        {},
        '',
        Duration(seconds: 10),
        mockRequest: true,
      ).then((val) {
        fail('Mock client not detected!');
        return; // needed for compiler
      }, onError: (e) {
        expect(e, isA<AwsRequestException>());
      });
    });

    test('mockFunction != null', () {
      Future<Response> mockFunction(Request request) async {
        return Response('', 500);
      }

      return AwsHttpRequest.getRequest(
        AwsRequestType.GET,
        Uri.parse('https://www.google.com'),
        {},
        '',
        Duration(seconds: 10),
        mockFunction: mockFunction,
      ).then((val) {}, onError: (err) {
        fail(err);
      });
    });

    test('check MockClient', () {
      Future<Response> mockFunction(Request request) async {
        return Response('', 500);
      }

      return AwsHttpRequest.getRequest(
        AwsRequestType.GET,
        Uri.parse('https://www.google.com'),
        {},
        '',
        Duration(seconds: 10),
        mockFunction: mockFunction,
        mockRequest: true,
      ).then((val) {
        Request request = Request(
          'GET',
          Uri.parse('https://www.google.com'),
        );
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
      return Response(request.method, 500);
    }

    test('GET', () {
      return AwsHttpRequest.send(
        awsSecretKey: 'awsSecretKey',
        awsAccessKey: 'awsAccessKey',
        type: AwsRequestType.GET,
        service: 'service',
        target: 'target',
        region: 'region',
        timeout: Duration(),
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
        type: AwsRequestType.POST,
        service: 'service',
        target: 'target',
        region: 'region',
        timeout: Duration(),
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
        type: AwsRequestType.DELETE,
        service: 'service',
        target: 'target',
        region: 'region',
        timeout: Duration(),
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
        type: AwsRequestType.PUT,
        service: 'service',
        target: 'target',
        region: 'region',
        timeout: Duration(),
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
        type: AwsRequestType.PATCH,
        service: 'service',
        target: 'target',
        region: 'region',
        timeout: Duration(),
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
        type: AwsRequestType.HEAD,
        service: 'service',
        target: 'target',
        region: 'region',
        timeout: Duration(),
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
}
