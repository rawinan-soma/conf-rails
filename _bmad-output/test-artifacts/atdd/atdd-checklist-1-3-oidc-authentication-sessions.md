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
storyId: '1.3'
storyKey: 1-3-oidc-authentication-sessions
storyFile: >-
  _bmad-output/implementation-artifacts/1-3-oidc-authentication-sessions.md
atddChecklistPath: >-
  _bmad-output/test-artifacts/atdd/atdd-checklist-1-3-oidc-authentication-sessions.md
generatedTestFiles:
  - test/models/user_test.rb
  - test/controllers/sessions_controller_test.rb
  - test/integration/authentication_flow_test.rb
  - test/fixtures/users.yml
inputDocuments:
  - _bmad-output/implementation-artifacts/1-3-oidc-authentication-sessions.md
  - _bmad/tea/config.yaml
  - test/test_helper.rb
---

# ATDD Checklist: Story 1.3 — OIDC Authentication & Sessions

**Date:** 2026-06-19
**Story:** 1.3 — OIDC Authentication & Sessions
**TDD Phase:** RED (all tests skipped until implementation)
**Stack:** Ruby on Rails 8 / Minitest (backend — no Playwright/TypeScript)
**Execution Mode:** SEQUENTIAL (model → controller → integration)

---

## Step 1: Preflight & Context Loading

### Stack Detection

- **Detected Stack:** `backend`
- **Reason:** No `package.json`, `playwright.config.*`, or frontend framework indicators found. Project is a pure Rails 8 monolith (zero Node). Minitest is the confirmed test framework.
- **Test Framework:** Minitest (`ActionDispatch::IntegrationTest`, `ActionController::TestCase`, `ActiveSupport::TestCase`)

### Prerequisites Satisfied

- [x] Story has clear acceptance criteria (3 ACs with BDD Given/When/Then)
- [x] Backend test config indicators: Rails 8 project structure (Gemfile with omniauth_openid_connect, test/ directory with test_helper.rb)
- [x] Story status: `ready-for-dev`
- [x] `omniauth_openid_connect` gem already in Gemfile (added in Story 1.1)

### Loaded Artifacts

- Story file: `_bmad-output/implementation-artifacts/1-3-oidc-authentication-sessions.md`
- Config: `_bmad/tea/config.yaml`
- Existing test patterns: `test/integration/project_scaffold_test.rb` (Story 1.1 reference)
- Existing test_helper: `test/test_helper.rb`

---

## Step 2: Generation Mode

**Mode:** AI Generation (backend stack — no browser recording needed)

**Rationale:** Acceptance criteria are clear and all scenarios are authentication/session management tests. Story specifies exact test file locations, OmniAuth mock patterns, and test data in Dev Notes. No UI interaction recording required — controller and integration tests use `ActionDispatch::IntegrationTest` request simulation.

---

## Step 3: Test Strategy

### Acceptance Criteria → Test Scenarios Mapping

| AC | Scenario | Test Level | Priority | File | Test Name |
|----|----------|------------|----------|------|-----------|
| AC-1 | find_or_create_by_omniauth creates new user | Unit/Model | P0 | user_test.rb | `find_or_create_by_omniauth creates a new user from a valid auth hash` |
| AC-1 | find_or_create_by_omniauth returns existing user | Unit/Model | P0 | user_test.rb | `find_or_create_by_omniauth returns existing user for the same provider/uid` |
| AC-1 | Email not updated on subsequent logins | Unit/Model | P0 | user_test.rb | `find_or_create_by_omniauth does NOT update email on subsequent logins` |
| AC-1 | User invalid without provider | Unit/Model | P1 | user_test.rb | `user is invalid without provider` |
| AC-1 | User invalid without uid | Unit/Model | P1 | user_test.rb | `user is invalid without uid` |
| AC-1 | User invalid without email | Unit/Model | P1 | user_test.rb | `user is invalid without email` |
| AC-1 | Duplicate provider/uid rejected | Unit/Model | P1 | user_test.rb | `user is invalid when provider/uid combination is not unique` |
| AC-1 | admin? false for regular user | Unit/Model | P1 | user_test.rb | `admin? returns false for a regular user` |
| AC-1 | admin? true for admin user | Unit/Model | P1 | user_test.rb | `admin? returns true for an admin user` |
| AC-1 | profile_complete? false when nil | Unit/Model | P1 | user_test.rb | `profile_complete? returns false when profile_completed_at is nil` |
| AC-1 | profile_complete? true when set | Unit/Model | P1 | user_test.rb | `profile_complete? returns true when profile_completed_at is set` |
| AC-1 | User.admins scope | Unit/Model | P2 | user_test.rb | `User.admins scope returns only admin users` |
| AC-1 | Callback creates session + redirects | Controller | P0 | sessions_controller_test.rb | `OmniAuth callback creates session and redirects to root` |
| AC-1 | Callback creates new User | Controller | P0 | sessions_controller_test.rb | `OmniAuth callback creates a new User when uid is unknown` |
| AC-1 | Callback finds existing User | Controller | P0 | sessions_controller_test.rb | `OmniAuth callback finds existing User when uid is known` |
| AC-1 | session[:user_id] set to user id | Controller | P0 | sessions_controller_test.rb | `OmniAuth callback sets session[:user_id] to the found/created user's id` |
| AC-1 | Redirect to return_to after auth | Controller | P0 | sessions_controller_test.rb | `OmniAuth callback redirects to session[:return_to] if set` |
| AC-1 | External return_to rejected | Controller | P0 | sessions_controller_test.rb | `return_to URL with external domain is ignored (open redirect protection)` |
| AC-3 | Failure clears session | Controller | P0 | sessions_controller_test.rb | `GET /auth/failure clears any partial session state` |
| AC-3 | Failure redirects to sign-in | Controller | P0 | sessions_controller_test.rb | `GET /auth/failure redirects to new_session_path` |
| AC-3 | Failure sets flash alert | Controller | P0 | sessions_controller_test.rb | `GET /auth/failure sets a flash alert` |
| AC-1 | Sign-out clears session | Controller | P1 | sessions_controller_test.rb | `DELETE /sign_out clears session and redirects to new_session_path` |
| AC-1 | Sign-out calls reset_session | Controller | P1 | sessions_controller_test.rb | `DELETE /sign_out calls reset_session (prevents session fixation)` |
| AC-1 | Sign-out flash notice | Controller | P1 | sessions_controller_test.rb | `DELETE /sign_out sets a signed-out flash notice` |
| AC-1 | New action renders 200 | Controller | P2 | sessions_controller_test.rb | `GET /sign_in renders the sign-in page with HTTP 200` |
| AC-1 | Sign-in page has POST form | Controller | P2 | sessions_controller_test.rb | `sign-in page contains a POST form to /auth/openid_connect` |
| AC-1 | Unauthenticated redirects to sign-in | Integration | P0 | authentication_flow_test.rb | `unauthenticated request to a protected page redirects to sign-in` |
| AC-1 | return_to stored on redirect | Integration | P0 | authentication_flow_test.rb | `unauthenticated request stores the original URL in session[:return_to]` |
| AC-1 | Full sign-in flow | Integration | P0 | authentication_flow_test.rb | `full sign-in flow: unauthenticated → IdP → callback → original URL` |
| AC-2 | Session expires after 30 min | Integration | P0 | authentication_flow_test.rb | `session expires after 30 minutes of inactivity` |
| AC-2 | Timeout sets flash alert | Integration | P0 | authentication_flow_test.rb | `session timeout sets a flash alert informing the user` |
| AC-2 | Session valid before 30 min | Integration | P0 | authentication_flow_test.rb | `session does NOT expire before 30 minutes of inactivity` |
| AC-2 | Sliding window resets timer | Integration | P0 | authentication_flow_test.rb | `inactivity timeout is a sliding window — activity resets the timer` |
| AC-2 | Timeout calls reset_session | Integration | P0 | authentication_flow_test.rb | `session timeout calls reset_session to prevent session fixation` |
| AC-2 | INACTIVITY_TIMEOUT constant = 30 min | Integration | P1 | authentication_flow_test.rb | `INACTIVITY_TIMEOUT constant is exactly 30 minutes and not configurable` |
| AC-3 | Failure creates no session | Integration | P0 | authentication_flow_test.rb | `OIDC callback failure does not create a session` |
| AC-3 | Failure shows clear error | Integration | P0 | authentication_flow_test.rb | `authentication failure renders a clear error message` |
| AC-1 | last_active_at updated per request | Integration | P1 | authentication_flow_test.rb | `session[:last_active_at] is updated on each authenticated request` |
| AC-1 | current_user returns user for valid session | Integration | P1 | authentication_flow_test.rb | `current_user returns the authenticated user for a valid session` |
| AC-1 | current_user nil for unauthenticated | Integration | P1 | authentication_flow_test.rb | `current_user returns nil for an unauthenticated request` |

### Priority Summary

| Priority | Count |
|----------|-------|
| P0 | 24 |
| P1 | 12 |
| P2 | 4 |
| **Total** | **40** |

### TDD Red Phase Compliance

- All 40 tests use `skip "ATDD RED PHASE — ..."` (Minitest skip pattern)
- All tests assert EXPECTED behavior (not placeholders like `assert true`)
- Tests designed to FAIL before Story 1.3 is implemented
- Activated tests fail first, then pass after implementation (TDD green)

---

## Step 4: Generated Test Files

### Generated Files

1. **`test/models/user_test.rb`**
   - Class: `UserTest < ActiveSupport::TestCase`
   - 12 test methods (P0: 3, P1: 8, P2: 1) — all skipped
   - Covers: AC-1 (`find_or_create_by_omniauth`, validations, predicates, scope)

2. **`test/controllers/sessions_controller_test.rb`**
   - Class: `SessionsControllerTest < ActionDispatch::IntegrationTest`
   - 14 test methods (P0: 9, P1: 3, P2: 2) — all skipped
   - Covers: AC-1 (callback flow, return_to, destroy) + AC-3 (failure action)

3. **`test/integration/authentication_flow_test.rb`**
   - Class: `AuthenticationFlowTest < ActionDispatch::IntegrationTest`
   - 14 test methods (P0: 12, P1: 4, P2: 0) — all skipped
   - Covers: AC-1 (full flow, current_user) + AC-2 (30-min timeout, sliding window) + AC-3 (no session on failure)

4. **`test/fixtures/users.yml`**
   - 2 fixtures: `regular_user` and `admin_user`
   - Non-realistic UIDs (`test-uid-*`), `@example.test` emails, no real PII

5. **`test/test_helper.rb`** (updated)
   - Added OmniAuth test mode configuration (commented — activate with Task 3)
   - Added `stub_omniauth` and `stub_omniauth_failure` helper stubs (commented)

### Fixture Needs

- `test/fixtures/users.yml` — 2 fixtures (regular + admin)
- OmniAuth test mode (`OmniAuth.config.test_mode = true`) — via test_helper.rb (commented until Task 3)
- `stub_omniauth` and `stub_omniauth_failure` helpers — via test_helper.rb (commented until Task 3)

---

## Step 5: Validation

### Checklist Validation

- [x] Prerequisites satisfied (story has 3 ACs, backend stack detected, Minitest framework)
- [x] All test files created at correct paths under `test/`
- [x] All tests use `skip "ATDD RED PHASE — ..."` (Minitest skip, not `test.skip()` which is Playwright)
- [x] All tests assert expected behavior with specific assertions (not `assert true`)
- [x] User fixtures use fake UIDs and `@example.test` emails — gitleaks safe
- [x] Story metadata captured: storyId, storyKey, storyFile, atddChecklistPath
- [x] `generatedTestFiles` list is complete and deterministic
- [x] No temp artifacts in random locations (checklist in `_bmad-output/test-artifacts/atdd/`)
- [x] No orphaned browser sessions (pure Rails controller/integration tests — no browser required at generation time)
- [x] Test levels match detected stack: Unit/Model + Controller + Integration (backend/Rails — no Playwright API/E2E TypeScript)
- [x] OmniAuth test mode and helpers added to test_helper.rb (commented — safe to activate with Task 3)
- [x] No real OIDC credentials or plausible-looking secrets in any test file

### Assumptions & Risks

1. **`root_path` undefined:** Integration tests assume `root_path` resolves. Story 1.3 Dev Notes specify adding `root to: 'sessions#new'` as a temporary placeholder — required before integration tests can run.
2. **OmniAuth middleware not yet mounted:** `stub_omniauth` helpers in test_helper.rb are commented out until `config/initializers/omniauth.rb` exists (Task 2). Activating them before Task 2 will raise `NameError: uninitialized constant OmniAuth`.
3. **User model does not exist yet:** All model tests and any test that calls `User.find_by` will raise `NameError: uninitialized constant User` until Task 1 is complete — correct red phase failure.
4. **`session.id` in integration tests:** `request.session.id` may require a wrapping request object. The reset_session tests may need adjustment to use `session.id.public_id.to_s` depending on Rails 8 session store. Acceptable risk — note for green phase.
5. **`travel` time helper:** Uses `ActiveSupport::Testing::TimeHelpers` which is included in `ActiveSupport::TestCase` by default in Rails 8. Verify inclusion if tests raise `NoMethodError`.
6. **`assert_select` in integration tests:** Requires HTML responses. Integration tests that use `assert_select` must `follow_redirect!` if the action redirects before checking HTML.

---

## Next Steps (Task-by-Task Activation)

During implementation of each Story 1.3 task:

1. Remove the `skip` line from the relevant test(s)
2. Uncomment `OmniAuth.config.test_mode = true` and the stub helpers in `test/test_helper.rb` once Task 2 is complete
3. Run: `bundle exec rails test <test_file>`
4. Verify the activated test FAILS first (red phase confirmed)
5. Implement the feature (the task)
6. Run tests again — verify PASS (green phase)
7. Commit the passing tests

### Activation Map

| Task | Activate tests in |
|------|-------------------|
| Task 1: User model + migration | All of `test/models/user_test.rb`; load `test/fixtures/users.yml` |
| Task 2: OmniAuth initializer | Uncomment `OmniAuth.config.test_mode = true` and stubs in `test_helper.rb` |
| Task 3: SessionsController | All of `test/controllers/sessions_controller_test.rb` |
| Task 4: Routes | Required prerequisite before controller + integration tests can run |
| Task 5: ApplicationController helpers | All of `test/integration/authentication_flow_test.rb` |
| Task 6: Views + I18n | `GET /sign_in renders 200`, `sign-in page has POST form`, flash message tests |

---

## ATDD Artifacts

- **Checklist:** `_bmad-output/test-artifacts/atdd/atdd-checklist-1-3-oidc-authentication-sessions.md`
- **Model tests:** `test/models/user_test.rb`
- **Controller tests:** `test/controllers/sessions_controller_test.rb`
- **Integration tests:** `test/integration/authentication_flow_test.rb`
- **Fixtures:** `test/fixtures/users.yml`
- **test_helper.rb:** Updated with OmniAuth test mode stubs (commented)

**Next Workflow:** `dev-story` (implement Story 1.3) → activate tests task by task → `automate` (after implementation, for CI wiring)
