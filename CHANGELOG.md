## [1.0.1] - 2024/05/20

* increased minimum `intl` version for 3.3 compatiblity

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