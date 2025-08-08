# ADR-0004: Client generation target (TypeScript first) and interface conventions

Date: 2025-08-08
Status: Accepted

## Context

We can generate clients in multiple languages. The highest demand from users is a typed browser/Node ecosystem client with first-class DX.

## Decision

Prioritize TypeScript as the official first-class generated client:

- Emit strongly-typed request/response models and method signatures.
- Promise-based API with configurable baseUrl and fetch/adapter options.
- Typed error envelope for non-2xx responses (e.g., discriminated union or exception type).
- Keep the generator pluggable to allow future languages (Ruby, Python) without coupling core.

## Consequences

- Pros: Maximizes reach for frontend/backend TS users; fast feedback loop; strong typing.
- Cons: Non-TS ecosystems need to wait for parity.
- Mitigations: Stable generator interface; community templates for other languages.

## Conventions

- Method names derived from path + HTTP verb; idempotent naming for GET/list/show.
- Query/path/body segmentation mirrors server types.
- Semantic versioning of client generator to avoid breaking downstream apps.

## Follow-ups

- Add examples for browser and Node usage, including auth headers and retries.
- Track demand for additional languages and prioritize accordingly.
