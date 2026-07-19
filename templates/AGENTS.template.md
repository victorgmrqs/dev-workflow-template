# AGENTS.md — {{project.name}}

<!-- Keep this file short. Procedures live in skills; layer conventions live in rules. -->

## Overview

{{Three sentences: what the system does, for whom, and its architecture in one line.}}

## Stack

{{Language/version, framework, database, test runner, dependency manager — one line each.}}

## Commands

```bash
{{lint}}         # lint
{{typecheck}}    # typecheck
{{test}}         # tests
{{build}}        # build, when applicable
```

## Non-negotiable constraints

{{At most eight factual constraints, referencing ADR/NFR IDs when available.}}

## Workflow

- Planning: `docs/prd/` → `docs/hld.md` → `docs/fdds/` → tickets.
- Execution: `/task <TICKET-ID>` → brief → approval → implementation/tests → docs → DoD → review → delivery.
- Configuration: `.dev-workflow/workflow.config.yaml`.

## Documentation loaded on demand

- Business rules: `docs/domain-context.md`
- Architecture: `docs/hld.md`; ADRs: `docs/adr/`
- Domain design: `docs/fdds/`
