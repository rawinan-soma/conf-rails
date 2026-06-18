---
workflowStatus: 'completed'
totalSteps: 5
stepsCompleted: ['step-01-detect-mode', 'step-02-load-context', 'step-03-risk-and-testability', 'step-04-coverage-plan', 'step-05-generate-output']
lastStep: 'step-05-generate-output'
nextStep: ''
lastSaved: '2026-06-18'
inputDocuments:
  - _bmad-output/planning-artifacts/epics.md
  - _bmad-output/planning-artifacts/architecture.md
  - _bmad-output/implementation-artifacts/sprint-status.yaml
  - _bmad/tea/config.yaml
mode: 'epic-level'
epicTarget: 'Epic 1 — Foundation, Identity & Platform'
outputFile: '_bmad-output/test-artifacts/test-design/test-design-epic-1.md'
---

# Test Design Progress — Epic 1: Foundation, Identity & Platform

## Step 1: Mode Detection (Complete)

- **Selected Mode**: Epic-Level
- **Reason**: User explicitly specified "Epic 1 — Foundation, Identity & Platform"; sprint-status.yaml present confirms BMad epic structure.
- **Epic in scope**: Epic 1 — Foundation, Identity & Platform (Stories 1.1–1.6)
- **FRs covered**: FR-080, FR-083, FR-084, FR-090, FR-091, FR-093, FR-094, FR-095

## Step 2: Context Loaded (Complete)

**Stack Detected**: backend (Ruby/Rails — Gemfile present, no frontend-only indicators)

**Configuration Read**:
- `tea_use_playwright_utils`: true
- `tea_use_pactjs_utils`: false
- `tea_pact_mcp`: none
- `tea_browser_automation`: auto
- `test_stack_type`: auto → detected backend (Rails/Minitest)
- `test_artifacts`: `_bmad-output/test-artifacts`

**Artifacts Loaded**:
- epics.md: Stories 1.1–1.6 with full acceptance criteria
- architecture.md: Rails 8 / Ruby 4.0 / PostgreSQL / Hotwire / Solid Queue / Pundit / ViewComponent / Minitest / Kamal stack

**Existing Tests**: None (project pre-implementation, all stories in backlog)

**Epic 1 FRs in scope**:
- FR-080: Outbound email via org SMTP only
- FR-083: Sender display name = org name
- FR-084: Email send decoupled from transaction (deliver_later + retry + dead-letter)
- FR-090: OIDC auth via org IdP
- FR-091: organizer/attendee default capacities; admin = only assignable role
- FR-093: 30-min fixed inactivity session timeout
- FR-094: RBAC — manage-own-only; admin read-all, no booking approval/edit
- FR-095: User profile (title, first/last name, phone, email from IdP read-only); first-login gate

**NFRs in scope for Epic 1**:
- NFR-001: Security — no high/critical vulns; CI gate (Brakeman + bundler-audit + gitleaks)
- NFR-004: Responsiveness — organizer UI mobile-usable
- NFR-006: Localization — Thai UI via I18n; th.yml key-mirror
- NFR-007: Accessibility — WCAG 2.1 AA

## Step 3: Risk & Testability Assessment (Complete)

### Testability Notes

- **Controllability**: OIDC IdP must be mocked (OmniAuth test mode); SMTP must be stubbed; no live external deps in test suite — architecture specifies this.
- **Observability**: Minitest + Capybara system tests; CI produces pass/fail reports; lograge for structured logs; gitleaks for secret-scan output.
- **Reliability**: Tests isolated via fixtures (no PII/keys); OmniAuth mocked in test_helper.

### Risk Register Built (see test plan)

### NFR Planning Built (see test plan)

## Step 4: Coverage Plan (Complete)

- P0: 18 test scenarios (OIDC auth gate, session timeout, Pundit enforcement, first-login gate, email decoupling, CI security gates)
- P1: 22 test scenarios (profile CRUD, role assignment, ViewComponent rendering, I18n coverage, job idempotency)
- P2: 14 test scenarios (accessibility, responsiveness, error states, edge cases)
- P3: 4 test scenarios (exploratory, Thai font rendering)

## Step 5: Output Generated (Complete)

Output: `_bmad-output/test-artifacts/test-design/test-design-epic-1.md`
