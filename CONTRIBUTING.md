# Contributing to RapiTapir 🦙

Thank you for your interest in contributing to RapiTapir! We're excited to work with the Ruby and Sinatra community to build the best API development experience possible.

## 🚀 Quick Start for Contributors

### Development Setup

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/ruby-tapir.git
   cd ruby-tapir
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Run the test suite**
   ```bash
   bundle exec rspec
   ```

4. **Try the examples**
   ```bash
   # Basic Sinatra example
   ruby examples/getting_started_extension.rb
   
   # Enterprise example with authentication
   ruby examples/enterprise_rapitapir_api.rb
   ```

## 🧪 Testing

We maintain high test coverage and all contributions should include appropriate tests.

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test files
bundle exec rspec spec/types_spec.rb

# Run with coverage report
bundle exec rspec --format documentation
```

### Test Structure

- `spec/types_spec.rb` - Type system tests
- `spec/dsl/` - DSL and endpoint definition tests  
- `spec/client/` - Client generation tests
- `spec/docs/` - Documentation generation tests
- `spec/observability/` - Health checks and monitoring tests
- `spec/integration/` - End-to-end integration tests

### Writing Tests

Follow our testing patterns:

```ruby
RSpec.describe RapiTapir::Types::String do
  describe '#validate' do
    it 'accepts valid strings' do
      type = described_class.new
      result = type.validate('hello')
      expect(result[:valid]).to be true
    end
    
    it 'rejects non-strings' do
      type = described_class.new
      result = type.validate(123)
      expect(result[:valid]).to be false
    end
  end
end
```

## 🏗️ Code Style and Standards

### Ruby Style

We follow Ruby best practices and conventions:

- **Use 2 spaces for indentation**
- **Keep line length under 120 characters**
- **Use descriptive variable and method names**
- **Include proper documentation for public APIs**
- **Follow Ruby naming conventions (snake_case for methods, PascalCase for classes)**

### Code Organization

- **Single Responsibility**: Each class should have one clear purpose
- **Dependency Injection**: Use dependency injection over global state
- **Immutability**: Prefer immutable objects where possible
- **Error Handling**: Use appropriate exceptions with clear messages

### Documentation

- **Document public APIs** with YARD-style comments
- **Include usage examples** in documentation
- **Keep README.md updated** with new features
- **Update CHANGELOG.md** for user-facing changes

## 🎯 Types of Contributions

### 🐛 Bug Reports

When reporting bugs, please include:

1. **Clear description** of the issue
2. **Steps to reproduce** the problem
3. **Expected vs actual behavior**
4. **Ruby version and gem versions**
5. **Minimal code example** if possible

Use our bug report template:

```markdown
## Bug Description
Brief description of what's wrong

## Steps to Reproduce
1. Create endpoint with...
2. Call endpoint with...
3. See error...

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- Ruby version: 3.2.0
- RapiTapir version: 1.0.0
- Framework: Sinatra 3.0.0
```

### ✨ Feature Requests

For new features, please:

1. **Check existing issues** to avoid duplicates
2. **Explain the use case** and problem you're solving
3. **Propose a solution** with examples if possible
4. **Consider backward compatibility**

### 🔧 Code Contributions

#### Pull Request Process

1. **Create a feature branch** from `main`
   ```bash
   git checkout -b feature/amazing-new-feature
   ```

2. **Make your changes** with tests
3. **Run the test suite** to ensure nothing breaks
4. **Update documentation** if needed
5. **Submit a pull request** with a clear description

#### PR Requirements

- ✅ **All tests pass**
- ✅ **New functionality includes tests**
- ✅ **Documentation is updated**
- ✅ **Code follows our style guidelines**
- ✅ **Commit messages are descriptive**

#### Commit Message Format

Use conventional commit format:

```
type(scope): description

[optional body]
```

Examples:
- `feat(types): add UUID type validation`
- `fix(sinatra): resolve route parameter extraction`
- `docs(readme): update installation instructions`
- `test(client): add TypeScript generation tests`

## 🗺️ Development Roadmap

### Current Priorities

1. **Core Stability** - Bug fixes and performance improvements
2. **Documentation** - Comprehensive guides and API docs
3. **Framework Integration** - Better Rails and Rack support
4. **Client Generation** - Python, Go, and JavaScript clients

### Future Phases

- **Phase 4**: Advanced client generation
- **Phase 5**: GraphQL integration  
- **Phase 6**: gRPC support
- **Community**: Plugin ecosystem

## 🏷️ Issue Labels

We use labels to organize issues and PRs:

- `bug` - Something is broken
- `enhancement` - New feature request
- `documentation` - Documentation improvements
- `good-first-issue` - Great for new contributors
- `help-wanted` - Community help needed
- `question` - General questions
- `wontfix` - Will not be implemented

## 🤝 Community Guidelines

### Code of Conduct

We are committed to providing a welcoming and inclusive environment. Please:

- **Be respectful** in all interactions
- **Assume good intentions** when asking questions or providing feedback
- **Help newcomers** learn and contribute
- **Give constructive feedback** on code and ideas
- **Focus on what's best for the community**

### Getting Help

- **🐛 Bug reports**: GitHub Issues
- **💡 Feature ideas**: GitHub Discussions
- **❓ Questions**: GitHub Discussions or Discord
- **📧 Private concerns**: riccardo.merolla@example.com

## 🎖️ Recognition

We believe in recognizing our contributors:

- **Contributors** are listed in our README
- **Significant contributions** are highlighted in release notes
- **Active community members** get maintainer privileges

## 📝 Development Notes

### Architecture Overview

RapiTapir is organized into several key modules:

- **`Types`** - Type system and validation
- **`DSL`** - Endpoint definition language
- **`Server`** - Framework adapters (Sinatra, Rails, Rack)
- **`Client`** - Code generation for various languages
- **`Docs`** - Documentation generation
- **`Auth`** - Authentication and authorization
- **`Observability`** - Monitoring and health checks

### Key Design Principles

1. **Developer Experience First** - APIs should be joy to use
2. **Type Safety** - Catch errors at definition time, not runtime
3. **Framework Agnostic** - Work with any Ruby web framework
4. **Convention over Configuration** - Sensible defaults, customizable when needed
5. **Documentation Driven** - Code and docs should never be out of sync

### Performance Considerations

- **Minimal runtime overhead** - Type checking and validation are optimized
- **Lazy evaluation** - OpenAPI specs and docs are generated on-demand
- **Memory efficient** - Reuse objects and avoid unnecessary allocations
- **Thread safe** - All core components work in multi-threaded environments

## 🎉 Thank You!

Every contribution, no matter how small, makes RapiTapir better for the entire Ruby community. We appreciate your time and effort in helping us build the future of API development in Ruby!

---

**Happy coding!** 🦙✨
