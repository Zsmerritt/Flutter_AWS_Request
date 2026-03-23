## [2.1.0] - 2026/03/22

### Changes:

* **SigV4 correctness:** Canonical query string matches the wire request — parameters sorted by name then value, encoding aligned with how the request `Uri` is built (avoids signing/query mismatches from ad hoc encoding)
* **SigV4 correctness:** Region and service names are lowercased in credential scope *and* in signing-key derivation (fixes invalid signatures when callers pass mixed-case region or service)
* **New request options** on `AwsRequest.send` / `staticSend` and `MockAwsRequest`: `queryStringPairs` for duplicate query parameter names (not expressible with `Map`); `hashedPayloadIsUnsigned` for S3-style `UNSIGNED-PAYLOAD`; `useNonS3DoubleEncodedCanonicalPath` for non-S3 path double-encoding rules
* `signedHeaders` entries are resolved case-insensitively against merged request headers
* Signing uses the same normalized canonical path as the outbound `Uri` (`url.path`)
* `AwsRequestException.toString()` includes `stackTrace`
* `AwsHttpRequest.send` rejects empty `awsAccessKey` / `awsSecretKey`
* Clearer error when `mockRequest` is true but `mockFunction` is null
* README: STS / temporary credentials (`X-Amz-Security-Token` and signing it); retries and HTTP client lifecycle; duplicate query keys with `Map`; corrected JSON body examples
* API docs updated for mutable credential fields, default signed headers, and the new options
* Stricter `analysis_options.yaml` (extends `package:lints/recommended.yaml`)
* Test suite expanded (SigV4 vector/conformance coverage; optional live AWS tests behind environment configuration)

## [2.0.0] - 2026/03/21

### Breaking Changes:

* `MockAwsRequest` constructor now uses named parameters to match `AwsRequest` API
* `AwsRequestException` fields (`message`, `stackTrace`) are now `final`

### Changes:

* Removed `intl` dependency — date formatting is now handled internally
* Fixed HTTP client resource leak in `getRequest` (client now always closed via `try/finally`)
* Fixed SigV4 timestamp race condition — `getAuth` now derives dateStamp from amzDate instead of a separate `DateTime.now()` call
* Added optional `endpoint` parameter for custom/non-standard AWS hostnames (S3 virtual-hosted-style, VPC endpoints, LocalStack, etc.)
* `sign()` return type changed from `dynamic` to `Digest`
* `validateRequest` now throws directly instead of returning a validation map
* Removed unused parameters (`host`, `requestBody`, `timeout`) from `getHeaders`
* `getSignedHeaders` no longer throws when default keys (e.g. `host`) are passed in `signedHeaders`
* Replaced `type.toString().toUpperCase().split('.').last` with `type.name.toUpperCase()`
* All tests now use mock HTTP clients instead of external network calls
* Updated CI pipeline actions (`checkout@v4`, `codecov-action@v5`)
* Updated README with SDK requirements, `MockAwsRequest` documentation, custom endpoints, and corrected examples
* Updated example project to current SDK and package versions

## [1.1.0] - 2025/06/21

* Increased minimum `intl` version for 3.32 compatibility
* Removed outdated lint rule

## [1.0.1] - 2024/05/20

* Increased minimum `intl` version for 3.3 compatibility

## [1.0.0] - 2023/05/31

* Requires Dart 3.0 or later
* Updated to http ^1.0.0

## [0.5.0] - 2023/05/31

* Updated `intl` to new version
* Fixed test broken by update

## [0.4.0+2] - 2023/02/09

* Minor housekeeping to fix running tests & lint deprecations
* Fixed typo in description
* Updated example
* Fixed test case for modern dart

## [0.4.0+1] - 2022/01/25

* Added comments for better auto documentation

## [0.4.0] - 2022/01/24

### Breaking Changes:

* AwsRequestTypes have been lower cased to conform with dart conventions

### Changes:

* Added stricter analysis options
* Refactored AwsRequest and MockAwsRequest
* Removed argument `target` because it should just be a header

## [0.3.0+1] - 2022/01/09

* Added more unit tests
* Added note about Android permissions to readme
* Incremented mid version for github
* Added optional timeout argument to `AwsRequest.send` that overrides constructor timeout

## [0.3.0] - 2022/01/08

* Migrated from `universal_io` to `http`
* Refactored project into discrete testable modules
* Added unit tests for each piece
* Added MockAwsRequest to mock requests for easier testing
* Added AUTHORS file
* Added static version of primary method
* Updated documentation to illustrate new static call method
* Added coverage
* Fixed bug with allowing non String values in queryString

## [0.2.1] - 2022/01/08

* Fixed issue with rejected headers on web

## [0.2.0+1] - 2021/09/17

* Updated package description

## [0.2.0] - 2021/09/16

* Removed unneeded flutter dependency to allow native and js compatibility
* Refactored some code for better readability
* Added AwsRequestType enum to replace String request type
* Removed deprecated `cause` from AwsRequestException 
* Updated license to MIT

## [0.1.9] - 2021/09/12

* Added stack trace to AwsRequestException
* Added optional timeout parameter with a default value of `Duration(seconds: 10)`

## [0.1.8] - 2021/08/25

* Fixed issue causing HttpException

## [0.1.7] - 2021/07/30

* Fixed bug limiting calls to POST requests
* Fixed bug limiting requests to `logs` service
* Fixed bug with static signed headers
* Reformatted files
* Added QoL service and target values to constructor

## [0.1.6] - 2021/07/01

* Removed strict flutter sdk version requirement

## [0.1.5] - 2021/06/08

* Fixed null safety typing issue
* Reformatted aws_request.dart

## [0.1.4] - 2021/05/18

* Removed old hard coded region values and replaced with dynamic region

## [0.1.3] - 2021/03/25

* Fixed issue with sending non unicode characters in request body

## [0.1.2] - 2021/03/24

* Fixed `flutter analyze` issues related to null safety

## [0.1.1] - 2021/03/24

* Actually migrated to null safety instead of just upgrading packages

## [0.1.0] - 2021/03/23

* Added support for null safety
* Updated dependencies for null safety compatibility

## [0.0.3] - 2021/02/10

* Reverted issue with null safety. This will be fixed later
* Added files to example to help it execute

## [0.0.2] - 2021/02/10

* Fixed readme.md and added example

## [0.0.1] - 2021/02/10

* Added initial files for sending signed aws requests