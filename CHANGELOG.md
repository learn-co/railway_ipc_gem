# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
* JSON decoder that can handle JSON encoded Protobufs.

### Changed
* (Breaking Change) Rename `Consumer#work` to `Consumer#work_with_params`. This
  was necessary so that we can support specifying different message encodings via metadata in the future. If the message encoding cannot be determined from the message matadata fall back to a default decoder (binary protobufs).

### Removed
### Fixed

## [3.0.0] - 2020-12-07
### Changed
* Consumers _will no longer crash_ when an exception is raised. Instead, consumers will move the message that caused the exception to a single dead-letter exchange called 'ipc:errors'. Railway will configure the dead-letter exchange automatically.

## [2.2.2] - 2020-11-20
### Fixed
* Fixed Publisher class channel leak. Channels were being created on each instantiation of a Publisher instead of being re-used.

## [2.2.1] - 2020-10-20
### Added
* Logging to indicate when options passed via `listen_to`/`from_queue` are overriding the defaults.

## [2.2.0] - 2020-10-20
### Added
* The ability to configure workers to handle different workloads via `rake railway_ipc::consumers:spawn`

## [2.1.0] - 2020-10-19
### Added
* :options parameter to `listen_to` which passes keys along to Sneaker's `from_queue` method.

## [2.0.3] - 2020-09-02
### Fixed
* Fix RPC server. RPC servers need to conform to the Sneaker worker API (i.e. their initializers need to be able to accept queue name / pool and they require a `stop` method.

## [2.0.2] - 2020-08-27
### Changed
* RPC `RailwayIpc::Client` does not need to log the queue name.

## [2.0.1] - 2020-08-24
### Fixed
* `RailwayIpc::Logger` now handles block syntax (i.e. `logger.info { 'my message' }`) correctly.

## [2.0.0] - 2020-08-20
### Added
* Several additions to internal logging:
  - Log messages now include a `feature` key. This can be used by logging aggregator tools to group log messages across different systems that use the gem. If one isn't provided a default value of `railway_ipc` is used.
  - Protobufs are logged as a sub-hash which contains both the protobuf type and payload.
  - Exchange and queue names are logged where applicable.
  - The internal Bunny connection now uses the `RailwayIpc::Logger` instead of a generic `Logger`.

### Changed
* *Breaking Change* `RailwayIpc.configure` now takes `device`, `level`, and `formatter` instead of a complete `Logger` instance. The instance is now managed internally by Railway. This is a breaking change to the `RailwayIpc.configure` API, clients will need to be updated to use the new syntax.

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

[Unreleased]: https://github.com/learn-co/railway_ipc_gem/compare/v30.0.0...HEAD
[3.0.0]: https://github.com/learn-co/railway_ipc_gem/compare/v2.2.2...v3.0.0
[2.2.2]: https://github.com/learn-co/railway_ipc_gem/compare/v2.2.1...v2.2.2
[2.2.1]: https://github.com/learn-co/railway_ipc_gem/compare/v2.2.0...v2.2.1
[2.2.0]: https://github.com/learn-co/railway_ipc_gem/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/learn-co/railway_ipc_gem/compare/v2.0.3...v2.1.0
[2.0.3]: https://github.com/learn-co/railway_ipc_gem/compare/v2.0.2...v2.0.3
[2.0.2]: https://github.com/learn-co/railway_ipc_gem/compare/v2.0.1...v2.0.2
[2.0.1]: https://github.com/learn-co/railway_ipc_gem/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/learn-co/railway_ipc_gem/compare/v1.1.0...v2.0.0
[1.1.0]: https://github.com/learn-co/railway_ipc_gem/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/learn-co/railway_ipc_gem/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/learn-co/railway_ipc_gem/compare/v0.1.7...v1.0.0
[0.1.7]: https://github.com/learn-co/railway_ipc_gem/releases/tag/v0.1.7
