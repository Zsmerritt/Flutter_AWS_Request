import 'dart:io';

import 'package:aws_request/aws_request.dart';

void sendCloudWatchLog(String logString) async {
  AwsRequest request = new AwsRequest('awsAccessKey', 'awsSecretKey', 'region');
  String body = """  
            {"logEvents":
              [{
                "timestamp":${DateTime.now().toUtc().millisecondsSinceEpoch},
                "message":"$logString"
              }],
              "logGroupName":"ExampleLogGroupName",
              "logStreamName":"ExampleLogStreamName"
            }""";
  HttpClientResponse result = await request.send(
    'POST',
    jsonBody: body,
    target: 'Logs_XXXXXXXX.PutLogEvents',
    service: 'logs',
  );
}
