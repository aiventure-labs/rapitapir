# ADR-0005: Authentication architecture (schemes + helpers + middleware)

Date: 2025-08-08
Status: Accepted

## Context

APIs require flexible authentication/authorization mechanisms. We support OAuth2/JWT, bearer/api-key/basic, and scope-based access control across different stacks.

## Decision

Adopt a layered auth architecture:

- Schemes: `RapiTapir::Auth::Schemes::*` (Bearer, JWT, OAuth2, Basic, ApiKey) encapsulate parsing/verification and `challenge` strings.
- Middleware: Authentication (build context), Authorization (scope checks), SecurityHeaders, CORS, RateLimiting.
- Helpers: In Sinatra integration, expose `authenticate_oauth2`, `authorize_oauth2!`, `authenticated?`, `has_scope?`, and `current_auth_context`.
- Provider-agnostic: Auth0 and generic OAuth2 supported via configuration; JWKS-based JWT verification.

## Consequences

- Pros: Clear separation, testable units, provider flexibility, easy to reason about.
- Cons: Multiple layers increase surface area.
- Mitigations: Defaults for common cases; comprehensive examples and specs.

## Alternatives considered

- Hard-wire to a specific provider: faster initially but vendor lock-in and reduced portability.

## Follow-ups

- Convert pending OAuth2/JWT tests to pass using deterministic JWKS fixtures.
- Document error semantics and standardize WWW-Authenticate challenges across schemes.
