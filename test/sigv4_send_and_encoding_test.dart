// S3 UNSIGNED-PAYLOAD via send(), non-S3 double path encoding, duplicate query
// keys via [List<MapEntry>]. See:
// https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html

import 'package:aws_request/src/request.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

void main() {
  group('send hashedPayloadIsUnsigned (S3)', () {
    test(
      'send_with_hashed_payload_unsigned_sets_x_amz_content_sha256_on_wire',
      () async {
        // Amazon S3: canonical HashedPayload uses UNSIGNED-PAYLOAD; the same
        // literal must appear in header x-amz-content-sha256.
        Future<Response> capture(Request request) async {
          expect(
            request.headers['x-amz-content-sha256'],
            'UNSIGNED-PAYLOAD',
          );
          expect(
            request.headers['authorization'],
            isNotNull,
          );
          return Response('ok', 200, request: request);
        }

        await AwsHttpRequest.send(
          awsSecretKey: 'awsSecretKey',
          awsAccessKey: 'awsAccessKey',
          type: AwsRequestType.get,
          service: 's3',
          region: 'us-east-1',
          timeout: const Duration(seconds: 10),
          headers: <String, String>{},
          jsonBody: '',
          canonicalUri: '/',
          hashedPayloadIsUnsigned: true,
          mockRequest: true,
          mockFunction: capture,
        );
      },
    );

    test(
      'send_unsigned_payload_includes_x_amz_content_sha256_in_signed_headers_list',
      () async {
        Future<Response> capture(Request request) async {
          final String? auth = request.headers['authorization'];
          expect(auth, isNotNull);
          expect(auth!, contains('x-amz-content-sha256'));
          return Response('ok', 200, request: request);
        }

        await AwsHttpRequest.send(
          awsSecretKey: 'awsSecretKey',
          awsAccessKey: 'awsAccessKey',
          type: AwsRequestType.get,
          service: 's3',
          region: 'us-east-1',
          timeout: const Duration(seconds: 10),
          headers: <String, String>{},
          jsonBody: '',
          canonicalUri: '/',
          hashedPayloadIsUnsigned: true,
          mockRequest: true,
          mockFunction: capture,
        );
      },
    );
  });

  group('canonicalUriPathNonS3DoubleEncode', () {
    test(
      'double_encodes_each_segment_so_percent_is_percent_twenty_five',
      () {
        // Non-S3: each segment is URI-encoded twice (% becomes %25).
        expect(
          AwsHttpRequest.canonicalUriPathNonS3DoubleEncode('/a%2Fb'),
          '/a%25252Fb',
        );
      },
    );

    test(
      'double_encodes_utf8_path_segment_like_sigv4_non_s3_rules',
      () {
        // First pass emits %C3%A9; hex letters C,3,A,9 are unreserved on the
        // second pass—only the `%` characters are re-encoded to %25.
        expect(
          AwsHttpRequest.canonicalUriPathNonS3DoubleEncode('/café'),
          '/caf%25C3%25A9',
        );
      },
    );

    test('empty_path_remains_slash', () {
      expect(AwsHttpRequest.canonicalUriPathNonS3DoubleEncode(''), '/');
    });
  });

  group('sigV4CanonicalQueryPairs duplicate keys', () {
    test(
      'matches_aws_suite_get_vanilla_query_order_key_canonical_query_line',
      () {
        // GET ?Param1=value2&Param1=Value1 → canonical Param1=Value1&Param1=value2
        expect(
          AwsHttpRequest.sigV4CanonicalQueryPairs(<MapEntry<String, String>>[
            const MapEntry('Param1', 'value2'),
            const MapEntry('Param1', 'Value1'),
          ]),
          'Param1=Value1&Param1=value2',
        );
      },
    );

    test(
      'map_string_string_cannot_hold_two_same_keys_last_assignment_wins',
      () {
        final Map<String, String> m = <String, String>{};
        m['Param1'] = 'value2';
        m['Param1'] = 'Value1';
        expect(m.length, 1);
        expect(
          AwsHttpRequest.sigV4CanonicalQueryString(m),
          'Param1=Value1',
          reason: 'Map collapses duplicates; use sigV4CanonicalQueryPairs',
        );
      },
    );
  });

  group('send canonicalQueryPairs', () {
    test(
      'send_builds_request_url_with_duplicate_query_names_from_pairs',
      () async {
        Future<Response> capture(Request request) async {
          expect(request.url.query, 'Param1=Value1&Param1=value2');
          return Response('ok', 200, request: request);
        }

        await AwsHttpRequest.send(
          awsSecretKey: 'awsSecretKey',
          awsAccessKey: 'awsAccessKey',
          type: AwsRequestType.get,
          service: 'service',
          region: 'us-east-1',
          timeout: const Duration(seconds: 10),
          headers: <String, String>{},
          jsonBody: '',
          canonicalUri: '/',
          canonicalQueryPairs: const <MapEntry<String, String>>[
            MapEntry('Param1', 'value2'),
            MapEntry('Param1', 'Value1'),
          ],
          mockRequest: true,
          mockFunction: capture,
        );
      },
    );
  });

  group('send useNonS3DoubleEncodedCanonicalPath', () {
    test(
      'send_uses_double_encoded_path_in_request_uri_when_flag_true',
      () async {
        Future<Response> capture(Request request) async {
          expect(request.url.path, '/a%25252Fb');
          return Response('ok', 200, request: request);
        }

        await AwsHttpRequest.send(
          awsSecretKey: 'awsSecretKey',
          awsAccessKey: 'awsAccessKey',
          type: AwsRequestType.get,
          service: 'service',
          region: 'us-east-1',
          timeout: const Duration(seconds: 10),
          headers: <String, String>{},
          jsonBody: '',
          canonicalUri: '/a%2Fb',
          useNonS3DoubleEncodedCanonicalPath: true,
          mockRequest: true,
          mockFunction: capture,
        );
      },
    );
  });
}
