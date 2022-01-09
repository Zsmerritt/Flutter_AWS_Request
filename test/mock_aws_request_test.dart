import 'package:aws_request/src/mock_aws_request.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

void main() {
  test('tests getter / setter values', () {
    final MockAwsRequest awsRequest = new MockAwsRequest(
      '',
      '',
      '',
      mockFunction: (Request) async {
        return Response('body', 200);
      },
    );
    expect(awsRequest.service == null, true);
    expect(awsRequest.target == null, true);
    awsRequest.service = 'testService';
    awsRequest.target = 'testTarget';
    expect(awsRequest.service == 'testService', true);
    expect(awsRequest.target == 'testTarget', true);
  });
}
