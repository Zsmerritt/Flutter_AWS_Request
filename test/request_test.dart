import 'package:aws_request/aws_request.dart';
import 'package:aws_request/src/request.dart';
import 'package:test/test.dart';

void main() {
  group('build functions', () {
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
      throw Exception(
          "Something went wrong. The last line didn't cause an error");
    });
  });
}
