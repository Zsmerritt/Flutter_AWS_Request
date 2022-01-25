import 'package:aws_request/aws_request.dart';
import 'package:http/http.dart';

Future<void> awsRequestFunction(String logString) async {
  final AwsRequest request =
      AwsRequest('awsAccessKey', 'awsSecretKey', 'region');
  final Response result = await request.send(
    AwsRequestType.post,
    jsonBody: "{'jsonKey': 'jsonValue'}",
    target: 'Logs_20140328.PutLogEvents',
    service: 'logs',
    queryString: {'X-Amz-Expires': '10'},
    headers: {'X-Amz-Security-Token': 'XXXXXXXXXXXX'},
  );
  print(result.statusCode);
}
