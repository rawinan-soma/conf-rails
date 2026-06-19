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
storyId: '1.2'
storyKey: 1-2-core-design-system-viewcomponent-ui-library
storyFile: >-
  _bmad-output/implementation-artifacts/1-2-core-design-system-viewcomponent-ui-library.md
atddChecklistPath: >-
  _bmad-output/test-artifacts/atdd/atdd-checklist-1-2-core-design-system-viewcomponent-ui-library.md
generatedTestFiles:
  - test/components/button_component_test.rb
  - test/components/form_field_component_test.rb
  - test/components/select_component_test.rb
  - test/components/toggle_component_test.rb
  - test/components/status_badge_component_test.rb
  - test/components/toast_component_test.rb
  - test/components/empty_state_component_test.rb
  - test/components/modal_component_test.rb
  - test/components/skeleton_component_test.rb
  - test/components/read_only_field_component_test.rb
  - test/components/admin_sidebar_component_test.rb
  - test/integration/design_system_test.rb
inputDocuments:
  - _bmad-output/implementation-artifacts/1-2-core-design-system-viewcomponent-ui-library.md
  - _bmad/tea/config.yaml
---

# ATDD Checklist: Story 1.2 — Core Design System & ViewComponent UI Library

**Date:** 2026-06-19
**Story:** 1.2 — Core design system & ViewComponent UI library
**TDD Phase:** RED (all tests skipped until implementation)
**Stack:** Ruby 4.0 / Rails 8 / Minitest + ViewComponent::TestCase (backend — no Playwright/TypeScript)
**Execution Mode:** SEQUENTIAL (component unit tests → integration tests)

---

## Step 1: Preflight & Context Loading

### Stack Detection

- **Detected Stack:** `backend`
- **Reason:** No `package.json`, `playwright.config.*`, `vite.config.*`, or frontend framework indicators found. Story explicitly mandates zero Node/npm. Minitest is the confirmed test framework. ViewComponent::TestCase provides component-level rendering tests.
- **Test Framework:** Minitest + ViewComponent::TestCase

### Prerequisites Satisfied

- [x] Story has clear acceptance criteria (3 ACs with BDD Given/When/Then)
- [x] Backend test config: Rails 8 project structure (`Gemfile`, `config/`, `test/`)
- [x] `view_component (4.12.0)` gem confirmed in `Gemfile.lock`
- [x] Story status: `ready-for-dev`
- [x] Depends on Story 1.1 (done / committed at baseline `4741d56`)

### Loaded Artifacts

- Story file: `_bmad-output/implementation-artifacts/1-2-core-design-system-viewcomponent-ui-library.md`
- TEA config: `_bmad/tea/config.yaml`
- Existing test patterns: `test/integration/project_scaffold_test.rb` (Story 1.1 reference)

---

## Step 2: Generation Mode

**Mode:** AI generation (acceptance criteria are clear; all scenarios are component rendering, accessibility, and configuration — no browser interaction needed).

---

## Step 3: Test Strategy

### Acceptance Criteria → Test Scenarios

| AC | Test Level | Priority | Scenario |
|----|-----------|----------|----------|
| AC-1 | Integration | P0 | daisyui-theme.mjs defines forest-copper with correct tokens |
| AC-1 | Integration | P0 | Application layout has Google Fonts for Noto Thai |
| AC-1 | Integration | P0 | CSS sets body line-height ≥1.65 (Thai hard minimum) |
| AC-1 | Integration | P1 | CSS defines 14px minimum font size |
| AC-1 | Integration | P1 | CSS defines type scale (display 32px, etc.) |
| AC-1 | Integration | P1 | Layout has theme-color meta tag for mobile |
| AC-1 | Integration | P1 | Layout includes flash/toast container |
| AC-1 | Integration | P2 | CSS defines radius/shadow CSS custom properties |
| AC-2 | Component | P0 | ButtonComponent renders primary variant |
| AC-2 | Component | P0 | ButtonComponent loading state disables + spinner |
| AC-2 | Component | P0 | ButtonComponent renders as `<a>` when href given |
| AC-2 | Component | P0 | FormFieldComponent label always visible above input |
| AC-2 | Component | P0 | FormFieldComponent error state with aria-describedby |
| AC-2 | Component | P0 | FormFieldComponent no placeholder-as-label (WCAG) |
| AC-2 | Component | P0 | ModalComponent role=dialog, aria-modal=true, aria-labelledby |
| AC-2 | Component | P0 | StatusBadgeComponent shows text label (not color-only) |
| AC-2 | Component | P0 | ToastComponent shows prefix/icon (not color-only) |
| AC-2 | Component | P0 | ViewComponent infrastructure (ApplicationComponent, initializer) |
| AC-2 | Component | P1 | ButtonComponent secondary/ghost variants |
| AC-2 | Component | P1 | ButtonComponent disabled state |
| AC-2 | Component | P1 | ButtonComponent tap target (element rendered for visual QA) |
| AC-2 | Component | P1 | FormFieldComponent required indicator (*) |
| AC-2 | Component | P1 | SelectComponent label + options rendering |
| AC-2 | Component | P1 | SelectComponent label/select for/id association |
| AC-2 | Component | P1 | SelectComponent blank option |
| AC-2 | Component | P1 | SelectComponent error state |
| AC-2 | Component | P1 | ToggleComponent label always visible (WCAG) |
| AC-2 | Component | P1 | ToggleComponent checked/unchecked state |
| AC-2 | Component | P1 | ToggleComponent daisyUI toggle class |
| AC-2 | Component | P1 | ModalComponent Stimulus controller attribute |
| AC-2 | Component | P1 | ModalComponent title rendering |
| AC-2 | Component | P1 | ModalComponent danger variant |
| AC-2 | Component | P1 | ReadOnlyFieldComponent label + value |
| AC-2 | Component | P1 | ReadOnlyFieldComponent not focusable as input |
| AC-2 | Component | P1 | ReadOnlyFieldComponent visually distinct from FormFieldComponent |
| AC-2 | Component | P1 | SkeletonComponent all four variants |
| AC-2 | Component | P1 | EmptyStateComponent message + action link |
| AC-2 | Component | P1 | EmptyStateComponent no large illustrations |
| AC-2 | Component | P1 | AdminSidebarComponent nav items rendered |
| AC-2 | Component | P1 | AdminSidebarComponent active item highlighted |
| AC-2 | Integration | P1 | Admin layout file exists |
| AC-2 | Component | P2 | ButtonComponent forwards data-attributes |
| AC-2 | Component | P2 | ButtonComponent method kwarg for turbo |
| AC-2 | Component | P2 | ButtonComponent additional CSS classes merged |
| AC-2 | Component | P2 | ToastComponent Stimulus controller for auto-dismiss |
| AC-3 | Integration | P0 | en.yml has common.cancel/confirm/close/loading keys |
| AC-3 | Integration | P0 | en.yml has components.status_badge.* keys |
| AC-3 | Integration | P0 | th.yml mirrors en.yml key-for-key (sampled check) |
| AC-3 | Integration | P1 | en.yml has components.modal/toast/empty_state keys |
| AC-3 | Integration | P1 | No hardcoded strings in component .html.erb templates |

### Test Levels Selected

- **Component unit tests** (`test/components/` with `ViewComponent::TestCase`): Primary test type for AC-2 — rendering, accessibility attributes, variant behavior.
- **Integration tests** (`test/integration/` with `ActiveSupport::TestCase`): For AC-1 (file system assertions on theme/CSS/layout) and AC-3 (I18n key presence).
- **No E2E/Playwright**: Zero Node architecture; no browser-based testing. Accessibility is enforced through structural unit tests + WCAG assertions.

### Priority Matrix

| Priority | Count | Coverage |
|----------|-------|----------|
| P0 | 18 | Critical: ARIA, no-color-alone meaning, Thai typography, theme tokens |
| P1 | 28 | Important: All component variants, i18n structure |
| P2 | 9 | Nice-to-have: Edge cases, CSS details |
| Total | 55 | 3 ACs fully covered |

---

## Step 4: Generated Test Files (TDD RED PHASE)

### Component Unit Tests (`ViewComponent::TestCase`)

| File | Tests | ACs |
|------|-------|-----|
| `test/components/button_component_test.rb` | 12 | AC-2 |
| `test/components/form_field_component_test.rb` | 7 | AC-2 |
| `test/components/select_component_test.rb` | 6 | AC-2 |
| `test/components/toggle_component_test.rb` | 6 | AC-2 |
| `test/components/status_badge_component_test.rb` | 6 | AC-2 |
| `test/components/toast_component_test.rb` | 6 | AC-2 |
| `test/components/empty_state_component_test.rb` | 6 | AC-2 |
| `test/components/modal_component_test.rb` | 8 | AC-2 |
| `test/components/skeleton_component_test.rb` | 6 | AC-2 |
| `test/components/read_only_field_component_test.rb` | 4 | AC-2 |
| `test/components/admin_sidebar_component_test.rb` | 6 | AC-2 |

### Integration Tests (`ActiveSupport::TestCase`)

| File | Tests | ACs |
|------|-------|-----|
| `test/integration/design_system_test.rb` | 23 | AC-1, AC-2, AC-3 |

### TDD Red Phase Compliance

- [x] All 83 tests use Minitest `skip` (red-phase scaffold)
- [x] All tests assert EXPECTED behavior (will fail until feature implemented)
- [x] No placeholder assertions (`assert true` style)
- [x] Priority tags `[P0]`, `[P1]`, `[P2]` included in test names

---

## Step 5: Validation

### Checklist

- [x] Prerequisites satisfied (story approved, ViewComponent gem present, Story 1.1 baseline exists)
- [x] Test files created in correct locations (`test/components/`, `test/integration/`)
- [x] All tests use `skip` — TDD red phase compliant
- [x] Acceptance criteria fully covered (AC-1, AC-2, AC-3)
- [x] Accessibility tests: ARIA roles, aria-modal, aria-labelledby, aria-describedby, color-not-alone
- [x] No orphaned browser sessions (no Playwright used)
- [x] Story metadata and handoff paths captured in frontmatter

### Key Risks / Assumptions

1. **ViewComponent::TestCase API**: Assumes `render_inline`, `assert_selector`, `assert_text`, `page.find`, `page.html` API as provided by `view_component 4.12.0`. Verify against gem docs if tests raise `NoMethodError`.
2. **Minitest `skip` in `test.skip` pattern**: Ruby uses `skip "message"` (not `test.skip()`). All tests in this suite use the correct Ruby pattern.
3. **I18n key paths**: Tests reference `components.status_badge.registered`, `components.toast.success_prefix`, etc. — these match the Dev Notes key structure exactly. If keys are renamed, update both en.yml and tests together.
4. **CSS assertion heuristics**: The `design_system_test.rb` regex assertions (`line-height: 1.65`, `32px`, etc.) are structural checks. The definitive CI gate is `bundle exec rails tailwindcss:build` building without errors.
5. **No color contrast tests**: Contrast ratio (copper on cream ≥4.5:1) cannot be unit-tested in Minitest. This must be verified manually or via Lighthouse CI (future story).
6. **Focus ring visibility**: ≥2px `green-500` focus ring is a CSS concern; its presence is verified structurally in component tests but the visual quality requires browser QA.

### Activation Instructions

During implementation of each task, activate tests incrementally:

1. Remove `skip "RED PHASE — ..."` from the test(s) for the current task
2. Run: `bundle exec rails test test/components/<component>_test.rb`
3. Verify tests FAIL (red) — confirms the scaffold is correct
4. Implement the component
5. Run tests again — verify they PASS (green)
6. Commit passing tests with the implementation

**To run all component tests:**
```bash
bundle exec rails test test/components/
```

**To run the integration suite:**
```bash
bundle exec rails test test/integration/design_system_test.rb
```

**To run the full test suite:**
```bash
bundle exec rails test
```

**Quality gates (must pass before story closure):**
```bash
bundle exec rubocop            # 0 offenses
bundle exec brakeman --no-pager  # 0 high/critical
bundle exec i18n-tasks health  # 0 errors/warnings
bundle exec rails test         # all tests pass
```

### ATDD Artifacts

- Checklist: `_bmad-output/test-artifacts/atdd/atdd-checklist-1-2-core-design-system-viewcomponent-ui-library.md`
- Component tests: `test/components/` (11 files)
- Integration tests: `test/integration/design_system_test.rb`

### Next Recommended Workflow

After implementation is complete and all tests are green:

1. Run `bmad-testarch-automate` to generate a fuller integration/system test harness
2. Run `bmad-dev-story` to close out the story and update sprint status
