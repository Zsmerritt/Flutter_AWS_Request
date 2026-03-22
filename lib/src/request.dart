import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';

part 'util.dart';

class AwsHttpRequest {
  static String _formatAmzDate(DateTime dt) {
    final DateTime utc = dt.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}'
        '${utc.month.toString().padLeft(2, '0')}'
        '${utc.day.toString().padLeft(2, '0')}'
        'T'
        '${utc.hour.toString().padLeft(2, '0')}'
        '${utc.minute.toString().padLeft(2, '0')}'
        '${utc.second.toString().padLeft(2, '0')}'
        'Z';
  }

  /// Returns a copy of [canonicalQuery] with entries sorted by key, then by
  /// value, per SigV4 canonical query rules. Returns null when
  /// [canonicalQuery] is null.
  static Map<String, String>? sortedQueryParameters(
    Map<String, String>? canonicalQuery,
  ) {
    if (canonicalQuery == null) {
      return null;
    }
    return Map<String, String>.fromEntries(
      canonicalQuery.entries.toList()
        ..sort((MapEntry<String, String> a, MapEntry<String, String> b) {
          final int c = a.key.compareTo(b.key);
          if (c != 0) {
            return c;
          }
          return a.value.compareTo(b.value);
        }),
    );
  }

  /// SigV4 [UriEncode] (Create canonical request): encode each UTF-8 byte except
  /// unreserved characters; space is `%20` (never `+`).
  /// https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
  static String _sigV4UriEncode(String input) {
    const String unreserved =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final StringBuffer out = StringBuffer();
    for (final int unit in utf8.encode(input)) {
      if (unit < 128 && unreserved.contains(String.fromCharCode(unit))) {
        out.writeCharCode(unit);
      } else {
        out.write('%${unit.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      }
    }
    return out.toString();
  }

  /// Canonical query string for SigV4 (sorted name=value pairs, `&`-joined).
  static String sigV4CanonicalQueryString(Map<String, String>? canonicalQuery) {
    final Map<String, String>? sorted = sortedQueryParameters(canonicalQuery);
    if (sorted == null || sorted.isEmpty) {
      return '';
    }
    final List<String> parts = <String>[];
    sorted.forEach((String k, String v) {
      parts.add('${_sigV4UriEncode(k)}=${_sigV4UriEncode(v)}');
    });
    return parts.join('&');
  }

  /// Same as [sigV4CanonicalQueryString] but allows duplicate parameter names
  /// (e.g. `?Param1=a&Param1=b`). [Map] cannot represent that use case.
  /// https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
  static String sigV4CanonicalQueryPairs(List<MapEntry<String, String>> pairs) {
    if (pairs.isEmpty) {
      return '';
    }
    final List<MapEntry<String, String>> sorted =
        List<MapEntry<String, String>>.from(pairs)
          ..sort((MapEntry<String, String> a, MapEntry<String, String> b) {
            final int c = a.key.compareTo(b.key);
            if (c != 0) {
              return c;
            }
            return a.value.compareTo(b.value);
          });
    return sorted
        .map(
          (MapEntry<String, String> e) =>
              '${_sigV4UriEncode(e.key)}=${_sigV4UriEncode(e.value)}',
        )
        .join('&');
  }

  /// Non-S3 SigV4: each path segment is URI-encoded twice (S3 uses a single pass).
  /// [path] should start with `/` (except empty → `/`).
  /// https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
  static String canonicalUriPathNonS3DoubleEncode(String path) {
    final String normalized = canonicalUriPathForSigV4(path);
    if (normalized == '/') {
      return '/';
    }
    final List<String> segments = normalized.split('/');
    final List<String> encoded = <String>[];
    for (final String seg in segments) {
      if (seg.isEmpty) {
        continue;
      }
      encoded.add(_sigV4UriEncode(_sigV4UriEncode(seg)));
    }
    return '/${encoded.join('/')}';
  }

  /// Empty absolute path must be `/` for CanonicalURI (SigV4).
  /// https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
  static String canonicalUriPathForSigV4(String path) =>
      path.isEmpty ? '/' : path;

  /// Trim and collapse consecutive spaces in a header value (CanonicalHeaders).
  /// https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
  static String canonicalHeaderValueForSigV4(String value) {
    final String trimmed = value.trim();
    return trimmed.replaceAll(RegExp(' +'), ' ');
  }

  static Map<String, String> getSignedHeaders({
    required Map<String, String> headers,
    required List<String> signedHeaderNames,
    required String host,
    required String amzDate,
  }) {
    final Map<String, String> signedHeaders = {
      'host': host,
      'x-amz-date': amzDate,
    };
    for (final String requestedName in signedHeaderNames) {
      final String lower = requestedName.toLowerCase();
      if (signedHeaders.containsKey(lower)) {
        continue;
      }
      final String? keyInHeaders = headers.keys
          .cast<String?>()
          .firstWhere((k) => k!.toLowerCase() == lower, orElse: () => null);
      if (keyInHeaders != null) {
        signedHeaders[lower] = headers[keyInHeaders]!;
      } else {
        throw AwsRequestException(
            message: 'AwsRequest ERROR: Signed Header Not Found: '
                '$requestedName could not be found in the included headers. '
                'Provided header keys are ${headers.keys.toList()} '
                'All headers besides [host, x-amz-date] '
                'that are included in signedHeaders must be included in headers',
            stackTrace: StackTrace.current);
      }
    }
    final String? contentTypeKey = headers.keys
        .cast<String?>()
        .firstWhere((k) => k!.toLowerCase() == 'content-type',
            orElse: () => null);
    if (contentTypeKey != null) {
      signedHeaders['content-type'] = headers[contentTypeKey]!;
    }
    return signedHeaders;
  }

  static Digest sign({required List<int> key, required String msg}) {
    return Hmac(sha256, key).convert(utf8.encode(msg));
  }

  static String getSignature({
    required String key,
    required String dateStamp,
    required String regionName,
    required String serviceName,
    required String stringToSign,
  }) {
    final List<int> kDate = Hmac(sha256, utf8.encode('AWS4$key'))
        .convert(utf8.encode(dateStamp))
        .bytes;
    final List<int> kRegion = sign(key: kDate, msg: regionName).bytes;
    final List<int> kService = sign(key: kRegion, msg: serviceName).bytes;
    final List<int> kSigning = sign(key: kService, msg: 'aws4_request').bytes;
    return sign(key: kSigning, msg: stringToSign).toString();
  }

  static String getCanonicalRequest({
    required String type,
    required String requestBody,
    required Map<String, String> signedHeaders,
    required String canonicalUri,
    required String canonicalQuerystring,
    bool hashedPayloadIsUnsigned = false,
  }) {
    final List<String> canonicalHeaders = [];
    signedHeaders.forEach((key, value) {
      canonicalHeaders.add(
          '$key:${canonicalHeaderValueForSigV4(value)}\n');
    });
    canonicalHeaders.sort();
    final String canonicalHeadersString = canonicalHeaders.join('');
    final List<String> keyList = signedHeaders.keys.toList()..sort();
    final String signedHeaderKeys = keyList.join(';');
    final String payloadHash = hashedPayloadIsUnsigned
        ? sha256.convert(utf8.encode('UNSIGNED-PAYLOAD')).toString()
        : sha256.convert(utf8.encode(requestBody)).toString();
    final String canonicalRequest =
        '$type\n$canonicalUri\n$canonicalQuerystring\n$canonicalHeadersString\n'
        '$signedHeaderKeys\n$payloadHash';
    return canonicalRequest;
  }

  static String getAuth({
    required String awsSecretKey,
    required String awsAccessKey,
    required String amzDate,
    required String canonicalRequest,
    required String region,
    required String service,
    required Map<String, String> signedHeaders,
  }) {
    const String algorithm = 'AWS4-HMAC-SHA256';
    final String dateStamp = amzDate.substring(0, 8);
    // Region and service must be lowercase in credential scope and in signing
    // key derivation (HMAC chain).
    // https://docs.aws.amazon.com/general/latest/gr/sigv4-create-string-to-sign.html
    // https://docs.aws.amazon.com/general/latest/gr/sigv4-calculate-signature.html
    final String regionLc = region.toLowerCase();
    final String serviceLc = service.toLowerCase();
    final String credentialScope =
        '$dateStamp/$regionLc/$serviceLc/aws4_request';
    final String stringToSign = '$algorithm\n$amzDate\n$credentialScope\n'
        '${sha256.convert(utf8.encode(canonicalRequest)).toString()}';
    final String signature = getSignature(
      key: awsSecretKey,
      dateStamp: dateStamp,
      regionName: regionLc,
      serviceName: serviceLc,
      stringToSign: stringToSign,
    );
    final List<String> keyList = signedHeaders.keys.toList()..sort();
    final String signedHeaderKeys = keyList.join(';');
    return '$algorithm Credential=$awsAccessKey/$credentialScope, '
        'SignedHeaders=$signedHeaderKeys, '
        'Signature=$signature';
  }

  static Map<String, String> getHeaders({
    required Map<String, String> headers,
    required String amzDate,
    required String auth,
  }) {
    return {
      ...defaultHeaders,
      ...headers,
      ...{
        'Authorization': auth,
        'x-amz-date': amzDate,
      }
    };
  }

  static Future<Response> getRequest({
    required AwsRequestType type,
    required Uri url,
    required Map<String, String> headers,
    required String body,
    required Duration timeout,
    bool mockRequest = false,
    Future<Response> Function(Request)? mockFunction,
  }) async {
    if (mockRequest && mockFunction == null) {
      throw AwsRequestException(
        message: 'mockFunction is required when mockRequest is true',
        stackTrace: StackTrace.current,
      );
    }
    final Client client = mockRequest ? MockClient(mockFunction!) : Client();
    try {
      final Future<Response> future;
      switch (type) {
        case AwsRequestType.get:
          future = client.get(
            url,
            headers: headers,
          );
          break;
        case AwsRequestType.post:
          future = client.post(
            url,
            headers: headers,
            body: utf8.encode(body),
          );
          break;
        case AwsRequestType.delete:
          future = client.delete(
            url,
            headers: headers,
            body: utf8.encode(body),
          );
          break;
        case AwsRequestType.patch:
          future = client.patch(
            url,
            headers: headers,
            body: utf8.encode(body),
          );
          break;
        case AwsRequestType.put:
          future = client.put(
            url,
            headers: headers,
            body: utf8.encode(body),
          );
          break;
        case AwsRequestType.head:
          future = client.head(
            url,
            headers: headers,
          );
          break;
      }
      return await future.timeout(timeout, onTimeout: () {
        throw TimeoutException('AwsRequest Timed Out', timeout);
      });
    } finally {
      client.close();
    }
  }

  static Future<Response> send({
    required String awsSecretKey,
    required String awsAccessKey,
    required AwsRequestType type,
    required String service,
    required String region,
    required Duration timeout,
    List<String> signedHeaders = const [],
    required Map<String, String> headers,
    required String jsonBody,
    required String canonicalUri,
    Map<String, String>? canonicalQuery,
    List<MapEntry<String, String>>? canonicalQueryPairs,
    bool hashedPayloadIsUnsigned = false,
    bool useNonS3DoubleEncodedCanonicalPath = false,
    String? endpoint,
    bool mockRequest = false,
    Future<Response> Function(Request)? mockFunction,
  }) async {
    if (awsAccessKey.isEmpty || awsSecretKey.isEmpty) {
      throw AwsRequestException(
        message: 'AwsRequest ERROR: awsAccessKey and awsSecretKey must be '
            'non-empty strings.',
        stackTrace: StackTrace.current,
      );
    }
    final String host = endpoint ?? '$service.$region.amazonaws.com';
    final Map<String, String>? sortedQueryParams =
        sortedQueryParameters(canonicalQuery);
    final String pathForRequest = useNonS3DoubleEncodedCanonicalPath
        ? canonicalUriPathNonS3DoubleEncode(canonicalUri)
        : canonicalUriPathForSigV4(canonicalUri);
    final String sortedCanonicalQuery = canonicalQueryPairs != null
        ? sigV4CanonicalQueryPairs(canonicalQueryPairs)
        : sigV4CanonicalQueryString(sortedQueryParams);
    final Uri url = sortedCanonicalQuery.isEmpty
        ? Uri(scheme: 'https', host: host, path: pathForRequest)
        : Uri(
            scheme: 'https',
            host: host,
            path: pathForRequest,
            query: sortedCanonicalQuery,
          );
    final String amzDate = _formatAmzDate(DateTime.now());
    Map<String, String> headersForSigning = {
      ...defaultHeaders,
      ...headers,
    };
    if (hashedPayloadIsUnsigned) {
      headersForSigning = {
        ...headersForSigning,
        'x-amz-content-sha256': 'UNSIGNED-PAYLOAD',
      };
    }
    final bool hasAmzContentSha256 = signedHeaders.any(
      (String s) => s.toLowerCase() == 'x-amz-content-sha256',
    );
    final List<String> signedHeaderNames = <String>[
      ...signedHeaders,
      if (hashedPayloadIsUnsigned && !hasAmzContentSha256)
        'x-amz-content-sha256',
    ];
    final Map<String, String> signedHeadersMap = getSignedHeaders(
      headers: headersForSigning,
      signedHeaderNames: signedHeaderNames,
      host: host,
      amzDate: amzDate,
    );

    final String canonicalRequest = getCanonicalRequest(
      type: type.name.toUpperCase(),
      requestBody: jsonBody,
      signedHeaders: signedHeadersMap,
      canonicalUri: url.path,
      canonicalQuerystring: sortedCanonicalQuery,
      hashedPayloadIsUnsigned: hashedPayloadIsUnsigned,
    );
    final String auth = getAuth(
      awsSecretKey: awsSecretKey,
      awsAccessKey: awsAccessKey,
      amzDate: amzDate,
      canonicalRequest: canonicalRequest,
      region: region,
      service: service,
      signedHeaders: signedHeadersMap,
    );
    final Map<String, String> headersForWire = {
      ...headers,
      if (hashedPayloadIsUnsigned) 'x-amz-content-sha256': 'UNSIGNED-PAYLOAD',
    };
    final Map<String, String> updatedHeaders = getHeaders(
      headers: headersForWire,
      amzDate: amzDate,
      auth: auth,
    );

    return getRequest(
      type: type,
      url: url,
      headers: updatedHeaders,
      body: jsonBody,
      timeout: timeout,
      mockRequest: mockRequest,
      mockFunction: mockFunction,
    );
  }
}
