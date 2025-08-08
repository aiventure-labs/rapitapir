# Architectural Decision Records (ADRs)

This directory contains Architecture Decision Records (ADRs) that document significant architectural decisions made throughout the RapiTapir project.

## Purpose

- Maintain a clear history of architectural choices and their rationale.
- Provide context and rationale for future maintainers and contributors.

## ADR Structure

Each ADR is a Markdown file with a sequential identifier and a descriptive title:

```
NNNN-short-title.md
```

Inside, ADRs follow this structure:

```
# ADR NNNN: Short Title

Date: YYYY-MM-DD

## Status

Proposed | Accepted | Deprecated

## Context

Describe the context and forces leading to this decision.

## Decision

Describe the decision and its rationale.

## Consequences

Describe the resulting consequences, trade-offs, and impacts.
```

## Creating a New ADR

1. Copy `template.md` and rename to the next sequence number, e.g., `0002-add-auth-cache.md`.
2. Fill in date, status, context, decision, and consequences.
3. Commit the new ADR file to the repository.
