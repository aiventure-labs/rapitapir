# ADR-0002: Type shortcut (T) and type system boundaries

Date: 2025-08-08
Status: Accepted

## Context

The library offers a rich runtime type system (primitives, composites, optionals, constraints, coercion). Frequent usage leads to verbosity (e.g., `RapiTapir::Types.string`).

## Decision

- Provide a global, ergonomic alias `T` to the type system (e.g., `T.string`, `T.array(T.integer)`, `T.hash({ "id" => T.integer })`).
- Keep the type system strictly runtime-validating with coercion where safe; no mandatory compile-time type checker dependency.
- Maintain boundaries: core remains independent of Sorbet/RBS; optional generators/adapters may be provided later.

## Consequences

- Pros: Concise schemas, consistent across DSL and apps, lower ceremony.
- Cons: Potential namespace collision in extreme cases.
- Mitigations: `T` is introduced in RapiTapir surface with clear docs; fallback to fully-qualified `RapiTapir::Types` always available.

## Alternatives considered

- No shortcut: more explicit but verbose.
- Multiple shortcuts per namespace: increases confusion and conflicts.

## Follow-ups

- Keep schema examples in docs using `T` for clarity.
- Provide guidance on custom types and how to avoid collisions.
