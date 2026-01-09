# Changelog

All notable changes to this project will be documented in this file.

## [1.2.0] - 2026-01-09
### Added
- **Auto-Cleaner**: Now at the end of the tests the tester delets all temp files it created except the log

### Fixed
- Fixed forbidden functions check, now excludes user's custom functions

## [1.1.0] - 2025-12-24
### Added
- **Auto-Updater**: The script now checks for updates automatically on startup.
- **Strict Function Check**: Now compiles source files temporarily to ensure only `read`, `malloc`, and `free` are used.
- **Output Cleanup**: Improved log readability by stripping color codes from the log file.

### Fixed
- Fixed potential false positives in the forbidden function checker for macOS/Linux compatibility.

## [1.0.0] - 2025-12-21
### Added
- Initial release of the Get Next Line Tester.
- Multi-buffer size testing (1, 42, 1000, 1M).
- Multiple file descriptor handling tests.
- Stdin (pipe) reading tests.
- Valgrind leak detection integration.