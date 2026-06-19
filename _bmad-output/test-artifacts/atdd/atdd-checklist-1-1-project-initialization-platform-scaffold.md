---
stepsCompleted:
  - step-01-preflight-and-context
  - step-02-generation-mode
  - step-03-test-strategy
  - step-04-generate-tests
  - step-04c-aggregate
  - step-05-validate-and-complete
lastStep: step-05-validate-and-complete
lastSaved: '2026-06-18'
storyId: '1.1'
storyKey: 1-1-project-initialization-platform-scaffold
storyFile: >-
  _bmad-output/implementation-artifacts/1-1-project-initialization-platform-scaffold.md
atddChecklistPath: >-
  _bmad-output/test-artifacts/atdd/atdd-checklist-1-1-project-initialization-platform-scaffold.md
generatedTestFiles:
  - test/integration/project_scaffold_test.rb
  - test/system/platform_scaffold_system_test.rb
inputDocuments:
  - _bmad-output/implementation-artifacts/1-1-project-initialization-platform-scaffold.md
  - _bmad-output/test-artifacts/test-design/test-design-epic-1.md
  - _bmad/tea/config.yaml
---

# ATDD Checklist: Story 1.1 — Project Initialization & Platform Scaffold

**Date:** 2026-06-18
**Story:** 1.1 — Project initialization & platform scaffold
**TDD Phase:** RED (all tests skipped until implementation)
**Stack:** Ruby 4.0 / Rails 8 / Minitest (backend — no Playwright/TypeScript)
**Execution Mode:** SEQUENTIAL (API integration → system tests)

---

## Step 1: Preflight & Context Loading

### Stack Detection

- **Detected Stack:** `backend`
- **Reason:** No `package.json`, `playwright.config.*`, `vite.config.*`, or frontend framework indicators found. Story explicitly mandates zero Node/npm. Minitest is the confirmed test framework.
- **Test Framework:** Minitest + Capybara (system tests)

### Prerequisites Satisfied

- [x] Story has clear acceptance criteria (3 ACs with BDD Given/When/Then)
- [x] Backend test config indicators: Rails 8 project structure (Gemfile, config/, test/)
- [x] Story approved: `ready-for-dev` status

### Loaded Artifacts

- Story file: `_bmad-output/implementation-artifacts/1-1-project-initialization-platform-scaffold.md`
- Test design: `_bmad-output/test-artifacts/test-design/test-design-epic-1.md` (Story 1.1 P0/P1 scenarios)
- Config: `_bmad/tea/config.yaml`

---

## Step 2: Generation Mode

**Mode:** AI Generation (backend stack — no browser recording needed)

**Rationale:** Acceptance criteria are clear and all scenarios are infrastructure/configuration tests (file content assertions, database adapter checks, CI YAML parsing, gem presence). No UI interaction recording required.

---

## Step 3: Test Strategy

### Acceptance Criteria → Test Scenarios Mapping

| AC | Scenario | Test Level | Priority | Test Name |
|----|----------|------------|----------|-----------|
| AC-1 | .gitignore excludes master.key | Integration (file assertion) | P0 | `.gitignore excludes master.key` |
| AC-1 | .gitignore excludes credentials/*.key | Integration | P0 | `.gitignore excludes credentials key files` |
| AC-1 | .gitignore excludes .env* | Integration | P0 | `.gitignore excludes .env files` |
| AC-1 | .gitignore excludes *.pem | Integration | P0 | `.gitignore excludes .pem files` |
| AC-1 | Rails boots with PostgreSQL | Integration | P1 | `database adapter is PostgreSQL` |
| AC-1 | Timezone set to Bangkok | Integration | P1 | `application is configured for Bangkok timezone` |
| AC-1 | Default locale is en | Integration | P1 | `application default locale is English` |
| AC-1 | Available locales include en, th | Integration | P1 | `application available locales include English and Thai` |
| AC-1 | daisyui.mjs committed (no CDN) | Integration | P1 | `daisyui.mjs is committed to app/assets/tailwind` |
| AC-1 | daisyui-theme.mjs committed (no CDN) | Integration | P1 | `daisyui-theme.mjs is committed to app/assets/tailwind` |
| AC-1 | application.css imports correct | Integration | P1 | `application.css imports tailwindcss and daisyUI plugins` |
| AC-1 | No node_modules present | Integration | P1 | `no node_modules directory exists at project root` |
| AC-1 | No package.json present | Integration | P1 | `package.json does not exist at project root` |
| AC-1 | Gemfile has runtime gems | Integration | P1 | `Gemfile includes required runtime gems` |
| AC-1 | Gemfile has dev/test gems | Integration | P1 | `Gemfile includes required development/test gems` |
| AC-1 | No forbidden gems (RSpec, Redis) | Integration | P1 | `Gemfile does not include forbidden gems` |
| AC-1 | btree_gist migration exists | Integration | P1 | `btree_gist extension migration exists` |
| AC-1 | btree_gist enabled in schema | Integration | P1 | `btree_gist extension is enabled in the database schema` |
| AC-1 | en.yml locale exists | Integration | P1 | `en.yml locale file exists` |
| AC-1 | th.yml locale stub exists | Integration | P1 | `th.yml locale file exists as key-mirror stub` |
| AC-1 | config/queue.yml exists | Integration | P1 | `config/queue.yml exists for Solid Queue` |
| AC-1 | config/recurring.yml stub exists | Integration | P1 | `config/recurring.yml stub exists` |
| AC-1 | ApplicationMailer scaffolded | Integration | P2 | `ApplicationMailer exists` |
| AC-1 | ApplicationMailer inherits ActionMailer::Base | Integration | P2 | `ApplicationMailer inherits ActionMailer::Base` |
| AC-1 | ApplicationController minimal | Integration | P2 | `ApplicationController exists and inherits ActionController::Base` |
| AC-1 | ApplicationController no Pundit yet | Integration | P2 | `ApplicationController does not include Pundit::Authorization at this stage` |
| AC-2 | CI workflow file exists | Integration | P0 | `CI workflow file exists at .github/workflows/ci.yml` |
| AC-2 | CI includes RuboCop | Integration | P0 | `CI workflow includes RuboCop step` |
| AC-2 | CI includes Brakeman | Integration | P0 | `CI workflow includes Brakeman step` |
| AC-2 | CI includes bundler-audit | Integration | P0 | `CI workflow includes bundler-audit step` |
| AC-2 | CI includes gitleaks | Integration | P0 | `CI workflow includes gitleaks step` |
| AC-2 | CI includes Minitest | Integration | P0 | `CI workflow includes Minitest step` |
| AC-2 | CI includes i18n-tasks | Integration | P0 | `CI workflow includes i18n-tasks health step` |
| AC-3 | config/deploy.yml exists | Integration | P0 | `config/deploy.yml exists` |
| AC-3 | deploy.yml has no hardcoded secrets | Integration | P0 | `config/deploy.yml contains no hardcoded secret values` |
| AC-3 | Dockerfile exists | Integration | P0 | `Dockerfile exists for Kamal 2 deployment` |
| AC-1 | App boots HTTP 200 | System | P0 | `root path responds with HTTP 200` |
| AC-1 | Page has compiled CSS | System | P0 | `rendered page includes Tailwind/daisyUI compiled CSS` |
| AC-1 | No Node/npm in process | System | P0 | `application boots without Node or npm processes` |

### Priority Summary

| Priority | Count |
|----------|-------|
| P0 | 14 |
| P1 | 17 |
| P2 | 4 |
| **Total** | **35** |

### TDD Red Phase Compliance

- All 35 tests use `skip "ATDD RED PHASE — ..."` (Minitest skip pattern)
- All tests assert EXPECTED behavior (not placeholders)
- Tests designed to FAIL before Story 1.1 is implemented
- Activated tests fail first, then pass after implementation (TDD green)

---

## Step 4: Generated Test Files

### Generated Files

1. **`test/integration/project_scaffold_test.rb`**
   - Class: `ProjectScaffoldTest < ActiveSupport::TestCase`
   - 32 test methods (P0: 11, P1: 17, P2: 4) — all skipped
   - Covers: AC-1 (file structure, gems, config, gitignore, daisyUI, i18n, btree_gist, queue, mailer, controller) + AC-2 (CI YAML) + AC-3 (deploy config)

2. **`test/system/platform_scaffold_system_test.rb`**
   - Class: `PlatformScaffoldSystemTest < ApplicationSystemTestCase`
   - 3 test methods (P0: 3) — all skipped
   - Covers: AC-1 smoke boot test (Capybara, HTTP 200, CSS render, no Node)

### Fixture Needs

- No custom fixtures needed for Story 1.1 — tests are file/config assertions or system boot checks
- `ApplicationSystemTestCase` (Rails default) required for system tests
- `test_helper.rb` (Rails default) required for integration tests

---

## Step 5: Validation

### Checklist Validation

- [x] Prerequisites satisfied (story has ACs, backend stack detected, Minitest framework)
- [x] All test files created at correct paths under `test/`
- [x] All tests use `skip "ATDD RED PHASE — ..."` (Minitest skip, not `test.skip()` which is Playwright)
- [x] All tests assert expected behavior with specific assertions (not `assert true`)
- [x] Story metadata captured: storyId, storyKey, storyFile, atddChecklistPath
- [x] generatedTestFiles list is complete and deterministic
- [x] No temp artifacts in random locations (checklist in `_bmad-output/test-artifacts/atdd/`)
- [x] No orphaned browser sessions (system tests: no recording attempted, no running app required at generation time)
- [x] Test levels match detected stack: Integration + System (backend/Rails — no Playwright API/E2E TypeScript)

### Assumptions & Risks

1. **`root_path` undefined:** System tests assume the app has a root route. Story 1.1 generates a Rails 8 app with a default route. If missing, the system test will fail with `NameError` — acceptable (red phase).
2. **`page.status_code` availability:** Requires Capybara rack-test or Selenium driver configured in `ApplicationSystemTestCase`. Story 1.1 scaffold includes capybara + selenium-webdriver gems.
3. **Database connection in test:** `database adapter is PostgreSQL` test assumes test DB is configured. During red phase (no app generated yet), this will raise `ActiveRecord::ConnectionNotEstablished` — correct red phase failure.

---

## Next Steps (Task-by-Task Activation)

During implementation of each Story 1.1 task:

1. Remove the `skip` line from the relevant test(s)
2. Run: `bundle exec rails test test/integration/project_scaffold_test.rb`
3. Verify the activated test FAILS first (red phase confirmed)
4. Implement the feature (the task)
5. Run tests again — verify PASS (green phase)
6. Commit the passing tests

### Activation Map

| Task | Remove skip from |
|------|-----------------|
| Task 1: Generate Rails 8 app | `database adapter is PostgreSQL`, `application is configured for Bangkok timezone`, `application default locale is English` |
| Task 2: Add daisyUI no-Node | `daisyui.mjs committed`, `daisyui-theme.mjs committed`, `application.css imports tailwindcss`, `no node_modules`, `no package.json`, system tests |
| Task 3: Configure Gemfile | `Gemfile includes required runtime gems`, `Gemfile includes required development/test gems`, `Gemfile does not include forbidden gems` |
| Task 4: Set up .gitignore | All 4 `.gitignore` tests |
| Task 5: GitHub Actions CI | All 7 CI workflow tests |
| Task 6: Kamal 2 + Thruster deploy | All 3 deploy config tests |
| Task 7: btree_gist migration | `btree_gist extension migration exists`, `btree_gist extension is enabled in the database schema` |
| Task 8: i18n structure | `en.yml locale file exists`, `th.yml locale file exists`, `application available locales include English and Thai` |
| Task 9: Solid Queue + scaffold | `config/queue.yml`, `config/recurring.yml`, `ApplicationMailer` tests, `ApplicationController` tests |
| Task 10: Smoke test boot | `root path responds with HTTP 200`, `rendered page includes Tailwind/daisyUI compiled CSS`, `application boots without Node or npm processes` |

---

## ATDD Artifacts

- **Checklist:** `_bmad-output/test-artifacts/atdd/atdd-checklist-1-1-project-initialization-platform-scaffold.md`
- **Integration tests:** `test/integration/project_scaffold_test.rb`
- **System tests:** `test/system/platform_scaffold_system_test.rb`

**Next Workflow:** `dev-story` (implement Story 1.1) → activate tests task by task → `automate` (after implementation, for CI wiring)
