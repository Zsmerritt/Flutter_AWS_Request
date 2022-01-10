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

## Getting Started

Create a request and send it!

~~~dart
import 'package:aws_request/aws_request.dart';

AwsRequest request = new AwsRequest('awsAccessKey', 'awsSecretKey', 'region');
request.send(AwsRequestType.POST);
~~~

The following parameters can be provided to the `send()` function:

~~~
type: request type (GET, POST, PUT, etc)
service: aws service you are sending request to
target: your instance of that service plus the operation (Logs_XXXXXXXX.PutLogEvents)
signedHeaders: a list of headers aws requires in the signature.
   Default included signed headers are: (content-type, host, x-amz-date, x-amz-target)
   (You do not need to provide these in [headers])
headers: any required headers. Any non-default headers included in the signedHeaders 
         must be added here.
jsonBody: the body of the request, formatted as json
queryPath: the aws query path
queryString: the url query string as a Map
~~~

Supported HTTP methods are GET, POST, DELETE, PATCH, PUT, HEAD.

## Important Notes:

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
~~~

### Example 2

There is also a static method if you find that more useful:

~~~dart
import 'package:aws_request/aws_request.dart';
import 'package:http/http.dart';

void awsRequestFunction(String logString) async {
  
  Response result = await AwsRequest.staticSend(
    awsAccessKey: 'awsAccessKey',
    awsSecretKey: 'awsSecretKey',
    region: 'region',
    type: AwsRequestType.POST,
    jsonBody: "{'jsonKey': 'jsonValue'}",
    target: 'Logs_20140328.PutLogEvents',
    service: 'logs',
    queryString: {'X-Amz-Expires': '10'},
    headers: {'X-Amz-Security-Token': 'XXXXXXXXXXXX'},
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