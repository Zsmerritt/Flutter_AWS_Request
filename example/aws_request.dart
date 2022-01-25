import 'package:aws_request/aws_request.dart';
import 'package:http/http.dart';

Future<void> awsRequestFunction(String logString) async {
  final AwsRequest request =
      AwsRequest('awsAccessKey', 'awsSecretKey', 'region');
  final Response result = await request.send(
    type: AwsRequestType.post,
    jsonBody: "{'jsonKey': 'jsonValue'}",
    service: 'logs',
    queryString: {'X-Amz-Expires': '10'},
    headers: {'X-Amz-Security-Token': 'XXXXXXXXXXXX'},
  );
  print(result.statusCode);
}
