# Changelog

## [0.2.0] - 2025-10-16

### Changed

- Expand files included in the gem by explicitly excluding development and test artifacts (e.g. `test/`, `pkg/`, `dev/`, `log/`, `.github/`) from `spec.files` in the gemspec.
- Add common repository files (`Gemfile`, `Rakefile`, `.gitignore`, `.gitattributes`) to the exclusion list to avoid shipping tooling files.

### Fixed

- Update packaging behavior so built gem no longer contains test/dummy or dev-only files.

## [0.1.0] - 2024-01-01

### Added

- Initial release
- Automatic suppression of "Undeclared attribute type for enum" errors
- Rails railtie for seamless integration
- Configuration option to enable/disable the gem
