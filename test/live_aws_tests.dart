// Live integration tests against real AWS (optional; requires `.env`).
//
// ## What this package can sign/send (in theory)
//
// - **HTTP methods:** GET, POST, PUT, PATCH, DELETE, HEAD (`AwsRequestType`).
// - **SigV4:** Authorization header; credential scope; HMAC key derivation;
//   canonical request with sorted headers, query (map or duplicate-name pairs),
//   and payload hash.
// - **Paths:** normal path or non-S3 double-encoded path segments
//   (`useNonS3DoubleEncodedCanonicalPath`); empty path → `/`.
// - **Query:** `canonicalQuery` / `canonicalQueryPairs` (SigV4 `UriEncode`, `%20`).
// - **Bodies:** any UTF-8 string (JSON, form-urlencoded, etc.); hashes match bytes.
// - **S3-style:** `hashedPayloadIsUnsigned` + `x-amz-content-sha256: UNSIGNED-PAYLOAD`.
// - **STS / roles:** session token header + include `x-amz-security-token` in
//   signed headers.
// - **JSON “target” APIs:** e.g. `X-Amz-Target` + `application/x-amz-json-1.1`.
// - **Endpoints:** default `service.region.amazonaws.com` or custom `endpoint`.
//
// ## What this file exercises
//
// Only **read-only** control-plane calls that **do not create or mutate**
// resources. These are the sort of APIs often used for connectivity checks;
// **AWS pricing** still applies to some services (e.g. S3 list pricing), so this
// set avoids S3 and sticks to common “metadata / list (empty ok)” patterns.
// Except for `sts:GetCallerIdentity`, each test **passes** on **200** (and then
// checks the body) **or** on **400/403** when AWS returns a normal access-denial
// style error (narrow IAM users). Responses that look like **invalid SigV4 /
// signature / key / clock skew** always **fail** (they are not treated as IAM
// access denied). Grant actions such as `iam:GetUser`,
// `ec2:DescribeRegions`, `sqs:ListQueues`, `lambda:ListFunctions`,
// `kms:ListKeys`, `sns:ListTopics` if you want **200** on every call.
//
// Setup: copy `.env.example` to `.env` in the package root. Run from package
// root: `dart test test/live_aws_tests.dart`
//
// Skips when `.env` is missing or access keys are empty so `dart test` is safe
// for CI without credentials.

import 'dart:io';

import 'package:aws_request/src/request.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

/// Global IAM endpoint is always signed with `us-east-1`.
const String _iamSignRegion = 'us-east-1';

final class _LiveAwsCreds {
  _LiveAwsCreds._(this.env)
      : region =
            env['AWS_DEFAULT_REGION'] ?? env['AWS_REGION'] ?? 'us-east-1',
        accessKey = env['AWS_ACCESS_KEY_ID']!,
        secretKey = env['AWS_SECRET_ACCESS_KEY']!,
        sessionToken = env['AWS_SESSION_TOKEN'],
        hasSessionToken =
            (env['AWS_SESSION_TOKEN'] ?? '').trim().isNotEmpty;

  factory _LiveAwsCreds.fromEnv(Map<String, String> env) =>
      _LiveAwsCreds._(env);

  final Map<String, String> env;
  final String region;
  final String accessKey;
  final String secretKey;
  final String? sessionToken;
  final bool hasSessionToken;

  Map<String, String> get _sessionHeader => <String, String>{
        if (hasSessionToken) 'X-Amz-Security-Token': sessionToken!,
      };

  List<String> get _sessionSigned => <String>[
        if (hasSessionToken) 'x-amz-security-token',
      ];

  Future<Response> postForm({
    required String service,
    required String region,
    required String body,
    Map<String, String> headers = const <String, String>{},
    List<String> signedHeaders = const <String>[],
    String? endpoint,
  }) {
    return AwsHttpRequest.send(
      awsAccessKey: accessKey,
      awsSecretKey: secretKey,
      type: AwsRequestType.post,
      service: service,
      region: region,
      endpoint: endpoint,
      timeout: const Duration(seconds: 30),
      headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
        ..._sessionHeader,
        ...headers,
      },
      jsonBody: body,
      canonicalUri: '/',
      signedHeaders: <String>[...signedHeaders, ..._sessionSigned],
      useNonS3DoubleEncodedCanonicalPath: true,
    );
  }

  /// JSON 1.1 APIs: default package `Content-Type` is already
  /// `application/x-amz-json-1.1`.
  Future<Response> postJsonTarget({
    required String service,
    required String region,
    required String target,
    required String jsonBody,
    String? endpoint,
  }) {
    return AwsHttpRequest.send(
      awsAccessKey: accessKey,
      awsSecretKey: secretKey,
      type: AwsRequestType.post,
      service: service,
      region: region,
      endpoint: endpoint,
      timeout: const Duration(seconds: 30),
      headers: <String, String>{
        'X-Amz-Target': target,
        ..._sessionHeader,
      },
      jsonBody: jsonBody,
      canonicalUri: '/',
      signedHeaders: <String>['x-amz-target', ..._sessionSigned],
      useNonS3DoubleEncodedCanonicalPath: true,
    );
  }
}

Map<String, String>? _loadDotEnvFile() {
  final File f = File('.env');
  if (!f.existsSync()) {
    return null;
  }
  return _parseDotEnv(f.readAsStringSync());
}

Map<String, String> _parseDotEnv(String content) {
  final Map<String, String> out = <String, String>{};
  for (final String rawLine in content.split(RegExp(r'\r?\n'))) {
    final String line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }
    final int eq = line.indexOf('=');
    if (eq <= 0) {
      continue;
    }
    final String key = line.substring(0, eq).trim();
    String val = line.substring(eq + 1).trim();
    if (val.length >= 2) {
      if ((val.startsWith('"') && val.endsWith('"')) ||
          (val.startsWith("'") && val.endsWith("'"))) {
        val = val.substring(1, val.length - 1);
      }
    }
    out[key] = val;
  }
  return out;
}

String? _skipReason(Map<String, String>? env) {
  if (env == null) {
    return 'No .env in package root; copy .env.example to .env and add credentials.';
  }
  final String ak = env['AWS_ACCESS_KEY_ID'] ?? '';
  final String sk = env['AWS_SECRET_ACCESS_KEY'] ?? '';
  if (ak.isEmpty || sk.isEmpty) {
    return 'Set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY in .env';
  }
  return null;
}

/// AWS responses that indicate the **request signature or credentials** are
/// wrong—not “you are not allowed to call this API”. If these match, live tests
/// must **fail** so bad SigV4 is never confused with IAM scope issues.
///
/// See e.g. [Common Errors](https://docs.aws.amazon.com/STS/latest/APIReference/CommonErrors.html)
/// and SigV4 troubleshooting in the AWS General Reference.
final RegExp _awsSigV4OrCredentialFailureLike = RegExp(
  'SignatureDoesNotMatch|IncompleteSignature|InvalidSignature|'
  'InvalidSignatureException|InvalidAccessKeyId|InvalidClientTokenId|'
  'RequestExpired|SignatureExpired|RequestTimeTooSkewed|'
  'Credential should be scoped|CredentialScope|'
  'The request signature we calculated does not match|'
  'signature you provided does not match|'
  'not able to validate the provided access credentials|'
  'AWS was not able to validate the provided access credentials',
  caseSensitive: false,
);

/// Strict success, or AWS “not allowed / not recognized” style errors (narrow
/// IAM policies). Does not accept 5xx or unexpected 4xx.
final RegExp _awsAccessDeniedLike = RegExp(
  'AccessDenied|UnauthorizedOperation|AuthorizationError|AccessDeniedException|'
  'not authorized to perform|NotAuthorized|Unable to determine service',
  caseSensitive: false,
);

void _failIfAwsSigV4OrCredentialFailure(
  Response response, {
  required String context,
}) {
  if (_awsSigV4OrCredentialFailureLike.hasMatch(response.body)) {
    fail(
      '$context: looks like SigV4/signature/credential/clock problem (not IAM '
      'access denied) — status=${response.statusCode} body=${response.body}',
    );
  }
}

void _expect200OrAwsAccessDenied(
  Response response, {
  required void Function(Response ok) onOk,
  String context = 'live read-only call',
}) {
  final int code = response.statusCode;
  if (code == 200) {
    _failIfAwsSigV4OrCredentialFailure(response, context: context);
    onOk(response);
    return;
  }
  _failIfAwsSigV4OrCredentialFailure(response, context: context);
  expect(
    code,
    anyOf(400, 403),
    reason: 'Unexpected status=$code body=${response.body}',
  );
  expect(
    _awsAccessDeniedLike.hasMatch(response.body),
    isTrue,
    reason: 'Expected AWS access / authorization style body, got: ${response.body}',
  );
}

void main() {
  final Map<String, String>? envMap = _loadDotEnvFile();
  final String? skipReason = _skipReason(envMap);

  group('Live AWS read-only API checks', () {
    late _LiveAwsCreds c;

    setUpAll(() {
      if (skipReason == null) {
        c = _LiveAwsCreds.fromEnv(envMap!);
      }
    });

    test('sts:GetCallerIdentity (Query POST, XML)', () async {
      final Response response = await c.postForm(
        service: 'sts',
        region: c.region,
        body: 'Action=GetCallerIdentity&Version=2011-06-15',
      );
      _failIfAwsSigV4OrCredentialFailure(response,
          context: 'sts:GetCallerIdentity');
      expect(response.statusCode, 200,
          reason: 'STS error body: ${response.body}');
      expect(response.body, contains('GetCallerIdentityResponse'));
      expect(response.body, contains('Arn'));
    }, skip: skipReason);

    test(
      'sts:GetCallerIdentity with wrong secret must fail with signature error',
      () async {
        final Map<String, String> headers = <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
          if (c.hasSessionToken) 'X-Amz-Security-Token': c.sessionToken!,
        };
        final List<String> signed = <String>[
          if (c.hasSessionToken) 'x-amz-security-token',
        ];
        final Response response = await AwsHttpRequest.send(
          awsAccessKey: c.accessKey,
          awsSecretKey: '${c.secretKey}__INVALID__',
          type: AwsRequestType.post,
          service: 'sts',
          region: c.region,
          timeout: const Duration(seconds: 30),
          headers: headers,
          jsonBody: 'Action=GetCallerIdentity&Version=2011-06-15',
          canonicalUri: '/',
          signedHeaders: signed,
          useNonS3DoubleEncodedCanonicalPath: true,
        );
        expect(response.statusCode, isNot(200),
            reason: 'wrong secret must not return 200: ${response.body}');
        expect(
          _awsSigV4OrCredentialFailureLike.hasMatch(response.body),
          isTrue,
          reason:
              'Expected AWS SigV4/signature/credential error in body, got '
              'status=${response.statusCode}: ${response.body}',
        );
      },
      skip: skipReason,
    );

    // IAM JSON RPC (`X-Amz-Target`) has returned 302 redirects for some clients
    // hitting `iam.amazonaws.com`; the Query API matches STS and is stable here.
    test('iam:GetUser (Query POST, XML, caller when UserName omitted)', () async {
      final Response response = await c.postForm(
        service: 'iam',
        region: _iamSignRegion,
        endpoint: 'iam.amazonaws.com',
        body: 'Action=GetUser&Version=2010-05-08',
      );
      _expect200OrAwsAccessDenied(response,
          context: 'iam:GetUser',
          onOk: (Response ok) {
        expect(ok.body, contains('GetUserResponse'));
      });
    }, skip: skipReason);

    test('ec2:DescribeRegions (Query POST, XML)', () async {
      final Response response = await c.postForm(
        service: 'ec2',
        region: c.region,
        body: 'Action=DescribeRegions&Version=2016-11-15',
      );
      _expect200OrAwsAccessDenied(response,
          context: 'ec2:DescribeRegions',
          onOk: (Response ok) {
        expect(ok.body, contains('DescribeRegionsResponse'));
        expect(ok.body, contains('regionName'));
      });
    }, skip: skipReason);

    test('sqs:ListQueues (Query POST, XML)', () async {
      final Response response = await c.postForm(
        service: 'sqs',
        region: c.region,
        body: 'Action=ListQueues&Version=2012-11-05',
      );
      _expect200OrAwsAccessDenied(response,
          context: 'sqs:ListQueues',
          onOk: (Response ok) {
        expect(ok.body, contains('ListQueuesResponse'));
      });
    }, skip: skipReason);

    test('lambda:ListFunctions (JSON 1.1)', () async {
      final Response response = await c.postJsonTarget(
        service: 'lambda',
        region: c.region,
        target: 'AWSLambda_20150331.ListFunctions',
        jsonBody: '{"MaxItems":1}',
      );
      _expect200OrAwsAccessDenied(response,
          context: 'lambda:ListFunctions',
          onOk: (Response ok) {
        expect(ok.body, contains('"Functions"'));
      });
    }, skip: skipReason);

    test('kms:ListKeys (JSON 1.1)', () async {
      final Response response = await c.postJsonTarget(
        service: 'kms',
        region: c.region,
        target: 'TrentService.ListKeys',
        jsonBody: '{"Limit":1}',
      );
      _expect200OrAwsAccessDenied(response,
          context: 'kms:ListKeys',
          onOk: (Response ok) {
        expect(ok.body, contains('"Keys"'));
      });
    }, skip: skipReason);

    test('sns:ListTopics (Query POST, XML)', () async {
      final Response response = await c.postForm(
        service: 'sns',
        region: c.region,
        body: 'Action=ListTopics&Version=2010-03-31',
      );
      _expect200OrAwsAccessDenied(response,
          context: 'sns:ListTopics',
          onOk: (Response ok) {
        expect(ok.body, contains('ListTopicsResponse'));
      });
    }, skip: skipReason);
  });
}
