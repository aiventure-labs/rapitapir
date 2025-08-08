# ADR-0001: Base class strategy (SinatraRapiTapir) vs manual extension

Date: 2025-08-08
Status: Accepted

## Context

Historically, users registered the Sinatra extension manually and wired routes/DSL themselves. This added boilerplate and repeated setup across services, making the first-run experience slower and error-prone.

## Decision

Adopt a first-class base class, `SinatraRapiTapir`, as the primary way to build APIs:

- Auto-registers the RapiTapir Sinatra extension.
- Exposes the enhanced HTTP verb DSL (GET/POST/...).
- Provides `development_defaults!` and `production_defaults!` helpers for sensible defaults (CORS/docs/health in dev; security headers/rate limit in prod).
- Keeps manual registration supported for power users and non-Sinatra stacks.

## Consequences

- Pros: Minimal boilerplate, consistent defaults, faster time-to-first-endpoint, clearer docs.
- Cons: Slightly more “magic”; divergence from vanilla Sinatra learning resources.
- Mitigations: Thorough docs, explicit opt-outs, manual extension path remains supported.

## Alternatives considered

- Only manual extension: simpler mental model but worse DX and more boilerplate.
- Separate installer generator: adds tooling complexity without runtime benefit.

## Follow-ups

- Ensure README and examples prefer `SinatraRapiTapir` while linking manual alternative.
- Add integration tests for both base class and manual setup to avoid regressions.
