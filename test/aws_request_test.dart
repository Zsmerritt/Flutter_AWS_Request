import 'package:aws_request/src/aws_request.dart';
import 'package:test/test.dart';

void main() {
  test('tests getter / setter values', () {
    final AwsRequest awsRequest = new AwsRequest('', '', '');
    expect(awsRequest.service == null, true);
    expect(awsRequest.target == null, true);
    awsRequest.service = 'testService';
    awsRequest.target = 'testTarget';
    expect(awsRequest.service == 'testService', true);
    expect(awsRequest.target == 'testTarget', true);
  });
}
