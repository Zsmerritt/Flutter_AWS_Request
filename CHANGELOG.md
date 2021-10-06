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