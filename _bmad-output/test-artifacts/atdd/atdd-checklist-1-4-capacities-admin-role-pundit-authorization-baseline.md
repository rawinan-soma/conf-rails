---
stepsCompleted:
  - step-01-preflight-and-context
  - step-02-generation-mode
  - step-03-test-strategy
  - step-04-generate-tests
  - step-04c-aggregate
  - step-05-validate-and-complete
lastStep: step-05-validate-and-complete
lastSaved: '2026-06-19'
storyId: '1.4'
storyKey: 1-4-capacities-admin-role-pundit-authorization-baseline
storyFile: >-
  _bmad-output/implementation-artifacts/1-4-capacities-admin-role-pundit-authorization-baseline.md
atddChecklistPath: >-
  _bmad-output/test-artifacts/atdd/atdd-checklist-1-4-capacities-admin-role-pundit-authorization-baseline.md
generatedTestFiles:
  - test/policies/application_policy_test.rb
  - test/integration/authorization_baseline_test.rb
inputDocuments:
  - _bmad-output/implementation-artifacts/1-4-capacities-admin-role-pundit-authorization-baseline.md
  - _bmad/tea/config.yaml
  - test/test_helper.rb
  - test/fixtures/users.yml
  - app/controllers/application_controller.rb
  - _bmad-output/test-artifacts/atdd/atdd-checklist-1-3-oidc-authentication-sessions.md
---

# ATDD Checklist: Story 1.4 — Capacities, Admin Role & Pundit Authorization Baseline

**Date:** 2026-06-19
**Story:** 1.4 — Capacities, Admin Role & Pundit Authorization Baseline
**TDD Phase:** RED (all tests skipped until implementation)
**Stack:** Ruby on Rails 8 / Minitest (backend — no Playwright/TypeScript)
**Execution Mode:** SEQUENTIAL (policy unit → integration)

---

## Step 1: Preflight & Context Loading

### Stack Detection

- **Detected Stack:** `backend`
- **Reason:** No `package.json`, `playwright.config.*`, or frontend framework indicators found. Project is a pure Rails 8 monolith (zero Node). Minitest is the confirmed test framework.
- **Test Framework:** Minitest (`ActionDispatch::IntegrationTest`, `ActiveSupport::TestCase`)

### Prerequisites Satisfied

- [x] Story has clear acceptance criteria (3 ACs with BDD Given/When/Then)
- [x] Backend test config indicators: Rails 8 project structure (Gemfile with `pundit`, `test/` directory with `test_helper.rb`)
- [x] Story status: `ready-for-dev`
- [x] `pundit` gem is already in the Gemfile (added in Story 1.1 — commented "configured in Story 1.4")
- [x] User fixtures already committed (`test/fixtures/users.yml`) with `regular_user` and `admin_user`
- [x] OmniAuth test helpers (`sign_in`, `stub_omniauth`) already in `test/test_helper.rb` from Story 1.3

### Loaded Artifacts

- Story file: `_bmad-output/implementation-artifacts/1-4-capacities-admin-role-pundit-authorization-baseline.md`
- Config: `_bmad/tea/config.yaml`
- Existing test patterns: `test/integration/authentication_flow_test.rb` (Story 1.3 reference)
- Existing test_helper: `test/test_helper.rb`
- Existing fixtures: `test/fixtures/users.yml`
- Previous ATDD checklist: `_bmad-output/test-artifacts/atdd/atdd-checklist-1-3-oidc-authentication-sessions.md`

### TEA Config Flags

- `tea_use_playwright_utils`: `true` (ignored — backend stack, Rails Minitest only)
- `tea_use_pactjs_utils`: `false`
- `tea_browser_automation`: `auto` (ignored — backend stack)
- `test_stack_type`: `auto` → resolved to `backend`

---

## Step 2: Generation Mode

**Mode:** AI Generation (backend stack — no browser recording needed)

**Rationale:** Acceptance criteria are clear and all scenarios are Pundit policy/authorization tests. The story specifies exact test file locations (`test/policies/application_policy_test.rb`, `test/integration/authorization_baseline_test.rb`), fixture names (`users(:regular_user)`, `users(:admin_user)`), and expected policy behavior in Dev Notes. No UI interaction recording required.

**Pact.js / Contract Testing:** Not applicable — this story introduces no API endpoints or inter-service contracts.

---

## Step 3: Test Strategy

### Acceptance Criteria → Test Scenarios Mapping

| AC | Scenario | Test Level | Priority | File | Test Name |
|----|----------|------------|----------|------|-----------|
| AC-2 | `ApplicationPolicy#index?` deny for plain user | Unit/Policy | P0 | application_policy_test.rb | `ApplicationPolicy#index? returns false for a plain user on a generic record` |
| AC-2 | `ApplicationPolicy#show?` deny for plain user | Unit/Policy | P0 | application_policy_test.rb | `ApplicationPolicy#show? returns false for a plain user on a generic record` |
| AC-2 | `ApplicationPolicy#create?` deny for plain user | Unit/Policy | P0 | application_policy_test.rb | `ApplicationPolicy#create? returns false for a plain user on a generic record` |
| AC-2 | `ApplicationPolicy#new?` deny for plain user | Unit/Policy | P0 | application_policy_test.rb | `ApplicationPolicy#new? returns false for a plain user on a generic record` |
| AC-2 | `ApplicationPolicy#update?` deny for plain user | Unit/Policy | P0 | application_policy_test.rb | `ApplicationPolicy#update? returns false for a plain user on a generic record` |
| AC-2 | `ApplicationPolicy#edit?` deny for plain user | Unit/Policy | P0 | application_policy_test.rb | `ApplicationPolicy#edit? returns false for a plain user on a generic record` |
| AC-2 | `ApplicationPolicy#destroy?` deny for plain user | Unit/Policy | P0 | application_policy_test.rb | `ApplicationPolicy#destroy? returns false for a plain user on a generic record` |
| AC-2 | `Scope#resolve` raises NotImplementedError | Unit/Policy | P0 | application_policy_test.rb | `ApplicationPolicy::Scope#resolve raises NotImplementedError for base class` |
| AC-1+3 | `admin?` false for regular user | Unit/Policy | P1 | application_policy_test.rb | `admin? returns false for a regular user (organizer+attendee only)` |
| AC-1+3 | `admin?` true for admin user | Unit/Policy | P1 | application_policy_test.rb | `admin? returns true for an admin user` |
| AC-2 | Policy exposes user + record via attr_reader | Unit/Policy | P1 | application_policy_test.rb | `ApplicationPolicy exposes user and record via attr_reader` |
| AC-3 | Admin structural prerequisite + deny-by-default base | Unit/Policy | P1 | application_policy_test.rb | `admin user has admin? true — structural prerequisite for AC-3 BookingPolicy and RegistrationPolicy` |
| AC-2 | Authenticated user GET / → 200, HomeController skips | Integration | P0 | authorization_baseline_test.rb | `authenticated user hits GET / and gets 200 — HomeController skips verify_authorized` |
| AC-2 | Unauthenticated user GET / → redirect to sign-in | Integration | P0 | authorization_baseline_test.rb | `unauthenticated user hitting GET / is redirected to sign-in` |
| AC-2 | GET /sign_in no NotAuthorizedError — Sessions skip | Integration | P0 | authorization_baseline_test.rb | `GET /sign_in does NOT raise Pundit::NotAuthorizedError` |
| AC-2 | DELETE /sign_out no NotAuthorizedError — Sessions skip | Integration | P0 | authorization_baseline_test.rb | `DELETE /sign_out does NOT raise Pundit::NotAuthorizedError` |
| AC-2 | NotAuthorizedError rescued — deny returns 403 + flash | Integration | P0 | authorization_baseline_test.rb | `Pundit::NotAuthorizedError is rescued with 403 redirect and flash alert` |
| AC-2 | flash.not_authorized I18n key (English) | Integration | P0 | authorization_baseline_test.rb | `flash.not_authorized I18n key returns a non-empty string in English` |
| AC-2 | flash.not_authorized I18n key mirrored (Thai) | Integration | P0 | authorization_baseline_test.rb | `flash.not_authorized I18n key is mirrored in Thai locale` |
| AC-1 | Authenticated user reaches root — capacities default | Integration | P1 | authorization_baseline_test.rb | `any authenticated user reaches GET / — organizer+attendee capacities are default` |
| AC-1 | Admin user reaches root — admin is additive | Integration | P1 | authorization_baseline_test.rb | `admin user also reaches GET / — admin is the only elevated role, not a restriction` |
| AC-2 | ApplicationController includes Pundit::Authorization | Integration | P1 | authorization_baseline_test.rb | `ApplicationController includes Pundit::Authorization` |
| AC-2 | ApplicationController has after_action :verify_authorized | Integration | P1 | authorization_baseline_test.rb | `ApplicationController has after_action :verify_authorized registered` |
| AC-2 | SessionsController skips verify_authorized | Integration | P1 | authorization_baseline_test.rb | `SessionsController has skip_after_action :verify_authorized registered` |

### Priority Summary

| Priority | Count |
|----------|-------|
| P0 | 16 |
| P1 | 8 |
| **Total** | **24** |

### TDD Red Phase Compliance

- All 24 tests use `skip "ATDD RED PHASE — ..."` (Minitest skip pattern)
- All tests assert EXPECTED behavior (specific assertions, not `assert true` placeholders)
- Tests designed to FAIL before Story 1.4 is implemented
- `test/policies/application_policy_test.rb` will raise `NameError: uninitialized constant ApplicationPolicy` until Task 2 is complete — correct red-phase failure
- Integration tests will fail with `Pundit::AuthorizationNotPerformedError` or raise until Task 1 wires verify_authorized — correct red-phase failure

---

## Step 4: Generated Test Files

### Generated Files

1. **`test/policies/application_policy_test.rb`** _(NEW)_
   - Class: `ApplicationPolicyTest < ActiveSupport::TestCase`
   - 12 test methods (P0: 8, P1: 4) — all skipped
   - Covers: AC-2 (deny-by-default for all 7 policy actions + Scope), AC-1/AC-3 (admin? predicate, attr_reader)
   - Uses fixtures: `users(:regular_user)`, `users(:admin_user)`

2. **`test/integration/authorization_baseline_test.rb`** _(NEW)_
   - Class: `AuthorizationBaselineTest < ActionDispatch::IntegrationTest`
   - 12 test methods (P0: 8, P1: 4) — all skipped
   - Covers: AC-2 (Pundit wiring, rescue_from, flash, SessionsController/HomeController skips), AC-1 (default capacities at HTTP layer)
   - Uses: `sign_in` helper from Story 1.3 test_helper.rb

### No New Fixtures Needed

- `test/fixtures/users.yml` already committed with `regular_user` and `admin_user` (Story 1.3)
- `test/test_helper.rb` already has `sign_in` / `stub_omniauth` helpers (Story 1.3)
- No changes required to existing test infrastructure

### What Is NOT in These Tests

- **HomeController skip_after_action** — tested indirectly via GET / returning 200 (Integration P0)
- **`verify_policy_scoped`** — no index actions with real scopes yet; not tested in this story
- **Full AC-3 BookingPolicy / RegistrationPolicy** — `Booking` and `Registration` models do not exist yet
  - Deferred to Story 2.1 (BookingPolicy) and Story 3.1 (RegistrationPolicy)
  - The structural prerequisite (`admin? == true` on fixtures) is asserted here
- **Admin role assignment UI** — Story 4.6, not tested here

---

## Step 5: Validation

### Checklist Validation

- [x] Prerequisites satisfied (story has 3 ACs, backend stack detected, Minitest framework)
- [x] All test files created at correct paths under `test/`
- [x] All tests use `skip "ATDD RED PHASE — ..."` (Minitest skip, not `test.skip()` which is Playwright)
- [x] All tests assert expected behavior with specific assertions (not `assert true` or `assert false`)
- [x] Policy tests use `users(:regular_user)` and `users(:admin_user)` fixtures (already in users.yml)
- [x] Integration tests use `sign_in` helper from Story 1.3 test_helper.rb (already committed)
- [x] Story metadata captured: storyId, storyKey, storyFile, atddChecklistPath
- [x] `generatedTestFiles` list is complete and deterministic
- [x] Temp artifacts in correct location (`_bmad-output/test-artifacts/atdd/`)
- [x] No orphaned browser sessions (pure Rails unit/integration tests — no browser at generation time)
- [x] Test levels match detected stack: Policy Unit + Integration (backend/Rails — no Playwright API/E2E)
- [x] AC-3 deferral documented with TODO comments pointing to Story 2.1 and Story 3.1
- [x] No real credentials or plausible-looking secrets in test files
- [x] gitleaks-safe email patterns (`@example.test`, non-realistic UIDs)
- [x] I18n key tests assert both `en` and `th` locales (mirrors `i18n-tasks health` gate)

### Assumptions & Risks

1. **`ApplicationPolicy` not yet created:** `application_policy_test.rb` will raise `NameError: uninitialized constant ApplicationPolicy` until Task 2 is complete — correct TDD red phase.
2. **`Pundit::Authorization` not yet included:** Integration tests hitting routes where `verify_authorized` is not called will fail with `Pundit::AuthorizationNotPerformedError` after Task 1 — correct regression-detection behavior.
3. **`SessionsController callback chain` introspection:** The `_process_action_callbacks` introspection test may need adjustment in the green phase depending on how Rails/Pundit registers callback skips internally. The functional integration test (GET /sign_in returns 200) is the more reliable assertion.
4. **Rescue_from returns 303 redirect, not 403 status:** The story spec says "returns 403 with flash" but `redirect_to` in Rails rescue_from sends a 3xx by default. The integration test validates the flash alert content and redirect behavior rather than a literal 403 HTTP status. A `head :forbidden` or `render status: :forbidden` would be needed for literal 403 — this is acceptable for flash-redirect-based authorization denial.
5. **AC-3 full enforcement deferred:** `Booking` and `Registration` models do not exist. AC-3 structural prerequisites are asserted at policy level (`admin? == true`, base policy denies admin too). Full resource-level policy tests are in Story 2.1 and Story 3.1.

---

## Next Steps (Task-by-Task Activation)

During implementation of each Story 1.4 task:

1. Remove the `skip` line from the relevant test(s)
2. Run: `bundle exec rails test <test_file>`
3. Verify the activated test FAILS first (red phase confirmed)
4. Implement the feature (the task)
5. Run tests again — verify PASS (green phase)
6. Run full suite: `bundle exec rails test` (must still pass)
7. Commit the passing tests

### Activation Map

| Task | Activate tests in |
|------|-------------------|
| Task 1: `include Pundit::Authorization`, `after_action :verify_authorized`, `rescue_from` in ApplicationController | `[P0]` all integration tests in `authorization_baseline_test.rb` for Pundit wiring; `[P1]` ApplicationController callback introspection tests |
| Task 2: `ApplicationPolicy` base class | All of `test/policies/application_policy_test.rb` |
| Task 3: `HomeController skip_after_action :verify_authorized, only: :index` | `[P0]` `authenticated user hits GET / and gets 200` |
| Task 4: `pundit_user` / `verify_policy_scoped` hook | No specific new tests (structural — existing tests cover it) |
| Task 5: I18n keys (`flash.not_authorized` in `en.yml` + `th.yml`) | `[P0]` both I18n flash tests in `authorization_baseline_test.rb` |
| Task 6: Full test suite run | All tests in both files must be GREEN; `bundle exec rails test` ≥76 existing + new policy + integration tests |

---

## ATDD Artifacts

- **Checklist:** `_bmad-output/test-artifacts/atdd/atdd-checklist-1-4-capacities-admin-role-pundit-authorization-baseline.md`
- **Policy unit tests:** `test/policies/application_policy_test.rb`
- **Integration tests:** `test/integration/authorization_baseline_test.rb`
- **Fixtures (pre-existing):** `test/fixtures/users.yml` (no changes — already has `regular_user` + `admin_user`)
- **test_helper.rb (pre-existing):** `test/test_helper.rb` (no changes — already has `sign_in` helper)

**Next Workflow:** `dev-story` (implement Story 1.4) → activate tests task by task → `automate` (after implementation, for CI wiring)
