# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Preparing for initial release

## [0.1.0] - 2024-08-01

### Added
- 🎉 Initial release of RapiTapir
- 🏗️ Core DSL for defining HTTP endpoints
- 🔧 Type system with validation and coercion
- 📚 Automatic OpenAPI documentation generation
- 🚀 Sinatra integration with ResourceBuilder
- 🔒 Authentication and authorization framework
- 📊 Health check and observability features
- 🧪 Comprehensive test suite (100% passing)
- 📖 Complete documentation and examples
- 🤝 Community-ready repository structure

### Features
- **Declarative API Design**: Define endpoints with `.in()`, `.out()`, `.error_out()` chaining
- **Type Safety**: Strong typing with automatic validation and helpful error messages
- **Framework Integration**: Seamless Sinatra support with plans for Rails and Rack
- **Documentation Generation**: Auto-generated OpenAPI 3.0 specs and interactive SwaggerUI
- **Client Generation**: TypeScript client generation with more languages planned
- **Enterprise Ready**: Built-in authentication, rate limiting, and security headers
- **Developer Experience**: Intuitive DSL, comprehensive examples, and excellent error messages

### Examples
- Basic getting started example with books API
- Enterprise example with authentication and advanced features
- CRUD operations with elegant block syntax
- Health checks and monitoring integration

### Technical Details
- **Ruby Compatibility**: Supports Ruby 3.0+
- **Framework Support**: Sinatra 2.0+, with Rack 2.0+ compatibility
- **Test Coverage**: 100% passing test suite with comprehensive validation
- **Documentation**: Complete API docs, tutorials, and contribution guidelines
- **Code Quality**: Professional codebase following Ruby best practices

[Unreleased]: https://github.com/riccardomerolla/ruby-tapir/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/riccardomerolla/ruby-tapir/releases/tag/v0.1.0
