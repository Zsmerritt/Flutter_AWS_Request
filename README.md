# aws_request

A package that generates, signs, sends requests to AWS.  
**This package is still under development**

The repository can be found [here](https://github.com/Zsmerritt/Flutter_AWS_Request)

Supported HTTP methods are get, post, delete, patch, put.

If you have feedback or have a use case that isn't covered feel free to contact me.

## Getting Started

To get start add `aws_request: ^[CURRENT_VERION],` to your `pubspec.yaml`

Then create a request: 
~~~
AwsRequest request = new AwsRequest('awsAccessKey', 'awsSecretKey', 'region');
~~~
Finally send your request by calling `request.send('TYPE');`

The following parameters can be provided to the `send()` function:
~~~
type: request type [GET, POST, PUT, etc]
service: aws service you are sending request to
target: your instance of that service plus the operation [Logs_XXXXXXXX.PutLogEvents]
signedHeaders: a list of headers aws requires in the signature.
   Default included signed headers are: [content-type, host, x-amz-date, x-amz-target]
   (You do not need to provide these in headers)
headers: any required headers. Any non-default headers included in the signedHeaders must be added here.
jsonBody: the body of the request, formatted as json
queryPath: the aws query path
queryString: the aws query string, formatted like ['abc=123&def=456']. Must be url encoded
~~~
## Examples

Here's an example of using aws_request to send a CloudWatch PutLogEvent request:

~~~dart
import 'package:aws_request/aws_request.dart';
import 'dart:io';

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
~~~
