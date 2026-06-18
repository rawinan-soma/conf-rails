---
workflowStatus: 'completed'
totalSteps: 5
stepsCompleted: ['step-01-detect-mode', 'step-02-load-context', 'step-03-risk-and-testability', 'step-04-coverage-plan', 'step-05-generate-output']
lastStep: 'step-05-generate-output'
nextStep: ''
lastSaved: '2026-06-18'
epic: 1
epicTitle: 'Foundation, Identity & Platform'
project: 'conf-rails'
mode: 'epic-level'
---

# Test Design: Epic 1 — Foundation, Identity & Platform

**Date:** 2026-06-18
**Author:** Rawinan
**Status:** Draft
**Project:** conf-rails (ENVOCC Conference Room Booking System)
**Stack:** Rails 8 / Ruby 4.0 / PostgreSQL / Hotwire / Solid Queue / Pundit / ViewComponent / Minitest / Kamal

---

## Executive Summary

**Scope:** Epic-level test design for Epic 1 — Foundation, Identity & Platform (Stories 1.1–1.6).
This epic establishes the entire platform that every subsequent epic builds on:
- Project initialization (Rails 8, Ruby 4.0, daisyUI/Tailwind, no Node, CI)
- Core design system & ViewComponent library (Forest & Copper theme, Thai fonts, WCAG 2.1 AA)
- OIDC authentication & 30-min session timeout
- Pundit authorization baseline (organizer/attendee capacities + admin role)
- First-login profile completion gate
- Email & background-job infrastructure (Solid Queue + ActionMailer decoupled)

**FRs in Scope:** FR-080, FR-083, FR-084, FR-090, FR-091, FR-093, FR-094, FR-095

**NFRs in Scope:** NFR-001 (Security), NFR-004 (Responsiveness), NFR-006 (Localization), NFR-007 (Accessibility)

**Risk Summary:**

- Total risks identified: 14
- High-priority risks (score ≥6): 5
- Critical categories: SEC (OIDC, session, token), TECH (CI gate integrity, profile gate bypass), OPS (credential leak)

**Coverage Summary:**

- P0 scenarios: 18 (~36–40 hours)
- P1 scenarios: 22 (~22–30 hours)
- P2 scenarios: 14 (~8–14 hours)
- P3 scenarios: 4 (~1–3 hours)
- **Total effort**: ~67–87 hours (~9–11 developer days)

---

## Not in Scope

| Item | Reasoning | Mitigation |
|------|-----------|------------|
| Booking conflict detection (EXCLUDE constraint) | Epic 2 (Story 2.4) — requires Room + Booking models | Covered in test-design-epic-2 |
| External registration token flows | Epic 3 — requires Registration model | Covered in test-design-epic-3 |
| Admin SMTP settings UI | Epic 4 (Story 4.5) — SMTP credentials configurable via admin UI | Epic 1 tests use credentials file / ENV stubs |
| Admin role assignment UI | Epic 4 (Story 4.6) — role-grant UI deferred | Epic 1 tests cover Pundit policy only; UI tested in Epic 4 |
| NFR-003 Performance load envelope (k6) | Explicitly deferred to a k6 perf plan (architecture decision) | Covered when org volumes are known; k6 baseline story in Epic 2/3 |
| NFR-005 Data Retention | No deletion UI in Epic 1 | Covered when admin deletion is implemented |
| Thai translation completion (th.yml) | Rawinan translates manually post-scaffold | en.yml + th.yml key-parity CI gate covers structure; content is OOB |
| Live OIDC IdP connectivity | OQ-3 exact attribute mapping to be confirmed at integration | Mock/stub OIDC in CI; integration test against real IdP at deploy |

---

## Risk Assessment

### High-Priority Risks (Score ≥6)

| Risk ID | Category | Description | Probability | Impact | Score | Mitigation | Owner | Timeline |
|---------|----------|-------------|-------------|--------|-------|------------|-------|----------|
| R-001 | SEC | OIDC callback accepts forged or replayed auth responses — attacker gains session without valid IdP credential | 2 | 3 | 6 | Use omniauth_openid_connect nonce + state verification; test with invalid/missing nonce, replayed state, and tampered ID tokens in unit tests; Brakeman CI gate | Dev/QA | Story 1.3 |
| R-002 | SEC | master.key or any credential accidentally committed (gitleaks miss) — secret permanently in git history | 2 | 3 | 6 | gitleaks in CI with fail-on-detect; .gitignore coverage verified in Story 1.1 AC; test CI gate rejects a diff containing a fake credential-shaped pattern | Dev | Story 1.1 |
| R-003 | SEC | Profile gate bypass — authenticated user navigates directly to an internal URL before completing profile | 2 | 3 | 6 | before_action :require_profile_complete in ApplicationController; Capybara system test: fresh OIDC login → navigate to /calendar → redirected to profile; profile stored in session flag | Dev/QA | Story 1.5 |
| R-004 | TECH | Pundit verify_authorized not applied to all controller actions — unauthorized actor performs privileged operation | 2 | 3 | 6 | Pundit verify_authorized in ApplicationController after_action; integration tests per controller; Brakeman does not catch Pundit gaps so controller tests must cover every action | Dev/QA | Story 1.4 |
| R-005 | OPS | Email send transaction rolls back triggering DB transaction — registration or booking record lost or double-sent | 2 | 3 | 6 | deliver_later (Solid Queue) used everywhere — mail enqueued after commit; test: mock mailer to raise; verify DB record committed and job queued; verify send failure does not rollback | Dev/QA | Story 1.6 |

### Medium-Priority Risks (Score 3–4)

| Risk ID | Category | Description | Probability | Impact | Score | Mitigation | Owner |
|---------|----------|-------------|-------------|--------|-------|------------|-------|
| R-006 | SEC | Session timeout not enforced — idle session beyond 30 min remains valid | 2 | 2 | 4 | Controller before_action checks last_activity_at; system test simulates time travel (Timecop/travel_to) + request after 31 min; verify redirect to login | Dev/QA |
| R-007 | TECH | I18n hardcoded string slips in — user-facing literal appears in a view without I18n key | 2 | 2 | 4 | i18n-tasks health runs in CI (fail on violations); unit test: render each component in isolation, assert no bare English strings | Dev |
| R-008 | TECH | ViewComponent rendering breaks accessibility — color-alone meaning, missing labels, contrast below 4.5:1 | 2 | 2 | 4 | WCAG 2.1 AA component tests: assert always-visible labels, aria attributes, focus ring CSS present; status-badge must use label + pattern (not color only) | Dev/QA |
| R-009 | DATA | User profile update does not propagate live to registration pages — stale contact displayed | 1 | 3 | 3 | Profile fields read live from User record in registration page render (not cached/snapshot); integration test: update profile → render registration page → verify updated contact | Dev/QA |
| R-010 | TECH | daisyUI no-Node bundle fails CSS compilation (standalone Tailwind CLI missing or misconfigured) | 1 | 3 | 3 | CI runs bin/dev build step; system test requests page and asserts expected CSS class is applied | Dev |
| R-011 | OPS | Solid Queue dead-letter: failed mail jobs not visible — silent failure | 1 | 3 | 3 | Solid Queue failed-jobs table acts as dead-letter; integration test: enqueue job that raises → assert it lands in failed-jobs table (not silently dropped) | Dev/QA |
| R-012 | SEC | Admin flag bypass — non-admin user upgrades themselves to admin via form tampering | 1 | 3 | 3 | Pundit policy for User#update: only admin can modify admin flag; Minitest: non-admin PATCH with admin:true → 403 | Dev/QA |
| R-013 | TECH | Ruby 4.0 / Rails 8 gem incompatibility — runtime error in production from untested combo | 1 | 2 | 2 | bundler-audit + CI on Ruby 4.0 matrix; runs full test suite green before story is done | Dev |

### Low-Priority Risks (Score 1–2)

| Risk ID | Category | Description | Probability | Impact | Score | Action |
|---------|----------|-------------|-------------|--------|-------|--------|
| R-014 | OPS | Kamal deploy config leaks env var in Dockerfile layer — credential visible in image history | 1 | 2 | 2 | Dockerfile uses multi-stage build + BuildKit secret mounts (no ARG for creds); verify no ENV secret in final image | Monitor |
| R-015 | BUS | Thai font (Noto Thai) not embedded in web font stack — Thai characters fall back to system font, line-height < 1.65 | 1 | 2 | 2 | System test: render Thai copy → assert font-family includes Noto; CSS body line-height assertion | Monitor |

### Risk Category Legend

- **TECH**: Technical/Architecture (flaws, integration, scalability)
- **SEC**: Security (access controls, auth, data exposure)
- **PERF**: Performance (SLA violations, degradation, resource limits)
- **DATA**: Data Integrity (loss, corruption, inconsistency)
- **BUS**: Business Impact (UX harm, logic errors, revenue)
- **OPS**: Operations (deployment, config, monitoring)

---

## NFR Planning

**Purpose:** Capture epic-specific NFR thresholds, planned validation, and evidence for later `nfr-assess`. This is not a final evidence audit.

| NFR Category | Requirement / Threshold | Risk Link | Planned Validation | Evidence Needed |
|--------------|------------------------|-----------|-------------------|-----------------|
| Security (NFR-001) | No high/critical Brakeman findings; no CVE high/critical from bundler-audit; no secrets in git (gitleaks) | R-001, R-002, R-003, R-012 | CI gate: Brakeman + bundler-audit + gitleaks fail build on any finding; Story 1.1 AC verifies CI pipeline structure | CI pipeline logs; Brakeman/bundler-audit/gitleaks output artifacts |
| Security (NFR-001) | OIDC nonce+state verified; session tokens not guessable | R-001 | Unit tests on SessionsController + OmniAuth mock: forged nonce, replayed state → failure | Test run report; OmniAuth mock assertions |
| Security (NFR-001) | Admin flag not self-elevatable; Pundit verify_authorized on all actions | R-004, R-012 | Integration test: every controller action covered by a Pundit policy; non-admin attempts privileged action → 403 | Test run report; Minitest output |
| Reliability (NFR-002, cross-cutting) | Email send never rolls back triggering DB transaction; dead-letter for failed jobs | R-005, R-011 | Integration test: mailer raises → DB record still present + job in failed-jobs table | Test run report; Solid Queue failed_jobs table state |
| Performance (NFR-003) | Calendar/dashboard load ≤ 3s p95 — load envelope DEFERRED | None in Epic 1 | k6 perf plan (separate story, post-Epic 2); not applicable to Epic 1 foundation work | k6 report (future) |
| Responsiveness (NFR-004) | Organizer UI mobile-usable; external pages fully responsive | R-008 | Capybara system tests with mobile viewport (375×667); assert no horizontal scroll; tap targets ≥44px (CSS assertions or visual review) | System test report; manual review at mobile viewport |
| Localization (NFR-006) | All user-facing strings via I18n keys; th.yml mirrors en.yml key-for-key; i18n-tasks health passes | R-007 | i18n-tasks health in CI (fail on missing/unused keys); th.yml key-parity assertion; no bare strings in components | CI i18n-tasks output |
| Accessibility (NFR-007) | WCAG 2.1 AA — contrast ≥4.5:1; visible focus rings; labels always visible; no color-alone meaning; tap targets ≥44px | R-008 | ViewComponent unit tests assert aria attributes, labels, focus ring CSS; axe-core (via axe-matchers gem) on key pages; manual audit of copper-on-cream contrast | Test report; axe-core accessibility audit output |

**Unknown thresholds:**
- NFR-003 exact p95 load envelope: UNKNOWN — deferred to k6 perf plan (architecture decision). Not blocking Epic 1.
- WCAG 2.1 AA automated coverage: partial — axe-core catches structural violations; color contrast (copper-on-cream, green-500-on-white) requires manual/visual audit or a contrast-checker tool. Note as assumption.
- OQ-3 exact OIDC claim mapping (which claims carry title, phone, org): UNKNOWN — tests use mock IdP; real mapping confirmed at integration. Note as assumption.

---

## Entry Criteria

- [ ] Epic and story acceptance criteria reviewed by Dev and QA
- [ ] Test environment: Rails 8 / Ruby 4.0 / PostgreSQL available (or Docker Compose local)
- [ ] OmniAuth mock configured in test_helper (no live IdP required)
- [ ] SMTP stubbed in test environment (ActionMailer delivery: :test)
- [ ] Fixtures ready (User, no real PII/keys)
- [ ] CI pipeline (GitHub Actions) wired up with RuboCop/Brakeman/bundler-audit/gitleaks/Minitest
- [ ] daisyUI bundle (daisyui.mjs + daisyui-theme.mjs) committed to repo

## Exit Criteria

- [ ] All P0 tests passing (18/18)
- [ ] All P1 tests passing ≥95% (21/22)
- [ ] No open SEC-category (R-001–R-004, R-012) risks unmitigated
- [ ] CI pipeline green: Brakeman, bundler-audit, gitleaks, RuboCop, Minitest all pass
- [ ] i18n-tasks health passes in CI
- [ ] Profile gate bypass scenario verified by system test
- [ ] Email/transaction decoupling verified by integration test
- [ ] No high/critical Brakeman or bundler-audit findings

---

## Test Coverage Plan

### P0 (Critical) — Run on every commit

**Criteria:** Blocks core journey + High risk (≥6) + No workaround

#### Story 1.1: Project Initialization & Platform Scaffold

| Requirement | Test Level | Risk Link | Scenario | Test Count | Owner | Notes |
|-------------|------------|-----------|----------|------------|-------|-------|
| CI gate rejects secret (Story 1.1 AC) | Unit/Integration | R-002 | Simulated CI: introduce a fake credential-shaped string; assert gitleaks step fails | 1 | Dev | Use gitleaks `--no-git` on test fixture with fake secret |
| .gitignore covers master.key, credentials/*.key, .env*, *.pem | Unit | R-002 | Assert each pattern is present in .gitignore content | 1 | Dev | File content assertion |
| Rails boots with PostgreSQL + Tailwind+daisyUI (no Node) | System | R-010 | bin/dev runs → HTTP 200 → page renders daisyUI class | 1 | Dev | Capybara GET / → assert daisyui CSS present |
| CI pipeline runs all gates (RuboCop, Brakeman, bundler-audit, gitleaks, Minitest) | Integration | R-002 | Assert CI YAML declares all five jobs/steps | 1 | Dev | Parse .github/workflows/ci.yml |
| Kamal deploy config has no secrets in source | Unit | R-002, R-014 | Assert config/deploy.yml contains no credential values (only ENV references) | 1 | Dev | File content assertion |

**Subtotal Story 1.1 P0:** 5 tests

#### Story 1.3: OIDC Authentication & Sessions

| Requirement | Test Level | Risk Link | Scenario | Test Count | Owner | Notes |
|-------------|------------|-----------|----------|------------|-------|-------|
| Unauthenticated request → redirect to IdP (FR-090) | Integration | R-001 | GET /calendar without session → 302 to OmniAuth OIDC path | 1 | QA | OmniAuth mock mode |
| OIDC callback success → User find_or_create + session starts | Integration | R-001 | OmniAuth mock returns valid UID → User created; session[:user_id] set | 1 | QA | |
| OIDC callback with forged/missing nonce → no session | Unit | R-001 | Mock OIDC failure (invalid state/nonce) → callback renders error, no session | 1 | QA | |
| OIDC callback failure → clear error, no session | Integration | R-001 | OmniAuth returns :failure → user sees error page; session empty | 1 | QA | |
| Session timeout: idle 30 min → requires re-auth (FR-093) | Integration | R-006 | travel_to(31.minutes.from_now) → GET any protected path → 302 to login | 2 | QA | Test 31 min (expired) and 29 min (still valid) |
| Session timeout is fixed (not configurable) | Unit | R-006 | INACTIVITY_TIMEOUT constant = 30.minutes; no ENV override path | 1 | Dev | |

**Subtotal Story 1.3 P0:** 7 tests

#### Story 1.4: Capacities, Admin Role & Pundit Authorization Baseline

| Requirement | Test Level | Risk Link | Scenario | Test Count | Owner | Notes |
|-------------|------------|-----------|----------|------------|-------|-------|
| verify_authorized applied — unprotected action raises Pundit::NotAuthorizedError | Integration | R-004 | Remove policy from a test controller action → assert after_action raises | 1 | Dev | Meta-test |
| Pundit unauthorized → 403 + flash (not 500) | Integration | R-004 | Non-admin requests admin-only action → response 403; flash message present | 1 | QA | |
| Admin self-elevation blocked (non-admin cannot PATCH admin=true) | Integration | R-012 | Non-admin PATCH /users/:id with admin: true → 403; admin flag unchanged | 1 | QA | |
| Admin read-all but no booking approval/edit of others (FR-094) | Integration | R-004 | Admin GET /bookings/:other_id → 200; Admin PATCH /bookings/:other_id → 403 | 2 | QA | Two separate requests |

**Subtotal Story 1.4 P0:** 5 tests

#### Story 1.5: First-Login Profile Completion Gate

| Requirement | Test Level | Risk Link | Scenario | Test Count | Owner | Notes |
|-------------|------------|-----------|----------|------------|-------|-------|
| First login with incomplete profile → gated to profile screen (FR-095) | System | R-003 | OmniAuth mock → first login → GET /calendar → redirected to /profile/edit | 1 | QA | Capybara system test |
| Profile gate blocks all internal routes until complete | Integration | R-003 | Incomplete profile user → GET /bookings → redirect to profile; GET /dashboard → redirect | 2 | QA | Test 2 protected routes |
| Email is read-only from IdP (FR-095) | Integration | R-003 | PATCH profile with email change → 422 or email unchanged | 1 | QA | |

**Subtotal Story 1.5 P0:** 4 tests

#### Story 1.6: Email & Background-Job Infrastructure

| Requirement | Test Level | Risk Link | Scenario | Test Count | Owner | Notes |
|-------------|------------|-----------|----------|------------|-------|-------|
| deliver_later: triggering transaction commits even if send fails (FR-084) | Integration | R-005 | Stub mailer to raise SMTP error → assert DB record saved; assert job in failed_jobs | 2 | QA | Two assertions = two tests |
| Failed mail job lands in dead-letter (Solid Queue failed_jobs) | Integration | R-011 | Force job to exhaust retries → assert SolidQueue::FailedExecution record present | 1 | QA | |

**Subtotal Story 1.6 P0:** 3 tests (counting the 2 assertions above as 2 tests + 1 = 3)

**Total P0: 24 tests, ~36–48 hours** (2 hr/test average for high-risk integration/system setup)

---

### P1 (High) — Run on PR to main

**Criteria:** Important features + Medium risk (3–4) + Common workflows

#### Story 1.1: Project Initialization & Platform Scaffold

| Requirement | Test Level | Risk Link | Scenario | Test Count | Owner | Notes |
|-------------|------------|-----------|----------|------------|-------|-------|
| Brakeman finds zero high/critical issues on fresh project | Integration | R-002 | Run Brakeman on codebase → assert exit code 0 (no high/critical) | 1 | Dev | CI step; also run locally |
| bundler-audit finds zero high/critical CVEs | Integration | R-002 | bundler-audit check → exit code 0 | 1 | Dev | CI step |
| RuboCop (omakase) passes with zero offenses | Integration | — | bin/rubocop → exit 0 | 1 | Dev | CI step |

**Subtotal Story 1.1 P1:** 3 tests

#### Story 1.2: Core Design System & ViewComponent UI Library

| Requirement | Test Level | Risk Link | Scenario | Test Count | Owner | Notes |
|-------------|------------|-----------|----------|------------|-------|-------|
| ButtonComponent renders with correct daisyUI classes and aria | Unit | R-008 | Render ButtonComponent(:primary) → assert class includes btn-primary; assert no color-only ARIA violation | 1 | Dev | |
| FormFieldComponent: label always visible, focus ring present | Unit | R-008 | Render FormFieldComponent → assert label element visible; assert focus ring CSS class present | 1 | Dev | |
| StatusBadgeComponent uses label+pattern, not color alone | Unit | R-008 | Render StatusBadge(:cancelled) → assert text label "Cancelled" present; assert pattern class present | 1 | Dev | |
| ModalComponent (destructive confirm) renders warning text | Unit | — | Render ModalComponent(destructive: true) → assert danger class + consequences text slot | 1 | Dev | |
| ToastComponent renders message | Unit | — | Render ToastComponent("message") → assert text present | 1 | Dev | |
| SkeletonComponent renders loading placeholder | Unit | — | Render SkeletonComponent → assert skeleton class | 1 | Dev | |
| EmptyStateComponent renders calm line + single action | Unit | — | Render EmptyStateComponent → assert action button present | 1 | Dev | |
| Forest & Copper theme applied: body uses Noto Thai fonts | System | R-010, R-015 | GET / → assert font-face includes "Noto Serif Thai" or "Noto Sans Thai" | 1 | QA | Capybara |
| Body line-height ≥ 1.65 and no text below 14px (NFR-007, UX-DR2) | System | R-008 | Computed CSS assertion or visual test on a rendered page | 1 | QA | Manual if CSS assertion not feasible |
| i18n-tasks health passes (no missing/unused keys) | Integration | R-007 | Run i18n-tasks health → exit 0 | 1 | Dev | CI step |
| th.yml mirrors en.yml key-for-key (NFR-006) | Unit | R-007 | Load both locale files; assert same key set | 1 | Dev | |
| All user-facing strings in components come from I18n keys | Unit | R-007 | ERB template render → assert no bare English string literals in output | 2 | Dev | One test per 2 template patterns |

**Subtotal Story 1.2 P1:** 12 tests

#### Story 1.3: OIDC Authentication & Sessions

| Requirement | Test Level | Risk Link | Scenario | Test Count | Owner | Notes |
|-------------|------------|-----------|----------|------------|-------|-------|
| find_or_create by IdP subject — same UID → same User (idempotent) | Unit | — | Call find_or_create twice with same UID → assert User.count unchanged | 1 | Dev | |
| Email read-only from OIDC claim — User.email never overwritten by PATCH | Unit | R-003 | Build User from OIDC; attempt update email → assert unchanged | 1 | Dev | |

**Subtotal Story 1.3 P1:** 2 tests

#### Story 1.4: Capacities, Admin Role & Pundit Authorization Baseline

| Requirement | Test Level | Risk Link | Scenario | Test Count | Owner | Notes |
|-------------|------------|-----------|----------|------------|-------|-------|
| All users have organizer+attendee capacities by default (FR-091) | Unit | — | User.new → assert .organizer? && .attendee? true with no assignment | 1 | Dev | |
| Admin flag is false by default | Unit | — | User.new → assert .admin? false | 1 | Dev | |
| BookingPolicy: user manages own bookings, not others | Unit | R-004 | BookingPolicy(user: other_user).update? → false | 1 | Dev | |
| BookingPolicy: admin can read any booking | Unit | R-004 | BookingPolicy(user: admin).show? → true for another user's booking | 1 | Dev | |

**Subtotal Story 1.4 P1:** 4 tests

#### Story 1.5: First-Login Profile Completion Gate

| Requirement | Test Level | Risk Link | Scenario | Test Count | Owner | Notes |
|-------------|------------|-----------|----------|------------|-------|-------|
| Profile form: title/first/last/phone/org editable; email read-only shown | Integration | — | GET /profiles/edit → form fields present; email shown read-only | 1 | QA | |
| Profile update success → completion flag set; app accessible | Integration | R-003 | PATCH /profiles → completion saved → GET /calendar → 200 | 1 | QA | |
| Profile changes propagate live (not cached) | Integration | R-009 | Update profile → assert User.reload has new values | 1 | Dev | |

**Subtotal Story 1.5 P1:** 3 tests

#### Story 1.6: Email & Background-Job Infrastructure

| Requirement | Test Level | Risk Link | Scenario | Test Count | Owner | Notes |
|-------------|------------|-----------|----------|------------|-------|-------|
| ApplicationMailer sender name = org name (FR-083) | Unit | — | Any mailer preview → assert from header displays org name | 1 | Dev | |
| All mailer sends use deliver_later (FR-084) | Unit | R-005 | Grep/unit test: assert no deliver_now call in mailer code | 1 | Dev | Static assertion |
| Solid Queue recurring tasks defined (auto-close + reminder) | Unit | — | Load config/recurring.yml → assert close_registrations and send_reminders entries present | 1 | Dev | |
| Job idempotency: double-enqueue same job → runs once | Unit | R-011 | Enqueue a test-idempotent job twice → assert side effect occurs once | 1 | Dev | Requires idempotency marker in job |

**Subtotal Story 1.6 P1:** 4 tests

**Total P1: 28 tests, ~22–34 hours** (~0.75–1.25 hr/test average)

---

### P2 (Medium) — Run nightly

**Criteria:** Secondary features + Low risk (1–2) + Edge cases

| Story | Requirement | Test Level | Risk Link | Scenario | Test Count | Owner | Notes |
|-------|-------------|------------|-----------|----------|------------|-------|-------|
| 1.1 | Docker image contains no ENV credentials | Integration | R-014 | Inspect built Docker image layers for credential-shaped strings | 1 | Dev | docker history check |
| 1.2 | ToggleComponent renders in on/off states | Unit | — | Render with checked: true / false → assert aria-checked | 2 | Dev | |
| 1.2 | SelectComponent renders options + aria | Unit | — | Render SelectComponent → assert option elements + label | 1 | Dev | |
| 1.2 | ReadOnlyFieldComponent renders disabled, no edit | Unit | — | Render → assert input[disabled] | 1 | Dev | |
| 1.2 | AppShell renders admin-sidebar for admin users | Integration | — | GET any page as admin → sidebar nav present | 1 | QA | |
| 1.2 | Responsive: no horizontal scroll at 375px viewport | System | — | Capybara mobile viewport → assert no overflow-x on body | 1 | QA | |
| 1.2 | axe-core accessibility scan on login page | System | R-008 | axe-matchers on /login → assert 0 WCAG 2.1 AA violations | 1 | QA | axe-matchers gem |
| 1.2 | axe-core accessibility scan on profile page | System | R-008 | axe-matchers on /profiles/edit → 0 AA violations | 1 | QA | |
| 1.3 | Login page renders in Thai locale (th.yml fallback) | System | R-007 | Switch locale to :th → GET /login → assert page responds without missing key error | 1 | QA | |
| 1.4 | Non-admin cannot access admin namespace | Integration | R-004 | Non-admin GET /admin/rooms → 403 | 1 | QA | |
| 1.5 | Completed profile: profile edit still accessible post-completion | Integration | — | Completed profile user → GET /profiles/edit → 200 | 1 | QA | |
| 1.5 | Profile validation: required fields (first/last name) enforce presence | Unit | — | User.new(first_name: nil).valid? → false; assert presence error | 1 | Dev | |
| 1.6 | Solid Queue processes a simple job end-to-end | Integration | R-011 | Enqueue TestJob → process queue → assert side effect | 1 | Dev | |
| 1.6 | Email delivery uses org SMTP (FR-080) — no third-party service | Unit | — | ActionMailer.delivery_method = :smtp; assert no SendGrid/Mailgun config present | 1 | Dev | |

**Total P2: 15 tests, ~8–15 hours** (~0.5–1 hr/test)

---

### P3 (Low) — Run on-demand / exploratory

| Story | Requirement | Test Level | Scenario | Test Count | Owner | Notes |
|-------|-------------|------------|----------|------------|-------|-------|
| 1.2 | Thai font rendering: Noto Thai glyphs visible (no tofu) | Exploratory | Manual visual check on /login with Thai locale | 1 | QA | Screenshot review |
| 1.1 | YJIT enabled in production config | Unit | Assert config/environments/production.rb has YJIT enable (Ruby 4.0) | 1 | Dev | |
| 1.3 | OIDC: different IdP provider config (edge: wrong issuer) → clear error | Unit | Mock OIDC with wrong issuer → assert error handled gracefully | 1 | QA | |
| 1.6 | Solid Queue web UI (if any) — admin can view failed jobs | Exploratory | Manual: navigate to failed jobs view (if Rails engine UI available) | 1 | QA | Optional; SolidQueue has no built-in UI; log inspection |

**Total P3: 4 tests, ~1–3 hours**

---

## Execution Order

### Smoke Tests (<3 min)

**Purpose:** Fast feedback — catch boot/config breakage

- [ ] Rails boots → HTTP 200 on root path (30s)
- [ ] PostgreSQL connection established (database.yml valid) (15s)
- [ ] OmniAuth OIDC route registered (`/auth/openid_connect`) (15s)
- [ ] Minitest suite runs with zero load errors (1 min)

**Total:** 4 scenarios

### P0 Tests (<15 min)

**Purpose:** Critical path — gate every commit

- [ ] .gitignore covers all credential patterns (unit, 10s)
- [ ] gitleaks rejects fake credential in diff (integration, 30s)
- [ ] CI YAML declares all five pipeline gates (unit, 10s)
- [ ] Kamal config contains no hardcoded secrets (unit, 10s)
- [ ] daisyUI renders on page (system, 1 min)
- [ ] OIDC callback → User created + session (integration, 20s)
- [ ] OIDC failure → no session (integration, 15s)
- [ ] Forged nonce → no session (unit, 10s)
- [ ] Session timeout 31 min → redirect (integration, 20s)
- [ ] Session valid at 29 min (integration, 15s)
- [ ] Session timeout fixed (unit, 5s)
- [ ] verify_authorized enforced (integration, 20s)
- [ ] Unauthorized → 403 not 500 (integration, 15s)
- [ ] Non-admin cannot self-elevate (integration, 15s)
- [ ] Admin read-all (integration, 20s)
- [ ] Admin cannot edit others' bookings (integration, 15s)
- [ ] First login → profile gate (system, 1 min)
- [ ] Profile gate on 2 routes (integration, 20s)
- [ ] Email read-only (integration, 15s)
- [ ] deliver_later: DB commits even if send fails (integration, 20s)
- [ ] Failed send: DB record present + job in failed_jobs (integration, 20s)
- [ ] Failed job lands in dead-letter (integration, 20s)

**Total:** 22 P0 scenarios (~12–14 min)

### P1 Tests (<30 min)

**Purpose:** Feature coverage — gate every PR

- [ ] Brakeman: zero high/critical (CI, 2 min)
- [ ] bundler-audit: zero CVE high/critical (CI, 30s)
- [ ] RuboCop: zero offenses (CI, 1 min)
- [ ] i18n-tasks health passes (CI, 30s)
- [ ] th.yml mirrors en.yml (unit, 10s)
- [ ] ButtonComponent aria + classes (unit, 5s)
- [ ] FormFieldComponent label + focus (unit, 5s)
- [ ] StatusBadge label+pattern (unit, 5s)
- [ ] Font-face Noto Thai in page (system, 1 min)
- [ ] find_or_create idempotent (unit, 5s)
- [ ] All users organizer+attendee by default (unit, 5s)
- [ ] Admin flag false by default (unit, 5s)
- [ ] BookingPolicy: own-only (unit, 5s)
- [ ] BookingPolicy: admin read-all (unit, 5s)
- [ ] Profile form: email read-only shown (integration, 20s)
- [ ] Profile update → completion flag → app accessible (integration, 20s)
- [ ] Mailer sender = org name (unit, 5s)
- [ ] No deliver_now in mailer code (unit, 5s)
- [ ] Recurring tasks in config/recurring.yml (unit, 5s)
- [ ] Job idempotency (unit, 20s)

**Total:** 20 P1 scenarios (~8–12 min)

### P2/P3 Tests (Nightly / On-demand)

**Total:** 15 + 4 = 19 scenarios (~20–40 min)

---

## Resource Estimates

### Test Development Effort

| Priority | Count | Hours/Test | Total Hours | Notes |
|----------|-------|------------|-------------|-------|
| P0 | 22 | ~2.0 | ~40–44 | Complex security/integration setup; OmniAuth mock, Timecop, Solid Queue stubs |
| P1 | 20 | ~1.0 | ~18–24 | Standard coverage; ViewComponent unit tests, I18n assertions |
| P2 | 15 | ~0.6 | ~8–10 | Edge cases; axe-core setup one-time cost |
| P3 | 4 | ~0.5 | ~2–3 | Exploratory / manual |
| **Total** | **61** | **—** | **~68–81 hours** | **~9–11 developer days** |

### Prerequisites

**Test Data:**
- `UserFixture` / `UserFactory` (faker-based first_name, last_name, email, title, phone, org — no real PII)
- OmniAuth mock auth hash factory (configurable UID, email, claims)
- No real SMTP or IdP credentials in fixtures

**Tooling:**
- Minitest (Rails default) — unit + integration tests
- Capybara + system tests (Rails 8 built-in) — system tests
- OmniAuth test mode (`:test` strategy) — OIDC mock
- Timecop or Rails `travel_to` helper — session timeout tests
- axe-matchers gem — WCAG 2.1 AA automated checks
- i18n-tasks gem — key parity CI gate
- gitleaks — secret scanning in CI
- Brakeman + bundler-audit — security static analysis in CI

**Environment:**
- PostgreSQL available in CI (GitHub Actions `services:` block)
- Ruby 4.0.x pinned in `.ruby-version`
- No external OIDC IdP required (OmniAuth mock mode)
- No live SMTP required (ActionMailer delivery: :test)

---

## Quality Gate Criteria

### Pass/Fail Thresholds

- **P0 pass rate:** 100% (no exceptions; all 22 must pass before PR merge)
- **P1 pass rate:** ≥95% (≥19/20; failures require triage + waiver)
- **P2/P3 pass rate:** ≥85% (informational; nightly)
- **Security (R-001–R-004, R-012):** 100% pass rate — non-negotiable

### Coverage Targets

- **Critical authentication/authorization paths:** 100%
- **CI security gates (Brakeman, bundler-audit, gitleaks):** 100% enabled and enforced
- **I18n key parity:** 100% (i18n-tasks health)
- **ViewComponent unit coverage:** ≥80% of base components
- **Business logic (profile gate, session timeout):** 100%

### Non-Negotiable Requirements

- [ ] All P0 tests pass
- [ ] No high-risk (score ≥6) items unmitigated (R-001–R-005 must have test coverage)
- [ ] SEC tests pass 100% (R-001, R-002, R-003, R-004, R-005, R-012)
- [ ] gitleaks detects no secrets in codebase at time of Epic 1 completion
- [ ] Brakeman and bundler-audit find no high/critical issues
- [ ] i18n-tasks health passes (NFR-006)
- [ ] NFR-001 evidence: CI pipeline logs with all gates green

---

## Mitigation Plans

### R-001: OIDC Forged/Replayed Auth Response (Score: 6)

**Mitigation Strategy:** Use `omniauth_openid_connect`'s built-in nonce + state verification; write unit tests that feed invalid/missing nonce, replayed state, and tampered claims to the OmniAuth mock and assert SessionsController returns an error without creating a session. Document that production IdP uses HTTPS + short token expiry.

**Owner:** Dev + QA
**Timeline:** Story 1.3 implementation
**Status:** Planned
**Verification:** P0 test suite: 4 OIDC auth tests all green

---

### R-002: Credential Committed to Git (Score: 6)

**Mitigation Strategy:** gitleaks in GitHub Actions CI (fail on detect); .gitignore verified by unit test; CI YAML asserts all five gates present; Kamal config asserted to contain no literal credential values. Supplement with developer pre-commit hook (gitleaks) for local protection.

**Owner:** Dev
**Timeline:** Story 1.1 implementation
**Status:** Planned
**Verification:** P0 test: gitleaks step rejects a test fixture with a fake credential-shaped string; CI pipeline run green on clean code

---

### R-003: Profile Gate Bypass (Score: 6)

**Mitigation Strategy:** `before_action :require_profile_complete` in ApplicationController (applied to all authenticated routes except profile controller and OmniAuth callbacks); Capybara system test covers the full login → gate → profile completion → app access flow.

**Owner:** Dev + QA
**Timeline:** Story 1.5 implementation
**Status:** Planned
**Verification:** P0 system test: fresh first login navigates to /calendar → redirected to /profiles/edit; on completion → /calendar 200

---

### R-004: Pundit verify_authorized Missing (Score: 6)

**Mitigation Strategy:** `after_action :verify_authorized, except: :index` in ApplicationController (or per-controller). Meta-test: write a controller test that omits `authorize` in an action and asserts `Pundit::AuthorizationNotPerformedError` is raised. Cover every Epic 1 controller action with explicit policy assertions.

**Owner:** Dev + QA
**Timeline:** Story 1.4 implementation
**Status:** Planned
**Verification:** P0 integration tests: every action tested; Pundit::NotAuthorizedError → 403 confirmed

---

### R-005: Email Send Rolls Back Triggering Transaction (Score: 6)

**Mitigation Strategy:** All mailer calls use `deliver_later` (assert via static grep + unit test). Integration test: stub mailer to raise SMTP error after job executes → assert DB record (User/Booking) is already committed and not rolled back; assert SolidQueue::FailedExecution row appears.

**Owner:** Dev + QA
**Timeline:** Story 1.6 implementation
**Status:** Planned
**Verification:** P0 integration tests: 3 tests covering transaction independence + dead-letter

---

## Assumptions and Dependencies

### Assumptions

1. OmniAuth test mode (`:test` strategy) is available and sufficient for CI testing of OIDC flows; live IdP connectivity is not required for the test suite.
2. `travel_to` (Rails time helper) can simulate session timeout without external dependencies.
3. axe-matchers gem is compatible with Rails 8 / Ruby 4.0 and Capybara.
4. WCAG color contrast (copper-on-cream, green-500-on-white) requires manual/visual audit in addition to axe-core; automated contrast thresholds are assumptions until design token values are finalized.
5. OQ-3 OIDC claim mapping (title, phone, org from IdP vs. user-entered) is confirmed at integration time against the real IdP — not blocking test design.
6. Thai translation content in th.yml is Rawinan's responsibility; the CI gate only verifies key parity, not translation quality.

### Dependencies

1. axe-matchers gem — add to Gemfile (dev/test group); required before P2 accessibility tests
2. gitleaks binary — installed in GitHub Actions runner or via action; required before Story 1.1 CI gate
3. Solid Queue gem + config — required for Story 1.6 job tests
4. OmniAuth test mode configuration in `test/test_helper.rb` — required for all Story 1.3 tests
5. PostgreSQL service in GitHub Actions — required for all integration/system tests

### Risks to Plan

- **Risk:** OQ-3 OIDC claim mapping unknown — if IdP does not expose title/phone/org claims, first-login profile screen must collect all fields from user input.
  - **Impact:** Profile field pre-population tests may differ from real IdP behavior.
  - **Contingency:** Tests use mock OIDC returning only `sub` + `email`; other fields assumed user-entered. Adjust if real IdP claims are broader.

- **Risk:** Ruby 4.0 / axe-matchers compatibility unknown.
  - **Impact:** P2 accessibility tests may require an alternative tool (e.g., `capybara-axe`, manual).
  - **Contingency:** If axe-matchers incompatible, replace with manual WCAG audit + `capybara-accessible` or similar.

- **Risk:** Timecop not compatible with Solid Queue internal time handling.
  - **Impact:** Session timeout tests may behave unexpectedly.
  - **Contingency:** Use Rails `travel_to` helper (built-in, no Timecop gem required for modern Rails).

---

## Interworking & Regression

| Service/Component | Impact | Regression Scope |
|-------------------|--------|-----------------|
| Epic 2 — Rooms & Booking | Requires Pundit policies from Story 1.4; uses Solid Queue email from Story 1.6 | Epic 1 policy tests must pass before Epic 2 starts |
| Epic 3 — Registration | Requires OIDC auth (Story 1.3), profile gate (Story 1.5), email infra (Story 1.6) | Epic 1 full P0+P1 suite must be green before Epic 3 |
| Epic 4 — Admin | Requires admin flag from Story 1.4; SMTP settings from Story 1.6 | Story 1.4 Pundit admin tests must pass |
| CI Pipeline (GitHub Actions) | All subsequent stories depend on Story 1.1 CI gates | Story 1.1 CI YAML test must be green before any other story's code is merged |

---

## Follow-on Workflows

- Run `/bmad-testarch-atdd` to generate failing P0 tests for Story 1.3 (OIDC) and Story 1.4 (Pundit) first — these are the highest-risk stories.
- Run `/bmad-testarch-automate` for broader Minitest coverage once Story 1.2 components are implemented.
- Run `/bmad-testarch-nfr` for NFR evidence collection after all 6 stories are complete.

---

## Approval

**Test Design Approved By:**

- [ ] Product Manager: Rawinan — Date: ___
- [ ] Tech Lead: Rawinan — Date: ___
- [ ] QA Lead: Rawinan — Date: ___

**Comments:** Solo developer project; single approver covers all roles.

---

## Appendix

### Knowledge Base References

- `risk-governance.md` — Risk classification framework (TECH/SEC/PERF/DATA/BUS/OPS)
- `probability-impact.md` — Risk scoring: Probability 1–3 × Impact 1–3 = Score 1–9; ≥6 = high
- `test-levels-framework.md` — Unit → Integration → System test level selection
- `test-priorities-matrix.md` — P0 (critical, every commit) → P1 (PR) → P2 (nightly) → P3 (on-demand)

### Related Documents

- PRD: `_bmad-output/planning-artifacts/prds/prd-conference-envocc-2026-06-07/prd.md`
- Epics: `_bmad-output/planning-artifacts/epics.md`
- Architecture: `_bmad-output/planning-artifacts/architecture.md`
- UX Design: `_bmad-output/planning-artifacts/ux-designs/ux-conference-envocc-2026-06-07/DESIGN.md`
- Sprint Status: `_bmad-output/implementation-artifacts/sprint-status.yaml`

---

**Generated by:** BMad TEA Agent — Test Architect Module (Master Test Architect)
**Workflow:** `bmad-testarch-test-design`
**Version:** 4.0 (BMad v6)
**Date:** 2026-06-18
**Mode:** Epic-Level (Create)
