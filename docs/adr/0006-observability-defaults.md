# ADR-0006: Observability defaults (health, logging, metrics/tracing hooks)

Date: 2025-08-08
Status: Accepted

## Context

Production services benefit from consistent, low-friction observability. The library ships helpers and middleware for health, logging, metrics, and tracing, while keeping exporters optional.

## Decision

- Development defaults enable: health endpoint, CORS, docs, basic metrics/logging.
- Production defaults focus on security headers and safe defaults; observability can be enabled via explicit configuration blocks.
- Provide hooks for Prometheus metrics and OpenTelemetry tracing; do not hard-depend on vendors.
- Health check registry supports built-in and custom checks.

## Consequences

- Pros: Fast local experience, predictable prod posture, portable observability across vendors.
- Cons: Users may expect batteries-included exporters.
- Mitigations: Snippets and guides for wiring popular backends; small glue modules where useful.

## Alternatives considered

- Ship tight integrations by default: increases maintenance and pulls heavy deps into core.

## Follow-ups

- Add labeled metrics examples and OTLP wiring snippets.
- Provide a minimal benchmark/perf budget harness to monitor overhead.
