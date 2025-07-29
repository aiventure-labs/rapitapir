# GitHub Copilot Instructions for RapiTapir

## 📌 Overview

This repository is a **Ruby library** named `rapitapir`. It is inspired by Scala’s Tapir and designed to define HTTP APIs declaratively, with type-safe input/output definitions, automatic OpenAPI documentation, and seamless integration with multiple Ruby stacks.

## ✅ Project Conventions

Please follow these conventions when generating or suggesting code in this repository:

### Code Style

- Use **Ruby 3.2+** syntax.
- Prefer `def`/`end` blocks over one-liners unless the method is trivial.
- Follow the **Ruby Style Guide**: https://rubystyle.guide/
- Use **snake_case** for method and variable names, **CamelCase** for class and module names.
- Always use 2-space indentation.
- Prefer `require_relative` for internal files and `require` for gems.
- Favor immutable data and functional style when possible.
- Use `attr_reader` for simple attribute accessors.
- Use `freeze` on data structures to prevent accidental mutation.
- Use `# frozen_string_literal: true` at the top of files to enforce immutability.
- Write comprehensive comments and documentation for public APIs.
- Use SOLID principles for class design.
- Write reusable, composable code that can be easily extended.
- Write code that is easy to read and understand, avoiding unnecessary complexity.
- Write code that is idiomatic Ruby, leveraging built-in methods and libraries where appropriate.
- Write tests before implementing new features or fixing bugs, then implement the code to pass those tests
- Write tests and ensure high coverage (aim for >90%).
- Write tests for all new features and bug fixes.
- Use RSpec for tests, following the conventions in `spec/`.
- Run tests with `bundle exec rspec` and ensure they pass before submitting changes.

### File Layout

- All source files are under `lib/rapitapir/`
- Tests go under `spec/`
- Documentation and planning lives in `docs/`
- Entry point is `lib/rapitapir.rb`

### DSL & Typing

- The goal is a readable, composable **DSL for defining HTTP endpoints**.
- Inputs and outputs should be defined via chained methods like `.in(...)`, `.out(...)`, `.error_out(...)`
- Suggest flexible, declarative APIs instead of procedural configurations.

Example:

```ruby
RapiTapir.get("/hello")
  .in(query(:name, :string))
  .out(json_body(message: :string))
```