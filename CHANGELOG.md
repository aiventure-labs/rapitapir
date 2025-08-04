# Changelog

All- 📏 **Type Shortcuts**: Global `T` constant for cleaner type syntax (automatically available - no setup needed)notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - 2025-08-02

### Summary
This release introduces the **SinatraRapiTapir** base class, providing the cleanest possible syntax for creating RapiTapir APIs. The new inheritance-based approach eliminates boilerplate while maintaining 100% backward compatibility.

### Added - SinatraRapiTapir Base Class & Enhanced Developer Experience
- 🎯 **SinatraRapiTapir Base Class**: Clean inheritance syntax `class MyAPI < SinatraRapiTapir`
- ✨ **Enhanced HTTP Verb DSL**: Built-in GET, POST, PUT, DELETE methods with fluent chaining
- 🔧 **Automatic Extension Registration**: Zero-boilerplate setup with automatic feature inclusion
- � **Type Shortcuts**: Global `T` constant for cleaner type syntax (`T.string` vs `RapiTapir::Types.string`)
- �📖 **Comprehensive Documentation**: Added detailed guides for base class usage and setup
- 🚀 **GitHub Pages Deployment**: Modern workflow with build/deploy separation for documentation
- 🧪 **Enhanced Test Suite**: Complete test coverage for SinatraRapiTapir functionality
- 📋 **Setup Guides**: Step-by-step documentation for GitHub Pages and repository configuration

### Enhanced
- 🔄 **Examples Updated**: Hello World and Getting Started examples now use clean base class syntax
- 📚 **Documentation Structure**: Improved organization with separate guides for each feature
- 🛠️ **Developer Experience**: Cleaner API with fewer required imports and automatic setup
- � **Type Syntax**: Introduced global `T` shortcut for much cleaner type definitions
- �🔧 **GitHub Actions**: Fixed workflow permissions and modernized deployment pattern

### Fixed
- 📄 **GitHub Pages Deployment**: Resolved 404 errors with proper workflow configuration
- 🔒 **Workflow Permissions**: Added required `pages: write` and `id-token: write` permissions
- ⚙️ **YAML Syntax**: Simplified HTML generation to prevent parsing conflicts
- 🏗️ **Build Pipeline**: Separated build and deploy jobs for better error handling

### Technical Improvements
- **Backward Compatibility**: 100% compatible with existing manual extension registration
- **Top-level Constant**: `SinatraRapiTapir` available at both module and top level
- **Automatic Features**: Health checks, CORS, documentation, and middleware auto-enabled
- **Development Messages**: Helpful startup messages indicating active features

### Documentation
- `docs/sinatra_rapitapir.md` - Complete base class usage guide
- `docs/github_pages_setup.md` - Repository configuration instructions  
- `docs/github_pages_fix.md` - Workflow troubleshooting guide
- Updated examples demonstrating clean syntax patterns

### Breaking Changes
- None - all changes are additive and backward compatible

### Migration Guide
- **New Projects**: Use `class MyAPI < SinatraRapiTapir` for cleanest syntax
- **Existing Projects**: Continue using manual extension registration (no changes required)
- **Enhanced DSL**: Access GET, POST, etc. methods directly without additional setup

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
- **Ruby Compatibility**: Supports Ruby 3.1+
- **Framework Support**: Sinatra 2.0+, with Rack 2.0+ compatibility
- **Test Coverage**: 470 tests passing (100% success rate) with 70.13% coverage
- **Documentation**: Complete API docs, tutorials, and contribution guidelines  
- **Code Quality**: Professional codebase following Ruby best practices
- **Developer Experience**: Clean inheritance syntax with automatic feature setup

[Unreleased]: https://github.com/riccardomerolla/rapitapir/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/riccardomerolla/rapitapir/releases/tag/v0.1.0
