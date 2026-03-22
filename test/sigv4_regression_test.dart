// Regression tests for Phase-1 SigV4 audit findings (now passing).
//
// References:
// https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
// (UriEncode: space must be %20; Trim header values; empty URI path is /)
// https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
// (S3 UNSIGNED-PAYLOAD / x-amz-content-sha256)

import 'dart:convert';

import 'package:aws_request/src/request.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

import 'sigv4_aws_suite_vectors.dart';

void main() {
  group('SigV4 regression: credential scope casing', () {
    test(
      'get_auth_lowercases_region_and_service_in_credential_scope_per_string_to_sign',
      () {
        // docs.aws.amazon.com/general/latest/gr/sigv4-create-string-to-sign.html
        // — CredentialScope region and service must be lowercase.
        final String upper = AwsHttpRequest.getAuth(
          awsSecretKey: kAwsSuiteSecretAccessKey,
          awsAccessKey: kAwsSuiteAccessKeyId,
          amzDate: kAwsSuiteAmzDate,
          canonicalRequest: kGetVanillaCreq,
          region: 'US-EAST-1',
          service: 'SERVICE',
          signedHeaders: const <String, String>{
            'host': kAwsSuiteHost,
            'x-amz-date': kAwsSuiteAmzDate,
          },
        );
        final String lower = AwsHttpRequest.getAuth(
          awsSecretKey: kAwsSuiteSecretAccessKey,
          awsAccessKey: kAwsSuiteAccessKeyId,
          amzDate: kAwsSuiteAmzDate,
          canonicalRequest: kGetVanillaCreq,
          region: kAwsSuiteRegion,
          service: kAwsSuiteService,
          signedHeaders: const <String, String>{
            'host': kAwsSuiteHost,
            'x-amz-date': kAwsSuiteAmzDate,
          },
        );
        expect(upper, lower);
        expect(upper, contains('20150830/us-east-1/service/aws4_request'));
      },
    );
  });

  group('SigV4 regression: default signed headers vs AWS suite', () {
    test(
      'get_signed_headers_without_content_type_matches_get_vanilla_authorization',
      () {
        // SigV4: sign Content-Type only when present (Create canonical request).
        // get-vanilla has only host + x-amz-date.
        final Map<String, String> signed = AwsHttpRequest.getSignedHeaders(
          headers: <String, String>{},
          signedHeaderNames: const <String>[],
          host: kAwsSuiteHost,
          amzDate: kAwsSuiteAmzDate,
        );
        final String canonical = AwsHttpRequest.getCanonicalRequest(
          type: 'GET',
          requestBody: '',
          signedHeaders: signed,
          canonicalUri: '/',
          canonicalQuerystring: '',
        );
        final String auth = AwsHttpRequest.getAuth(
          awsSecretKey: kAwsSuiteSecretAccessKey,
          awsAccessKey: kAwsSuiteAccessKeyId,
          amzDate: kAwsSuiteAmzDate,
          canonicalRequest: canonical,
          region: kAwsSuiteRegion,
          service: kAwsSuiteService,
          signedHeaders: signed,
        );
        expect(auth, kGetVanillaAuthz);
      },
    );
  });

  group('SigV4 regression: canonical query encoding (Uri vs SigV4 UriEncode)',
      () {
    test(
      'canonical_query_string_must_encode_space_as_percent_twenty_not_plus',
      () {
        // Phase 1: Dart Uri.queryParameters uses + for space; SigV4 UriEncode
        // requires %20 (same doc as general SigV4 UriEncode rules).
        // Fix: build canonical query with a SigV4 encoder, not raw Uri.query.
        final Map<String, String>? sorted =
            AwsHttpRequest.sortedQueryParameters(<String, String>{'k': 'a b'});
        expect(
          AwsHttpRequest.sigV4CanonicalQueryString(sorted),
          'k=a%20b',
        );
      },
    );
  });

  group('SigV4 regression: canonical URI empty path', () {
    test(
      'empty_absolute_path_must_canonicalize_to_slash_per_sigv4',
      () {
        // Phase 1: AWS requires CanonicalURI '/' when absolute path is empty.
        // send() uses Uri(path: canonicalUri); path '' yields no trailing slash.
        // Fix: normalize empty path to '/' before signing and request URL.
        expect(AwsHttpRequest.canonicalUriPathForSigV4(''), '/');
      },
    );
  });

  group('SigV4 regression: canonical header name sort (prefix safety)', () {
    test(
      'canonical_headers_sort_by_name_not_by_full_line_so_a_before_a1',
      () {
        // If we sorted the full "name:value" lines, "a:x" would sort after
        // "a1:x" because ':' (58) > '1' (49). AWS orders by header name only.
        final String canonical = AwsHttpRequest.getCanonicalRequest(
          type: 'GET',
          requestBody: '',
          signedHeaders: const <String, String>{
            'a1': 'v',
            'a': 'v',
            'z': 'v',
          },
          canonicalUri: '/',
          canonicalQuerystring: '',
        );
        expect(
          canonical,
          'GET\n/\n\na:v\na1:v\nz:v\n\na;a1;z\n'
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        );
      },
    );
  });

  group('SigV4 regression: canonical header normalization', () {
    test(
      'canonical_header_values_require_trim_and_collapse_internal_spaces',
      () {
        // Phase 1: getCanonicalRequest does not Trim() or collapse spaces.
        // Suite get-header-value-trim: raw My-Header2 has "a   b   c" in .req.
        // Fix: normalize each signed header value per SigV4 before hashing.
        final String actual = AwsHttpRequest.getCanonicalRequest(
          type: 'GET',
          requestBody: '',
          signedHeaders: const <String, String>{
            'host': kAwsSuiteHost,
            'my-header1': 'value1',
            'my-header2': '"a   b   c"',
            'x-amz-date': kAwsSuiteAmzDate,
          },
          canonicalUri: '/',
          canonicalQuerystring: '',
        );
        expect(actual, kGetHeaderValueTrimCreq);
      },
    );

    test(
      'canonical_header_values_trim_leading_and_trailing_whitespace',
      () {
        // sigv4-create-canonical-request — Trim() on header values.
        final String actual = AwsHttpRequest.getCanonicalRequest(
          type: 'GET',
          requestBody: '',
          signedHeaders: <String, String>{
            'host': kAwsSuiteHost,
            'my-header1': '  value1  ',
            'my-header2': '"a   b   c"',
            'x-amz-date': kAwsSuiteAmzDate,
          },
          canonicalUri: '/',
          canonicalQuerystring: '',
        );
        expect(actual, kGetHeaderValueTrimCreq);
      },
    );
  });

  group('SigV4 regression: S3 payload hash semantics', () {
    test(
      's3_empty_body_should_use_unsigned_payload_digest_not_empty_string_hash',
      () {
        // Phase 1: S3 often uses UNSIGNED-PAYLOAD in canonical request and
        // x-amz-content-sha256; library always hashes empty string for '' body.
        // Fix: optional S3 mode — HashedPayload = hex(SHA256("UNSIGNED-PAYLOAD")).
        final String payloadLine = AwsHttpRequest.getCanonicalRequest(
          type: 'GET',
          requestBody: '',
          signedHeaders: const <String, String>{
            'host': kAwsSuiteHost,
            'x-amz-date': kAwsSuiteAmzDate,
          },
          canonicalUri: '/',
          canonicalQuerystring: '',
          hashedPayloadIsUnsigned: true,
        ).split('\n').last;
        final String unsignedPayloadHex =
            sha256.convert(utf8.encode('UNSIGNED-PAYLOAD')).toString();
        expect(payloadLine, unsignedPayloadHex);
      },
    );
  });
}
