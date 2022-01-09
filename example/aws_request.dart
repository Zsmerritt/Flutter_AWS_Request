import 'package:aws_request/aws_request.dart';
import 'package:http/http.dart';

void awsRequestFunction(String logString) async {
  AwsRequest request = new AwsRequest('awsAccessKey', 'awsSecretKey', 'region');
  Response result = await request.send(
    AwsRequestType.POST,
    jsonBody: "{'jsonKey': 'jsonValue'}",
    target: 'Logs_20140328.PutLogEvents',
    service: 'logs',
    queryString: {'X-Amz-Expires': '10'},
    headers: {'X-Amz-Security-Token': 'XXXXXXXXXXXX'},
  );
}
