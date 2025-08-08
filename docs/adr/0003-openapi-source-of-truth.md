# ADR-0003: OpenAPI source-of-truth and documentation flow

Date: 2025-08-08
Status: Accepted

## Context

We generate OpenAPI from endpoint definitions. Competing approaches: maintain OpenAPI by hand and generate code from it, or treat the DSL as the single source of truth (SSOT).

## Decision

Use the RapiTapir DSL as the SSOT. All documentation artifacts are derived from code:

- Generate OpenAPI 3.0.3 (JSON/YAML) from endpoints.
- Generate interactive HTML docs and Markdown from the same model.
- Serve docs via CLI/dev server or mount in-app.
- Avoid editing generated OpenAPI by hand; support customization via DSL metadata and documented extension points.

## Consequences

- Pros: Docs stay in sync with code; fewer drift bugs; simpler workflow for Ruby teams.
- Cons: Some OpenAPI-first workflows may need additional annotations in code.
- Mitigations: Rich metadata helpers (summary/description/tags/examples), selective overrides where needed.

## Alternatives considered

- OpenAPI-first: stronger language-agnostic posture, but duplicates schema logic and increases drift.

## Follow-ups

- Add CI job to generate/validate OpenAPI for examples to prevent drift.
- Document how to inject vendor extensions and examples through DSL metadata.
