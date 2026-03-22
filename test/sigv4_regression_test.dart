// Regression tests for Phase-1 SigV4 audit findings. These intentionally fail
// until the library is fixed (do not skip). Fix hints are in each comment.
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

// Run without these tests: dart test --exclude-tags regression
void main() {
  group('SigV4 regression: default signed headers vs AWS suite', () {
    test(
      'get_signed_headers_always_adds_content_type_breaking_get_vanilla_authz_match',
      () {
        // Phase 1: getSignedHeaders injects content-type even when absent from
        // the wire request; AWS suite get-vanilla has only host + x-amz-date.
        // Fix: only sign Content-Type when present on the outbound request, or
        // align defaults with service expectations.
        // Suite: get-vanilla (.authz).
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
        expect(
          auth,
          kGetVanillaAuthz,
          reason:
              'Expected to fail until optional content-type signing is fixed',
        );
      },
    );
  }, tags: ['regression']);

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
        final Uri url = Uri(
          scheme: 'https',
          host: kAwsSuiteHost,
          path: '/',
          queryParameters: sorted,
        );
        expect(
          url.query,
          'k=a%20b',
          reason: 'Expected to fail: Uri encodes space as +',
        );
      },
    );
  }, tags: ['regression']);

  group('SigV4 regression: canonical URI empty path', () {
    test(
      'empty_absolute_path_must_canonicalize_to_slash_per_sigv4',
      () {
        // Phase 1: AWS requires CanonicalURI '/' when absolute path is empty.
        // send() uses Uri(path: canonicalUri); path '' yields no trailing slash.
        // Fix: normalize empty path to '/' before signing and request URL.
        final Uri url = Uri(
          scheme: 'https',
          host: kAwsSuiteHost,
          path: '',
        );
        expect(
          url.path,
          '/',
          reason: 'Expected to fail until empty path normalization exists',
        );
      },
    );
  }, tags: ['regression']);

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
        expect(
          actual,
          kGetHeaderValueTrimCreq,
          reason:
              'Expected to fail until header value normalization is implemented',
        );
      },
    );
  }, tags: ['regression']);

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
        ).split('\n').last;
        final String unsignedPayloadHex =
            sha256.convert(utf8.encode('UNSIGNED-PAYLOAD')).toString();
        expect(
          payloadLine,
          unsignedPayloadHex,
          reason:
              'Expected to fail: library uses empty-string hash, not S3 UNSIGNED-PAYLOAD',
        );
      },
    );
  }, tags: ['regression']);
}
