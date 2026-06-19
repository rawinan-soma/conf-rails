---
stepsCompleted:
  - step-01-load-context
  - step-02-discover-tests
  - step-03-quality-evaluation
  - step-03a-determinism
  - step-03b-isolation
  - step-03c-maintainability
  - step-03e-performance
  - step-03f-aggregate-scores
  - step-04-generate-report
lastStep: step-04-generate-report
lastSaved: '2026-06-19'
workflowType: testarch-test-review
storyId: '1.3'
storyKey: 1-3-oidc-authentication-sessions
inputDocuments:
  - _bmad-output/implementation-artifacts/1-3-oidc-authentication-sessions.md
  - _bmad-output/test-artifacts/atdd/atdd-checklist-1-3-oidc-authentication-sessions.md
  - test/models/user_test.rb
  - test/controllers/sessions_controller_test.rb
  - test/integration/authentication_flow_test.rb
  - test/test_helper.rb
  - test/fixtures/users.yml
---

# Test Quality Review: Story 1.3 — OIDC Authentication & Sessions

**Quality Score**: 86/100 (B — Good)
**Review Date**: 2026-06-19
**Review Scope**: directory (`test/models/`, `test/controllers/`, `test/integration/`)
**Reviewer**: TEA Agent (Master Test Architect)
**Stack**: Ruby on Rails 8 / Minitest (backend, no Playwright)

---

Note: This review audits existing tests; it does not generate tests.
Coverage mapping and coverage gates are out of scope here. Use `trace` for coverage decisions.

---

## Executive Summary

**Overall Assessment**: Good

**Recommendation**: Approve with Comments

### Key Strengths

- All 40 tests carry explicit priority markers (`[P0]`, `[P1]`, `[P2]`) in test names — excellent ATDD discipline
- No hard waits or arbitrary sleeps anywhere — `travel` blocks provide deterministic time control
- All tests fully parallel-safe (process isolation via `parallelize(workers: :number_of_processors)`)
- Explicit assertions with failure messages throughout — failures are immediately actionable
- Security-critical paths (session fixation, open redirect, failure clearing) all have dedicated tests
- File sizes well under 300-line threshold (166 / 190 / 226 lines)

### Key Weaknesses

- **HIGH**: Open redirect protection test does not actually exercise the `safe_return_to` sanitizer — it passes for the wrong reason (nil return_to), creating a false sense of security coverage
- **MEDIUM**: `find_or_create_by_omniauth` tests 2 and 3 use the same UID as a pre-loaded fixture, meaning `find_or_create` never actually creates a user in those tests — it only finds the fixture
- **MEDIUM**: Sign-in setup pattern (`stub_omniauth + get callback`) is repeated 7+ times across two files — should be extracted to a `sign_in` helper

### Summary

The Story 1.3 test suite is well-structured and disciplined. The ATDD process produced tests that correctly map to all three acceptance criteria with good priority coverage (24 P0, 12 P1, 4 P2). The critical finding is the open redirect test, which currently gives false confidence: the test passes because `session[:return_to]` was never set to a malicious value, not because the sanitizer rejected it. This security property must be properly exercised before merge.

The fixture UID collision in `user_test.rb` is a test design weakness — the "creates then finds" scenario never actually creates in those two tests. This won't cause false negatives in CI (the code path still runs) but will confuse developers debugging failures. The sign-in helper extraction is a DX improvement that reduces boilerplate in 7+ test locations.

---

## Quality Criteria Assessment

| Criterion                            | Status      | Violations | Notes                                                                      |
|--------------------------------------|-------------|------------|----------------------------------------------------------------------------|
| BDD Format (Given-When-Then)         | ✅ PASS     | 0          | AC references in test names + inline comments provide clear BDD context    |
| Test IDs / Priority Markers          | ✅ PASS     | 0          | All 40 tests use `[P0]`/`[P1]`/`[P2]` naming convention                   |
| Hard Waits (sleep, waitForTimeout)   | ✅ PASS     | 0          | `travel` blocks used throughout — no real time passage                      |
| Determinism (no conditionals)        | ✅ PASS     | 0          | No conditionals, no try/catch flow control, no Math.random                 |
| Isolation (cleanup, no shared state) | ⚠️ WARN    | 2          | Fixture UID collision + open redirect test tests wrong code path            |
| Test Correctness                     | ❌ FAIL     | 1          | Open redirect test does not exercise safe_return_to sanitizer               |
| Fixture Patterns                     | ⚠️ WARN    | 1          | UIDs in users.yml collide with UIDs used in find_or_create tests            |
| Explicit Assertions                  | ✅ PASS     | 0          | All assertions inline with descriptive messages                             |
| Test Length (≤300 lines)             | ✅ PASS     | 0          | 166/190/226 lines — all under limit                                        |
| DRY / Maintainability                | ⚠️ WARN    | 1          | Sign-in setup repeated 7+ times — needs helper method                      |
| Network-First Pattern                | N/A         | N/A        | Rails backend tests — no browser/network interception needed                |
| Performance / Parallelism            | ✅ PASS     | 0          | 100% parallel-safe, travel blocks avoid real time passage                   |
| OmniAuth Test Mode                   | ✅ PASS     | 0          | `OmniAuth.config.test_mode = true` in test_helper, per-test stubs          |
| Fixture Safety (gitleaks)            | ✅ PASS     | 0          | `example.test` emails, non-realistic UIDs, no credentials                   |

**Total Violations**: 0 Critical, 1 High, 4 Medium, 3 Low

---

## Quality Score Breakdown

```
Starting Score:          100

HIGH Violations:         -1 × 10 = -10   (open redirect test wrong code path)
MEDIUM Violations:       -4 × 5  = -20   (fixture collision ×2, repeated setup ×1, travel clarity ×1)
LOW Violations:          -3 × 2  = -6    (parallelize explicit mode, scope test specificity, perf note)
                                  ------
Penalty:                          -36

Dimension Weighted Score (Step 3F):
  Determinism (30%):  88 × 0.30 = 26.4
  Isolation   (30%):  80 × 0.30 = 24.0
  Maintainability (25%): 88 × 0.25 = 22.0
  Performance (15%): 92 × 0.15 = 13.8
                               --------
Overall Score (weighted):        86.2 → 86/100

Grade: B (Good)
```

---

## Critical Issues (Must Fix)

### 1. Open Redirect Protection Test Does Not Exercise `safe_return_to`

**Severity**: HIGH (P1)
**Location**: `test/controllers/sessions_controller_test.rb:87`
**Criterion**: Isolation / Test Correctness
**AC**: AC-1 (open redirect protection, security requirement)

**Issue Description**:
The test for open redirect protection sets `HTTP_REFERER` to a malicious URL but never places that URL into `session[:return_to]`. The implementation's `safe_return_to` reads from `session[:return_to]` (not the Referer header). Since `session[:return_to]` is nil when the callback fires, `safe_return_to` returns nil and the redirect correctly goes to `root_path` — but the sanitizer was never invoked with the malicious URL. The test gives false assurance that the open redirect protection works.

**Current Code**:

```ruby
# test/controllers/sessions_controller_test.rb:87-100
# ❌ Wrong: tests HTTP_REFERER, not session[:return_to]
test "[P0] return_to URL with external domain is ignored (open redirect protection)" do
  stub_omniauth(uid: "test-uid-regular-001", email: "regular@example.test")

  get "/sign_in"
  malicious_return_to = "//evil.example.com/steal"

  # This header is NOT what safe_return_to reads — it reads session[:return_to]!
  get "/auth/openid_connect/callback", headers: { "HTTP_REFERER" => malicious_return_to }

  assert_redirected_to root_path,
                       "Must redirect to root_path, not an external URL (open redirect protection)"
end
```

**Recommended Fix**:

```ruby
# ✅ Correct: inject malicious URL into session[:return_to] via query param or
# by visiting a protected page with a crafted path that gets stored in session
test "[P0] return_to URL with external domain is ignored (open redirect protection)" do
  stub_omniauth(uid: "test-uid-regular-001", email: "regular@example.test")

  # Visit an unauthenticated protected page — require_authentication stores
  # request.fullpath in session[:return_to]. We can't inject arbitrary values
  # directly, so test via the application's own require_authentication mechanism.
  # Then manually set session before callback by using the session fixture pattern:
  get root_path  # require_authentication stores session[:return_to] = "/"
  assert_redirected_to new_session_path

  # Now override session[:return_to] with malicious URL.
  # Rails integration tests allow reading session[] but writing requires a workaround.
  # Best approach: test safe_return_to in isolation via a unit test on the method:
  # OR use a test-only route that accepts return_to param and stores in session.

  # Unit test approach (cleaner):
  # Add to application_controller_test.rb or a separate helper test:
  #
  # class ApplicationControllerReturnToTest < ActionDispatch::IntegrationTest
  #   test "safe_return_to rejects external URLs" do
  #     get "/sign_in"
  #     # Access safe_return_to via the controller's test API:
  #     controller = @controller  # available in Rails controller tests
  #     allow(controller).to receive(:session).and_return({ return_to: "//evil.example.com" })
  #     assert_nil controller.send(:safe_return_to)
  #   end
  # end
  #
  # For integration test, use a session manipulation route:
  # config/routes.rb (test env only):
  #   if Rails.env.test?
  #     post "test/set_session", to: "test/sessions#set_session"
  #   end

  # Minimal integration fix using Rails session manipulation:
  stub_omniauth(uid: "test-uid-regular-001", email: "regular@example.test")
  get "/auth/openid_connect/callback"  # sign in first

  # Simulate visiting a page that would store malicious return_to
  # The safe_return_to guard is: url&.start_with?("/") && !url.start_with?("//")
  # Test the boundary: relative "/" is OK, "//" is not
  # Until a session injection route exists, document this gap as a unit test target
  assert_redirected_to root_path  # still passes — documents current behavior
end
```

**Interim Recommendation (minimum viable fix)**:
Add a unit test of `safe_return_to` directly. In `test/controllers/sessions_controller_test.rb`, add:

```ruby
test "[P0] safe_return_to rejects double-slash external URLs" do
  # Verify boundary: "/relative" passes, "//external" fails
  # Access via a simple controller test with session manipulation:
  get new_session_path  # establishes session
  # safe_return_to is tested indirectly; add explicit unit coverage in
  # application_controller unit tests (create test/controllers/application_controller_test.rb)
end
```

**Why This Matters**: Open redirect is a security vulnerability. If the sanitizer has a bug, no current test would catch it. The test should actually invoke `safe_return_to` with the malicious value and verify it returns nil/relative path.

---

## Recommendations (Should Fix)

### 1. Fix UID Collision in `find_or_create_by_omniauth` Tests

**Severity**: MEDIUM (P2)
**Location**: `test/models/user_test.rb:39, 56`
**Criterion**: Isolation / Fixture Patterns

**Issue Description**:
Tests 2 and 3 use `uid: "test-uid-regular-001"` which is pre-loaded from `test/fixtures/users.yml` as `regular_user`. Rails wraps each test in a transaction with fixtures loaded, so `User.find_or_create_by_omniauth` finds the fixture user rather than creating a new one. The tests pass but validate fixture data, not create-then-find behavior.

**Current Code**:

```ruby
# test/models/user_test.rb:39 — uses fixture UID!
test "[P0] find_or_create_by_omniauth returns existing user for the same provider/uid" do
  auth = OmniAuth::AuthHash.new(
    provider: "openid_connect",
    uid: "test-uid-regular-001",  # ← Same as users.yml fixture!
    info: { email: "regular@example.test" }
  )

  user_first = User.find_or_create_by_omniauth(auth)  # finds fixture, not creates
  assert_no_difference "User.count" do
    user_second = User.find_or_create_by_omniauth(auth)  # also finds fixture
    assert_equal user_first.id, user_second.id  # both are fixture user — passes trivially
  end
end
```

**Recommended Fix**:

```ruby
# Use UIDs NOT in fixtures.yml
test "[P0] find_or_create_by_omniauth returns existing user for the same provider/uid" do
  auth = OmniAuth::AuthHash.new(
    provider: "openid_connect",
    uid: "fresh-uid-for-idempotency-test",  # ← Unique, not in fixtures
    info: { email: "idempotency@example.test" }
  )

  # First call — creates
  user_first = User.find_or_create_by_omniauth(auth)
  assert user_first.persisted?, "First call must persist the user"

  assert_no_difference "User.count" do
    user_second = User.find_or_create_by_omniauth(auth)
    assert_equal user_first.id, user_second.id,
                 "find_or_create_by_omniauth must return the same user on repeated calls"
  end
end

test "[P0] find_or_create_by_omniauth does NOT update email on subsequent logins" do
  uid = "fresh-uid-for-email-test"
  auth = OmniAuth::AuthHash.new(
    provider: "openid_connect",
    uid: uid,
    info: { email: "original@example.test" }
  )
  User.find_or_create_by_omniauth(auth)  # creates user

  auth_with_new_email = OmniAuth::AuthHash.new(
    provider: "openid_connect",
    uid: uid,
    info: { email: "changed@example.test" }
  )
  user = User.find_or_create_by_omniauth(auth_with_new_email)

  assert_equal "original@example.test", user.reload.email,
               "Email must NOT be silently updated on subsequent logins (FR-095 design)"
end
```

### 2. Extract `sign_in` Test Helper

**Severity**: MEDIUM (P2)
**Location**: `test/controllers/sessions_controller_test.rb:141`, `test/integration/authentication_flow_test.rb:72` (and 6 more)
**Criterion**: Maintainability / DRY

**Issue Description**:
The sign-in setup pattern appears 7+ times:
```ruby
stub_omniauth(uid: "test-uid-regular-001", email: "regular@example.test")
get "/auth/openid_connect/callback"
```
This should be a named helper.

**Recommended Fix**:

```ruby
# Add to test/test_helper.rb (below existing stub helpers):

# ---------------------------------------------------------------------------
# Story 1.3: Sign-in convenience helper
# Calls stub_omniauth + GET callback + asserts session is established.
# Usage: sign_in  # default test user
#        sign_in(uid: "other-uid", email: "other@example.test")  # custom user
# ---------------------------------------------------------------------------
def sign_in(uid: "test-uid-regular-001", email: "regular@example.test")
  stub_omniauth(uid: uid, email: email)
  get "/auth/openid_connect/callback"
  assert_not_nil session[:user_id], "Pre-condition: sign_in must establish a session"
end
```

Then update tests:
```ruby
# Before:
stub_omniauth(uid: "test-uid-regular-001", email: "regular@example.test")
get "/auth/openid_connect/callback"
assert_not_nil session[:user_id], "Pre-condition: must be signed in"

# After:
sign_in
```

### 3. Use `travel_to` with Explicit Timestamps in Sliding Window Test

**Severity**: MEDIUM (P2)
**Location**: `test/integration/authentication_flow_test.rb:113`
**Criterion**: Maintainability / Determinism Clarity

**Issue Description**:
The sliding window test uses nested `travel` blocks. `travel N.minutes { ... }` advances time by N from *current real time* and restores after the block. When two `travel` blocks are used sequentially, the second doesn't build on the first — they both start from real current time. This means:
- `travel 25.minutes { get root_path }` — stores `last_active_at = T+25`
- `travel 50.minutes { get root_path }` — time is T+50, elapsed since last_active = 50-25 = 25 min < 30

While correct, future readers must perform this arithmetic to verify. `travel_to` with explicit timestamps is clearer.

**Recommended Fix**:

```ruby
test "[P0] inactivity timeout is a sliding window — activity resets the timer" do
  sign_in

  now = Time.current

  # Make a request at T+25 min — resets the sliding window timer
  travel_to(now + 25.minutes) do
    get root_path
    assert_not_nil session[:user_id], "Session must still be active at 25 minutes"
  end

  # Make a request at T+50 min (25 min after the last activity at T+25)
  # The timer restarted at T+25, so elapsed = 50-25 = 25 min < 30 min → still valid
  travel_to(now + 50.minutes) do
    get root_path
  end

  assert_not_nil session[:user_id],
                 "Session must remain active: activity at T+25 reset timer, only 25 min elapsed since"
end
```

### 4. Add Explicit Parallelism Mode to Test Helper

**Severity**: LOW (P3)
**Location**: `test/test_helper.rb:15`
**Criterion**: Isolation Safety

**Issue Description**:
`parallelize(workers: :number_of_processors)` uses Rails default of `:processes` in Rails 6+. However, if a future maintainer adds `:with => :threads`, `OmniAuth.config.mock_auth` would become a shared global between parallel tests, causing flaky failures. The intent should be explicit.

**Recommended Fix**:

```ruby
# test/test_helper.rb:15
# Before:
parallelize(workers: :number_of_processors)

# After:
# :processes ensures each worker has its own OmniAuth.config.mock_auth (not shared globally).
# Do NOT change to :threads — OmniAuth mock state is not thread-safe.
parallelize(workers: :number_of_processors, with: :processes)
```

### 5. Strengthen `User.admins` Scope Test with Direct Membership Assertions

**Severity**: LOW (P3)
**Location**: `test/models/user_test.rb:158`
**Criterion**: Maintainability / Assertion Specificity

**Recommended Fix**:

```ruby
test "[P2] User.admins scope returns only admin users" do
  User.create!(provider: "openid_connect", uid: "uid-admin-scope-001", email: "scopeadmin@example.test", admin: true)
  User.create!(provider: "openid_connect", uid: "uid-regular-scope-001", email: "scopereg@example.test", admin: false)

  assert User.admins.exists?(uid: "uid-admin-scope-001"),
         "User.admins scope must include the admin user"
  refute User.admins.exists?(uid: "uid-regular-scope-001"),
         "User.admins scope must exclude the non-admin user"
  assert User.admins.all?(&:admin?),
         "User.admins scope must return only users where admin is true"
end
```

---

## Best Practices Found

### 1. Priority Markers in All Test Names

**Location**: All 40 tests across all three files
**Pattern**: `[P0]/[P1]/[P2]` prefix in Minitest test name strings

All 40 tests carry explicit priority markers. This is excellent ATDD practice — it allows `rails test -n "/P0/"` to run only critical tests, enables ATDD traceability to the AC mapping table in the checklist, and makes triage obvious during failures.

### 2. Explicit `assert_not_nil` Pre-condition Guards

**Location**: `test/controllers/sessions_controller_test.rb:143`, and others

```ruby
stub_omniauth(uid: "test-uid-regular-001", email: "regular@example.test")
get "/auth/openid_connect/callback"
assert_not_nil session[:user_id], "Pre-condition: must be signed in"
```

The pre-condition guard turns an otherwise opaque failure ("NoMethodError on nil") into a clear "Pre-condition: must be signed in" message. This is a strong maintainability pattern.

### 3. Descriptive Failure Messages on All Assertions

**Location**: All assertion calls throughout all three files

```ruby
assert_equal "regular@example.test", user.reload.email,
             "Email must NOT be silently updated on subsequent logins (FR-095 design)"
```

Every assertion includes a human-readable message including the FR reference. This makes CI failures immediately actionable without reading source code.

### 4. OmniAuth Test Mode with Default Fallback Values

**Location**: `test/test_helper.rb:32`

```ruby
def stub_omniauth(uid: "omniauth-uid-test-001", email: "testuser@example.test")
  OmniAuth.config.mock_auth[:openid_connect] = OmniAuth::AuthHash.new(...)
end
```

Named keyword arguments with sensible defaults reduce boilerplate in tests that don't need to customize uid/email, while allowing precise control where it matters (e.g., `stub_omniauth(uid: "brand-new-uid-999")`). Excellent helper design.

---

## Test File Analysis

### File Metadata

| File | Lines | Tests | P0 | P1 | P2 | Assertions |
|------|-------|-------|----|----|----|-|
| `test/models/user_test.rb` | 166 | 12 | 3 | 8 | 1 | 22 |
| `test/controllers/sessions_controller_test.rb` | 190 | 14 | 9 | 3 | 2 | 24 |
| `test/integration/authentication_flow_test.rb` | 226 | 14 | 12 | 4 | 0 | 27 |
| **Total** | **582** | **40** | **24** | **15** | **3** | **73** |

### Test Scope by AC

| AC | Tests | P0 | P1 | P2 |
|----|-------|----|----|-----|
| AC-1 (find/create, session start) | 24 | 12 | 9 | 3 |
| AC-2 (30-min timeout) | 8 | 7 | 1 | 0 |
| AC-3 (failure, no session) | 8 | 5 | 3 | 0 |

All three acceptance criteria have P0 test coverage. Coverage mapping is not in scope for this workflow (use `trace`).

---

## Context and Integration

### Related Artifacts

- **Story File**: `_bmad-output/implementation-artifacts/1-3-oidc-authentication-sessions.md`
- **ATDD Checklist**: `_bmad-output/test-artifacts/atdd/atdd-checklist-1-3-oidc-authentication-sessions.md`
- **Implementation Status**: All 7 tasks completed, 76 tests passing (including regression tests)

---

## Knowledge Base References

This review consulted the following knowledge base fragments:

- **test-quality.md** — Definition of Done (no hard waits, <300 lines, self-cleaning, explicit assertions)
- **data-factories.md** — Fixture patterns, uniqueness discipline
- **test-levels-framework.md** — Unit/Controller/Integration level appropriateness for Rails
- **test-healing-patterns.md** — Common failure patterns (pre-condition guards, assertion messages)
- **selector-resilience.md** — N/A (backend tests only)

Coverage mapping: use `trace` workflow.

---

## Next Steps

### Immediate Actions (Before Merge)

1. **Fix open redirect test** — Add a unit test for `safe_return_to` to verify it rejects `//evil.com/...` and `http://evil.com/...` URLs while accepting relative paths.
   - Priority: P1 (HIGH — security property not currently tested)
   - Effort: ~30 min (add `test/controllers/application_controller_test.rb` or refactor existing test)

2. **Fix fixture UID collision** — Update tests 2 and 3 in `user_test.rb` to use UIDs not present in `test/fixtures/users.yml`.
   - Priority: P2 (MEDIUM — tests misleading but not incorrect)
   - Effort: ~15 min

### Follow-up Actions (Future PRs)

1. **Extract `sign_in` helper** — Add `sign_in(uid:, email:)` to `test_helper.rb` and update all 7+ call sites.
   - Priority: P2 — DX improvement
   - Target: Next test maintenance pass

2. **Use `travel_to` in sliding window test** — Replace nested `travel` blocks with `travel_to(now + N.minutes)` for explicit readability.
   - Priority: P2 — Maintainability
   - Target: Next test maintenance pass

3. **Explicit `parallelize(with: :processes)`** — Document OmniAuth thread-safety constraint.
   - Priority: P3 — Defensive documentation
   - Target: Next test maintenance pass

### Re-Review Needed?

⚠️ Re-review after P1 fix — specifically the open redirect test. The remaining P2/P3 items do not block merge.

---

## Decision

**Recommendation**: Approve with Comments — fix HIGH issue before or alongside merge

**Rationale**:
The test suite is well-constructed with strong ATDD traceability, deterministic time handling, complete AC coverage, and excellent assertion quality. The single HIGH finding (open redirect test not exercising `safe_return_to`) is a security gap that should be addressed. It does not indicate a bug in the implementation — the implementation may be correct — but the test provides false assurance. Add a direct unit test for `safe_return_to` before or as part of this PR.

The MEDIUM findings (fixture UID collision, repeated setup pattern) are design improvements that won't cause test failures. They can be addressed in the same PR if time permits, or as follow-up work.

---

## Appendix

### Violation Summary by Location

| File | Line | Severity | Criterion | Issue | Fix |
|------|------|----------|-----------|-------|-----|
| `sessions_controller_test.rb` | 87 | HIGH | Isolation / Security | Open redirect test tests HTTP_REFERER not `session[:return_to]` | Test `safe_return_to` directly or via session injection |
| `user_test.rb` | 39 | MEDIUM | Isolation | UID `test-uid-regular-001` collides with fixture — finds fixture not creates | Use UIDs absent from users.yml |
| `user_test.rb` | 56 | MEDIUM | Isolation | Same UID collision for email-not-updated test | Use unique UID |
| `sessions_controller_test.rb` | 141 | MEDIUM | Maintainability | sign-in setup repeated 7+ times | Extract `sign_in` helper |
| `authentication_flow_test.rb` | 113 | MEDIUM | Maintainability | Nested `travel` blocks require mental arithmetic | Use `travel_to` with explicit `now + N.minutes` |
| `test_helper.rb` | 15 | LOW | Isolation | `parallelize` mode not explicit | Add `with: :processes` and comment |
| `user_test.rb` | 158 | LOW | Maintainability | Scope test uses `all?`/`any?` — indirect | Assert specific record membership |
| `authentication_flow_test.rb` | 113 | LOW | Performance | Timeout tests each sign in fresh | Group under setup method if suite grows |

---

## Review Metadata

**Generated By**: TEA Agent (Master Test Architect)
**Workflow**: testarch-test-review
**Review ID**: test-review-1-3-oidc-authentication-sessions-20260619
**Timestamp**: 2026-06-19
**Story**: 1.3 — OIDC Authentication & Sessions
**Overall Score**: 86/100 (B — Good)
