<h1 align="center">
  aws_request
</h1>

<p align="center">
    <a href="https://pub.dev/packages/aws_request">
        <img alt="Pub Package" src="https://img.shields.io/pub/v/aws_request.svg?logo=dart&logoColor=00b9fc">
    </a>
    <a href="https://github.com/Zsmerritt/Flutter_AWS_Request/issues">
        <img alt="Open Issues" src="https://img.shields.io/github/issues/Zsmerritt/Flutter_AWS_Request?logo=github&logoColor=white">
    </a>
    <a href="https://github.com/Zsmerritt/Flutter_AWS_Request">
        <img alt="Code size" src="https://img.shields.io/github/languages/code-size/Zsmerritt/Flutter_AWS_Request?logo=github&logoColor=white">
    </a>
    <a href="https://github.com/Zsmerritt/Flutter_AWS_Request/blob/main/LICENSE">
        <img alt="License" src="https://img.shields.io/github/license/Zsmerritt/Flutter_AWS_Request?logo=open-source-initiative&logoColor=blue">
    </a>
    <a href="https://github.com/Zsmerritt/Flutter_AWS_Request/actions/workflows/dart.yml">
        <img alt="CI pipeline status" src="https://github.com/Zsmerritt/Flutter_AWS_Request/actions/workflows/dart.yml/badge.svg">
    </a>
    <a href="https://codecov.io/gh/Zsmerritt/Flutter_AWS_Request">
        <img alt="Coverage" src="https://codecov.io/gh/Zsmerritt/Flutter_AWS_Request/branch/main/graph/badge.svg?token=RY2QXJVTTW"/>
    </a>
</p>

<p align="center">
    Easily create, sign, and send API requests to AWS.
</p>

---

<h3 align="center">
  Resources
</h3>

<p align="center">
    <a href="https://pub.dev/documentation/aws_request/latest/aws_request/aws_request-library.html">
        Documentation
    </a>
    &nbsp;
    &nbsp;
    &nbsp;
    <a href="https://pub.dev/packages/aws_request">
        Pub Package
    </a>
    &nbsp;
    &nbsp;
    &nbsp;
    <a href="https://github.com/Zsmerritt/Flutter_AWS_Request">
        GitHub Repository
    </a>
</p>

<p align="center">
    If you have feedback or have a use case that isn't covered feel free to open an issue.
</p>

## Requirements

- Dart SDK `>=3.0.0 <4.0.0`

## Getting Started

Create a request and send it!

~~~dart
import 'package:aws_request/aws_request.dart';

void main() {
  final AwsRequest request = AwsRequest(
    awsAccessKey: 'awsAccessKey',
    awsSecretKey: 'awsSecretKey',
    region: 'region',
  );
  request.send(type: AwsRequestType.post, service: 'logs');
}
~~~

The following parameters can be provided to the `send()` function:

~~~
type: request type (GET, POST, PUT, etc)
service: aws service you are sending request to
signedHeaders: a list of headers aws requires in the signature.
   Default included signed headers are: (content-type, host, x-amz-date)
   (You do not need to provide these in [headers])
headers: any required headers. Any non-default headers included in the signedHeaders 
         must be added here.
jsonBody: the body of the request, formatted as json
queryPath: the aws query path
queryString: the url query string as a Map
timeout: overrides the constructor request timeout (default: 10 seconds)
endpoint: custom hostname override (defaults to {service}.{region}.amazonaws.com)
~~~

Supported HTTP methods are GET, POST, DELETE, PATCH, PUT, HEAD.

## Important Notes:

### Default Headers

The default `Content-Type` is `application/x-amz-json-1.1`, which works for most AWS
JSON-protocol services (CloudWatch Logs, Lambda, etc.). Some services require a different
value — for example, DynamoDB uses `application/x-amz-json-1.0`, and S3/SQS/SNS use XML
content types. Override via the `headers` parameter when needed.

### Custom Endpoints

By default, requests are sent to `{service}.{region}.amazonaws.com`. If you need a
non-standard endpoint (S3 virtual-hosted-style buckets, VPC endpoints, LocalStack, etc.),
pass the `endpoint` parameter:

~~~dart
final AwsRequest request = AwsRequest(
  awsAccessKey: 'awsAccessKey',
  awsSecretKey: 'awsSecretKey',
  region: 'us-east-1',
  endpoint: 'mybucket.s3.us-east-1.amazonaws.com',
);
~~~

The `endpoint` can also be passed per-request via `send()` or `staticSend()`, and will
override the constructor value.

### Android

If running on android, make sure you have

`<uses-permission android:name="android.permission.INTERNET" />`

in your app's `android/app/src/main/AndroidManifest.xml`

## Examples

### Example 1

Here's an example of using aws_request to send a CloudWatch PutLogEvent request:

~~~dart
import 'package:aws_request/aws_request.dart';
import 'package:http/http.dart';

Future<void> awsRequestFunction(String logString) async {
  final AwsRequest request = AwsRequest(
    awsAccessKey: 'awsAccessKey',
    awsSecretKey: 'awsSecretKey',
    region: 'region',
  );
  final Response result = await request.send(
    type: AwsRequestType.post,
    jsonBody: "{'jsonKey': 'jsonValue'}",
    service: 'logs',
    queryString: {'X-Amz-Expires': '10'},
    headers: {'X-Amz-Security-Token': 'XXXXXXXXXXXX'},
  );
  print(result.statusCode);
}
~~~

### Example 2

There is also a static method if you find that more useful:

~~~dart
import 'package:aws_request/aws_request.dart';
import 'package:http/http.dart';

Future<void> awsRequestFunction(String logString) async {
  final Response result = await AwsRequest.staticSend(
    awsAccessKey: 'awsAccessKey',
    awsSecretKey: 'awsSecretKey',
    region: 'region',
    type: AwsRequestType.post,
    jsonBody: "{'jsonKey': 'jsonValue'}",
    service: 'logs',
    queryString: {'X-Amz-Expires': '10'},
    headers: {'X-Amz-Security-Token': 'XXXXXXXXXXXX'},
  );
  print(result.statusCode);
}
~~~

## Testing

A `MockAwsRequest` class is provided for testing via the `testing` library.
It mirrors the `AwsRequest` API but uses a mock HTTP client instead of making
real network calls:

~~~dart
import 'package:aws_request/testing.dart';
import 'package:http/http.dart';

void main() {
  final MockAwsRequest mockRequest = MockAwsRequest(
    awsAccessKey: 'awsAccessKey',
    awsSecretKey: 'awsSecretKey',
    region: 'region',
    mockFunction: (Request request) async {
      return Response('{"status": "ok"}', 200);
    },
  );

  mockRequest.send(
    type: AwsRequestType.post,
    service: 'logs',
    jsonBody: '{"key": "value"}',
  );
}
~~~

## MIT License

```
Copyright (c) Zachary Merritt

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
