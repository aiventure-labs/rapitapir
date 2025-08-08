# ADR-0007: AI features scope (RAG/LLM/MCP) and maintainability boundaries

Date: 2025-08-08
Status: Accepted

## Context

RapiTapir includes AI-adjacent features: LLM instruction generation, a simple RAG pipeline (memory backend), and MCP export for agent tooling. These should remain optional and decoupled from core HTTP concerns.

## Decision

- Namespace AI features under `RapiTapir::AI` and keep them opt-in.
- Provide provider-agnostic interfaces; avoid hard vendor locks and network calls in core.
- Ship deterministic test doubles and local-only defaults (e.g., memory backend) for reliability.
- Limit feature scope to developer tooling and augmentation (instructions, docs, context), not business logic.

## Consequences

- Pros: Clear boundaries, low risk to core stability, easy to disable.
- Cons: Smaller immediate feature set vs vendor SDKs.
- Mitigations: Extension points for providers; examples that demonstrate integration without coupling.

## Alternatives considered

- Deep vendor integrations in core: faster to demo, harder to maintain and test.

## Follow-ups

- Add guidance on switching RAG backends and plugging external vector stores.
- Provide examples for MCP export consumption in popular agents.
