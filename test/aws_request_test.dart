import 'package:aws_request/aws_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tests getter / setter values', () {
    final AwsRequest awsRequest = new AwsRequest('', '', '');
    expect(awsRequest.getService() == null, true);
    expect(awsRequest.getTarget() == null, true);
    awsRequest.setService('testService');
    awsRequest.setTarget('testTarget');
    expect(awsRequest.getService() == 'testService', true);
    expect(awsRequest.getTarget() == 'testTarget', true);
  });
}
