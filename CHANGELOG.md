# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
### Changed
### Removed
### Fixed

## [1.1.0] - 2020-08-07
### Changed
* allow multiple consumers to handle the same message
* consumed messages table requires its own primary key due to ActiveRecord not having support for composite primary keys

## [1.0.1] - 2020-07-23
### Fixed
* Fix publisher connection by using default connection if one isn't provided

## [1.0.0] - 2020-07-20
### Added
* CircleCI build that runs the specs
* Rubocop (also ran by CircleCI)
* New error types for incoming messages
* RailwayIpc::Messages::Unknown protobuf

### Changed
* Refactored worker to use ProcessIncomingMessage and IncomingMessage abstractions
* Moved decoding logic from ConsumedMessage to IncomingMessage
* Removed STATUSES constant from ConsumedMessage
* Publisher is no longer a Singleton; kept a Singleton version of the Publisher for backwards compatibility that gives a "deprecated" warning

### Removed
* Removed `BaseMessage` protobuf
* NullMessage and NullHandler were removed

### Fixed
* Fixed all Rubocop warnings and errors

## [0.1.7] - 2020-06-29
### Added
- Correlation ID and message UUID are auto generated for messages for IDs are not passed in [#23](https://github.com/learn-co/railway_ipc_gem/pull/23)

[Unreleased]: https://github.com/learn-co/railway_ipc_gem/compare/v1.0.0...HEAD
[1.1.0]: https://github.com/learn-co/railway_ipc_gem/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/learn-co/railway_ipc_gem/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/learn-co/railway_ipc_gem/compare/v0.1.7...v1.0.0
[0.1.7]: https://github.com/learn-co/railway_ipc_gem/releases/tag/v0.1.7
