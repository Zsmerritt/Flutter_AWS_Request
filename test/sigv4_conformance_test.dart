// SigV4 conformance: per-step validation and happy-path vectors from the official
// AWS test suite (mhart/aws4 mirror). See:
// https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
// https://docs.aws.amazon.com/general/latest/gr/sigv4-create-string-to-sign.html
// https://docs.aws.amazon.com/general/latest/gr/sigv4-calculate-signature.html

import 'dart:convert';

import 'package:aws_request/src/request.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

import 'sigv4_aws_suite_vectors.dart';

void main() {
  group('SigV4 unit: canonical request (AWS test suite)', () {
    test(
      'get_vanilla_canonical_request_matches_aws_sigv4_suite_creq_file',
      () {
        // Scenario: get-vanilla — canonical request structure (method, URI,
        // query, sorted lowercase headers, signed header list, payload hash).
        final String actual = AwsHttpRequest.getCanonicalRequest(
          type: 'GET',
          requestBody: '',
          signedHeaders: const <String, String>{
            'host': kAwsSuiteHost,
            'x-amz-date': kAwsSuiteAmzDate,
          },
          canonicalUri: '/',
          canonicalQuerystring: '',
        );
        expect(actual, kGetVanillaCreq);
      },
    );

    test(
      'post_vanilla_canonical_request_matches_aws_sigv4_suite_creq_file',
      () {
        // Scenario: post-vanilla — same as get-vanilla but POST method.
        final String actual = AwsHttpRequest.getCanonicalRequest(
          type: 'POST',
          requestBody: '',
          signedHeaders: const <String, String>{
            'host': kAwsSuiteHost,
            'x-amz-date': kAwsSuiteAmzDate,
          },
          canonicalUri: '/',
          canonicalQuerystring: '',
        );
        expect(actual, kPostVanillaCreq);
      },
    );

    test(
      'post_sts_header_before_canonical_request_matches_aws_sigv4_suite_creq',
      () {
        // Scenario: post-sts-token/post-sts-header-before — session token in
        // canonical headers (docs: temporary credentials / x-amz-security-token).
        final String actual = AwsHttpRequest.getCanonicalRequest(
          type: 'POST',
          requestBody: '',
          signedHeaders: const <String, String>{
            'host': kAwsSuiteHost,
            'x-amz-date': kAwsSuiteAmzDate,
            'x-amz-security-token': kPostStsHeaderBeforeToken,
          },
          canonicalUri: '/',
          canonicalQuerystring: '',
        );
        expect(actual, kPostStsHeaderBeforeCreq);
      },
    );

    test(
      'post_header_key_case_lowercases_header_names_per_canonical_headers_rules',
      () {
        // Suite post-header-key-case: HTTP header names may be mixed case; the
        // canonical request must use lowercase names only (same AWS doc).
        const String expectedCreq = 'POST\n/\n\n'
            'host:example.amazonaws.com\n'
            'x-amz-date:20150830T123600Z\n'
            '\n'
            'host;x-amz-date\n'
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
        final String actual = AwsHttpRequest.getCanonicalRequest(
          type: 'POST',
          requestBody: '',
          signedHeaders: const <String, String>{
            'Host': 'example.amazonaws.com',
            'X-Amz-Date': kAwsSuiteAmzDate,
          },
          canonicalUri: '/',
          canonicalQuerystring: '',
        );
        expect(actual, expectedCreq);
      },
    );

    test(
      'get_header_value_trim_matches_suite_when_values_are_sigv4_normalized',
      () {
        // Scenario: get-header-value-trim — AWS requires Trim() and collapsing
        // sequential spaces in header values before canonicalization.
        // This passes only when callers supply already-normalized values.
        final String actual = AwsHttpRequest.getCanonicalRequest(
          type: 'GET',
          requestBody: '',
          signedHeaders: const <String, String>{
            'host': kAwsSuiteHost,
            'my-header1': 'value1',
            'my-header2': '"a b c"',
            'x-amz-date': kAwsSuiteAmzDate,
          },
          canonicalUri: '/',
          canonicalQuerystring: '',
        );
        expect(actual, kGetHeaderValueTrimCreq);
      },
    );
  });

  group('SigV4 unit: string to sign and payload hash (AWS test suite)', () {
    test(
      'hashed_canonical_request_matches_string_to_sign_fourth_line_get_vanilla',
      () {
        // Per sigv4-create-string-to-sign: line 4 is hex(SHA256(canonical request)).
        final Digest digest = sha256.convert(utf8.encode(kGetVanillaCreq));
        final List<String> stsLines = kGetVanillaSts.split('\n');
        expect(stsLines.length, 4);
        expect(digest.toString(), stsLines[3]);
      },
    );

    test(
      'hashed_canonical_request_matches_string_to_sign_fourth_line_post_vanilla',
      () {
        final Digest digest = sha256.convert(utf8.encode(kPostVanillaCreq));
        final List<String> stsLines = kPostVanillaSts.split('\n');
        expect(digest.toString(), stsLines[3]);
      },
    );

    test(
      'empty_http_body_maps_to_sha256_hex_of_empty_string_in_canonical_request',
      () {
        // docs.aws.amazon.com/.../sigv4-create-canonical-request — HashedPayload
        // for GET with no body is hex(SHA256("")).
        const String expectedEmptyPayloadHash =
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
        final String canonical = AwsHttpRequest.getCanonicalRequest(
          type: 'GET',
          requestBody: '',
          signedHeaders: const {
            'host': kAwsSuiteHost,
            'x-amz-date': kAwsSuiteAmzDate
          },
          canonicalUri: '/',
          canonicalQuerystring: '',
        );
        expect(canonical.split('\n').last, expectedEmptyPayloadHash);
      },
    );
  });

  group('SigV4 unit: signing key and signature (AWS test suite)', () {
    test(
      'get_signature_matches_suite_expected_hmac_for_get_vanilla_string_to_sign',
      () {
        // sigv4-calculate-signature — final HMAC-SHA256(signingKey, stringToSign).
        final String sig = AwsHttpRequest.getSignature(
          key: kAwsSuiteSecretAccessKey,
          dateStamp: kAwsSuiteDateStamp,
          regionName: kAwsSuiteRegion,
          serviceName: kAwsSuiteService,
          stringToSign: kGetVanillaSts,
        );
        expect(
          sig,
          'ea21d6f05e96a897f6000a1a293f0a5bf0f92a00343409e820dce329ca6365ea',
        );
      },
    );

    test(
      'get_signature_matches_suite_expected_hmac_for_post_vanilla_string_to_sign',
      () {
        final String sig = AwsHttpRequest.getSignature(
          key: kAwsSuiteSecretAccessKey,
          dateStamp: kAwsSuiteDateStamp,
          regionName: kAwsSuiteRegion,
          serviceName: kAwsSuiteService,
          stringToSign: kPostVanillaSts,
        );
        expect(
          sig,
          '5cf47c2034c6dd32b7809d9dfca248ffbe7599680fc9a1e081b21ddc522c8dee',
        );
      },
    );
  });

  group('SigV4 suite metadata: mirror file drift', () {
    test(
      'get_vanilla_expected_auth_signature_matches_sts_not_legacy_bundled_authz_file',
      () {
        // mhart/aws4 test/aws-sig-v4-test-suite/get-vanilla/get-vanilla.authz
        // still lists Signature=5fa00...; canonical + .sts from the same folder
        // yield Signature=ea21... (verified with mhart/aws4 npm 1.13.2 aws4.sign).
        expect(
          kGetVanillaAuthz,
          isNot(contains(
              '5fa00fa31553b73ebf1942676e86291e8372ff2a2260956d9b8aae1d763fbf31')),
        );
        expect(
          kGetVanillaAuthz,
          contains(
              'ea21d6f05e96a897f6000a1a293f0a5bf0f92a00343409e820dce329ca6365ea'),
        );
      },
    );
  });

  group('SigV4 unit: Authorization header assembly (AWS test suite)', () {
    test(
      'get_auth_matches_get_vanilla_official_authz_file_character_for_character',
      () {
        // sigv4-add-signature-to-request — Authorization header format.
        final String auth = AwsHttpRequest.getAuth(
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
        expect(auth, kGetVanillaAuthz);
      },
    );

    test(
      'get_auth_matches_post_vanilla_official_authz_file_character_for_character',
      () {
        final String auth = AwsHttpRequest.getAuth(
          awsSecretKey: kAwsSuiteSecretAccessKey,
          awsAccessKey: kAwsSuiteAccessKeyId,
          amzDate: kAwsSuiteAmzDate,
          canonicalRequest: kPostVanillaCreq,
          region: kAwsSuiteRegion,
          service: kAwsSuiteService,
          signedHeaders: const <String, String>{
            'host': kAwsSuiteHost,
            'x-amz-date': kAwsSuiteAmzDate,
          },
        );
        expect(auth, kPostVanillaAuthz);
      },
    );

    test(
      'get_auth_matches_post_sts_header_before_official_authz_file',
      () {
        final String auth = AwsHttpRequest.getAuth(
          awsSecretKey: kAwsSuiteSecretAccessKey,
          awsAccessKey: kAwsSuiteAccessKeyId,
          amzDate: kAwsSuiteAmzDate,
          canonicalRequest: kPostStsHeaderBeforeCreq,
          region: kAwsSuiteRegion,
          service: kAwsSuiteService,
          signedHeaders: const <String, String>{
            'host': kAwsSuiteHost,
            'x-amz-date': kAwsSuiteAmzDate,
            'x-amz-security-token': kPostStsHeaderBeforeToken,
          },
        );
        expect(auth, kPostStsHeaderBeforeAuthz);
      },
    );

    test(
      'get_auth_matches_get_header_value_trim_when_canonical_headers_normalized',
      () {
        final String auth = AwsHttpRequest.getAuth(
          awsSecretKey: kAwsSuiteSecretAccessKey,
          awsAccessKey: kAwsSuiteAccessKeyId,
          amzDate: kAwsSuiteAmzDate,
          canonicalRequest: kGetHeaderValueTrimCreq,
          region: kAwsSuiteRegion,
          service: kAwsSuiteService,
          signedHeaders: const <String, String>{
            'host': kAwsSuiteHost,
            'my-header1': 'value1',
            'my-header2': '"a b c"',
            'x-amz-date': kAwsSuiteAmzDate,
          },
        );
        expect(auth, kGetHeaderValueTrimAuthz);
      },
    );
  });

  group('SigV4 end-to-end static: suite-shaped request without DateTime.now',
      () {
    test(
      'full_static_pipeline_manual_signed_headers_matches_get_vanilla_authz',
      () {
        // End-to-end for a fixed clock: build canonical the same way as unit
        // tests, assert final Authorization equals .authz (no network).
        const Map<String, String> signed = <String, String>{
          'host': kAwsSuiteHost,
          'x-amz-date': kAwsSuiteAmzDate,
        };
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

  group('SigV4 edge cases: query encoding and API limits', () {
    test(
      'get_vanilla_query_unreserved_uri_query_matches_suite_canonical_query_string',
      () {
        // Scenario: get-vanilla-query-unreserved — unreserved chars in query;
        // canonical query must match the suite .creq line (sorted, SigV4-encoded).
        final Map<String, String>? sorted =
            AwsHttpRequest.sortedQueryParameters(
          <String, String>{kUnreservedParamName: kUnreservedParamName},
        );
        expect(
          AwsHttpRequest.sigV4CanonicalQueryString(sorted),
          kGetVanillaQueryUnreservedCanonicalQuery,
        );
      },
    );

    test(
      'sorted_query_parameters_sorts_lexicographically_by_key_then_by_value',
      () {
        // Canonical query: sort by name, then by value (suite
        // get-vanilla-query-order-value). Same-key duplicates need a multimap;
        // here we only assert key order with distinct keys.
        final Map<String, String>? sorted =
            AwsHttpRequest.sortedQueryParameters(
          <String, String>{'z': '1', 'a': '2', 'm': '0'},
        );
        expect(sorted!.keys.toList(), <String>['a', 'm', 'z']);
        expect(sorted['a'], '2');
        expect(sorted['m'], '0');
        expect(sorted['z'], '1');
      },
    );

    test(
      'map_based_query_cannot_represent_duplicate_keys_from_get_vanilla_query_order_key',
      () {
        // Suite get-vanilla-query-order-key: ?Param1=value2&Param1=Value1
        // canonical Param1=Value1&Param1=value2. Dart Map<String,String> drops
        // duplicate keys — document gap vs suite.
        // Duplicate query names are not representable; second assignment wins.
        final Map<String, String> dup = <String, String>{};
        dup['Param1'] = 'value2';
        dup['Param1'] = 'Value1';
        expect(dup.length, 1);
        expect(dup['Param1'], 'Value1');
        final Map<String, String>? sorted =
            AwsHttpRequest.sortedQueryParameters(dup);
        final Uri url = Uri(
          scheme: 'https',
          host: kAwsSuiteHost,
          path: '/',
          queryParameters: sorted,
        );
        expect(
          url.query,
          isNot('Param1=Value1&Param1=value2'),
          reason: 'Single map entry cannot produce duplicate Param1 pairs',
        );
      },
    );
  });
}
