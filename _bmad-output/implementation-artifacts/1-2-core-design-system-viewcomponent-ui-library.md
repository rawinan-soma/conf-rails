---
baseline_commit: 4741d56
---

# Story 1.2: Core design system & ViewComponent UI library

Status: ready-for-dev

## Story

As an internal user,
I want a branded, accessible, Thai-ready interface shell and reusable components,
so that every screen is visually consistent and usable in Thai.

## Acceptance Criteria

1. **Given** the theme and fonts, **when** any page renders, **then** it uses the "Forest & Copper" design tokens (green-700 primary, copper accent, cream backgrounds) and Noto Serif/Sans Thai fonts with body line-height ≥1.65 and no text below 14px.

2. **Given** the component library, **when** a developer uses a base component, **then** button/form-field/select/toggle/badge/modal/toast/skeleton/empty-state render per DESIGN.md specs, with visible focus rings (≥2px green-500), always-visible labels, and no color-alone meaning (WCAG 2.1 AA).

3. **Given** all user-facing copy, **when** a string is rendered, **then** it comes from an I18n key (lazy view-scoped `t('.key')`), `th.yml` mirrors `en.yml` key-for-key, and `bundle exec i18n-tasks health` passes in CI.

## Tasks / Subtasks

- [ ] Task 1: Implement "Forest & Copper" daisyUI theme in `daisyui-theme.mjs` (AC: #1)
  - [ ] Replace the placeholder `daisyui-theme.mjs` with the full custom daisyUI v5 theme definition
  - [ ] Map all color tokens per DESIGN.md: green-900/700/500/200/100, copper, copper-light, copper-bg, cream, cream-100/200, card, border, ink, ink-2, ink-3, and semantic status colors (success/warning/danger with -bg variants)
  - [ ] Set daisyUI CSS variable names to match the canonical palette (e.g. `--color-primary: #2D6A4F` for green-700, `--color-secondary: #B5651D` for copper)
  - [ ] Verify `bin/dev` (or `rails tailwindcss:build`) outputs the theme with no errors

- [ ] Task 2: Configure Thai typography via Google Fonts (AC: #1)
  - [ ] Add Google Fonts link for Noto Serif Thai + Noto Sans Thai to `app/views/layouts/application.html.erb` `<head>`
  - [ ] Set CSS: heading/display → `font-family: 'Noto Serif Thai', serif`; body/UI → `font-family: 'Noto Sans Thai', sans-serif`
  - [ ] Set body `line-height: 1.65` (≥1.65 is non-negotiable for Thai vowel/tone marks)
  - [ ] Set minimum font size: 14px is the hard floor — never go below
  - [ ] Apply the type scale from DESIGN.md: display 32px, h1 28px, h2 22px, h3 18px, body 16px, small 14px
  - [ ] Set these as custom CSS properties or Tailwind utilities in `application.css`

- [ ] Task 3: Update application layout for app shell (AC: #1, #2)
  - [ ] Update `app/views/layouts/application.html.erb` to include: flash message area (for toast), Google Fonts, page title, and yield regions
  - [ ] Remove the generated placeholder `<main class="container mx-auto mt-28 px-5 flex">` — replace with semantic `<main>` that matches the app shell structure
  - [ ] Add flash container that renders `ToastComponent` when flash messages are present
  - [ ] Add `<meta name="theme-color">` reflecting green-900 for mobile branding

- [ ] Task 4: Initialize ViewComponent infrastructure (AC: #2)
  - [ ] Create `config/initializers/view_component.rb` with `ViewComponent::Base.config.use_linting = !Rails.env.test?` (or equivalent)
  - [ ] Create `app/components/application_component.rb` as the base class: `class ApplicationComponent < ViewComponent::Base; end`
  - [ ] Confirm `app/components/` directory exists (was NOT created in Story 1.1 — create it now)

- [ ] Task 5: Build `ButtonComponent` (AC: #2)
  - [ ] Create `app/components/button_component.rb` and `app/components/button_component.html.erb`
  - [ ] Variants: `:primary` (green-700 fill, white text, shadow-1), `:secondary` (card fill, border stroke, ink text), `:ghost` (text-only, copper accent for highlight actions)
  - [ ] Loading state: `loading:` kwarg renders spinner + disables button (daisyUI `loading` class)
  - [ ] All buttons: radius `md` (10px), tap target ≥44px (pad to ensure), visible focus ring
  - [ ] Disabled state: cream-200 fill + ink-3 text
  - [ ] Accept `type:`, `href:`, `method:`, `data:`, `class:` kwargs; render as `<a>` if `href:` provided
  - [ ] I18n: button label passed as argument, never hardcoded inside component

- [ ] Task 6: Build `FormFieldComponent` (AC: #2)
  - [ ] Create `app/components/form_field_component.rb` and `app/components/form_field_component.html.erb`
  - [ ] Structure: label (always visible above, never placeholder-only) → input → error message slot
  - [ ] Styling: card fill, border stroke (#E0DBD3), radius sm (6px); focus → green-500 ring ≥2px
  - [ ] Error state: danger border + error message below field
  - [ ] Accept `form:`, `attribute:`, `label:`, `hint:`, `error:` kwargs
  - [ ] Required fields: show `*` indicator after label

- [ ] Task 7: Build `SelectComponent` (AC: #2)
  - [ ] Create `app/components/select_component.rb` and `app/components/select_component.html.erb`
  - [ ] Same shell as FormFieldComponent (card fill, border, radius sm, focus green-500 ring)
  - [ ] Accept `form:`, `attribute:`, `label:`, `options:`, `include_blank:`, `error:` kwargs
  - [ ] Used for Title picker and Meal-type picker in later stories — design for those use cases

- [ ] Task 8: Build `ToggleComponent` (AC: #2)
  - [ ] Create `app/components/toggle_component.rb` and `app/components/toggle_component.html.erb`
  - [ ] On state: green-700; off state: ink-3/cream-200 — use daisyUI toggle classes
  - [ ] Label always visible beside toggle (never label-only-via-color)
  - [ ] Used for: catering toggle, registration-enable toggle (Stories 2.4, 3.1)
  - [ ] Accept `form:`, `attribute:`, `label:`, `checked:` kwargs

- [ ] Task 9: Build `ReadOnlyFieldComponent` (AC: #2)
  - [ ] Create `app/components/read_only_field_component.rb` and `app/components/read_only_field_component.html.erb`
  - [ ] Styling: cream-100 fill, ink-2 text, no border emphasis, NOT focusable as input
  - [ ] Visually distinct from editable FormFieldComponent (different bg color is the key differentiator)
  - [ ] Used for: event contact (organizer name + phone, pre-filled from profile) on Booking Form
  - [ ] Accept `label:`, `value:` kwargs

- [ ] Task 10: Build `StatusBadgeComponent` (AC: #2)
  - [ ] Create `app/components/status_badge_component.rb` and `app/components/status_badge_component.html.erb`
  - [ ] Pill shape, radius sm; always shows TEXT LABEL — never color-only
  - [ ] MVP statuses: `:registered` (green-100 bg, green-700 text), `:cancelled` (cream-200 bg, ink-2 text)
  - [ ] Skeleton for other statuses that may come in later epics
  - [ ] Thai line-height rule applies: ≥1.65 even in badge (compact context = 1.5 minimum)
  - [ ] Accept `status:` kwarg (symbol)

- [ ] Task 11: Build `ModalComponent` (AC: #2)
  - [ ] Create `app/components/modal_component.rb` and `app/components/modal_component.html.erb`
  - [ ] Styling: card surface, radius lg (16px), shadow-3, green-900 header band
  - [ ] Must support: title slot, body slot, confirm/cancel actions
  - [ ] Primary use: destructive confirm modal (room deactivation in Story 2.6) — design with "danger" variant in mind
  - [ ] Use daisyUI modal class + Stimulus controller for open/close
  - [ ] Focus trap when open (accessibility requirement)
  - [ ] Accept `title:`, `id:` kwargs; use slots for body content and footer actions

- [ ] Task 12: Build `ToastComponent` (AC: #2)
  - [ ] Create `app/components/toast_component.rb` and `app/components/toast_component.html.erb`
  - [ ] Position: top-right; auto-dismisses (use Stimulus + setTimeout or daisyUI toast)
  - [ ] Triggered from Flash messages in the layout (see Task 3)
  - [ ] Accept `message:`, `type:` (`:success`, `:error`, `:info`) kwargs
  - [ ] No color-alone meaning: icon or prefix word in addition to color

- [ ] Task 13: Build `SkeletonComponent` (AC: #2)
  - [ ] Create `app/components/skeleton_component.rb` and `app/components/skeleton_component.html.erb`
  - [ ] Grey-green shimmer blocks shaped like content
  - [ ] Variants for: `:card`, `:list_row`, `:table_row`, `:calendar_grid` (placeholder shapes only)
  - [ ] Used as the loading pattern for calendar, lists, dashboard in later stories
  - [ ] Accept `variant:`, `rows:` kwargs

- [ ] Task 14: Build `EmptyStateComponent` (AC: #2)
  - [ ] Create `app/components/empty_state_component.rb` and `app/components/empty_state_component.html.erb`
  - [ ] Layout: one calm line + single primary action — NO large illustrations
  - [ ] Accept `message:`, `action_label:`, `action_path:` kwargs
  - [ ] Example usage: empty organizer dashboard → "No bookings yet" + "Create booking" (primary button)

- [ ] Task 15: Build admin shell layout (`AdminSidebarComponent`) (AC: #2)
  - [ ] Create `app/components/admin_sidebar_component.rb` and `app/components/admin_sidebar_component.html.erb`
  - [ ] Styling: green-900 background, light text (white/cream), active item highlighted (green-700 or copper accent)
  - [ ] Navigation items passed as array of `{label:, path:, active:}` hashes (or use slots)
  - [ ] Internal app shell only — never shown to public/unauthenticated visitors
  - [ ] Create `app/views/layouts/admin.html.erb` that includes the sidebar
  - [ ] The admin layout will be wired to `Admin::` controllers in Story 2.1+

- [ ] Task 16: Expand i18n structure for UI components (AC: #3)
  - [ ] Add component-level I18n keys to `config/locales/en.yml`: common UI strings (e.g. `common.loading`, `common.cancel`, `common.confirm`, `common.close`, `common.empty_state`, etc.)
  - [ ] Mirror all new keys in `config/locales/th.yml` key-for-key (Thai values filled by Rawinan later)
  - [ ] All components must use `t('.key')` for any user-visible text inside them (lazy view-scoped or component-scoped)
  - [ ] Run `bundle exec i18n-tasks health` — must pass with 0 errors

- [ ] Task 17: Write component tests (AC: #2)
  - [ ] Create `test/components/` directory
  - [ ] Write Minitest unit tests for each component using `ViewComponent::TestCase`
  - [ ] Test all variants and kwargs for: ButtonComponent, FormFieldComponent, SelectComponent, ToggleComponent, StatusBadgeComponent, ToastComponent, EmptyStateComponent
  - [ ] Test accessibility attributes: focus rings, labels, aria attributes
  - [ ] Run `bundle exec rails test test/components/` — all tests must pass
  - [ ] No RSpec — Minitest only (architectural decision)

- [ ] Task 18: CI & quality gate verification (AC: #3)
  - [ ] Run `bundle exec rubocop` — 0 offenses (Rails Omakase)
  - [ ] Run `bundle exec brakeman --no-pager` — 0 high/critical warnings
  - [ ] Run `bundle exec i18n-tasks health` — 0 errors/warnings
  - [ ] Run `bundle exec rails test` — all tests pass
  - [ ] Verify no user-facing literal strings remain in component `.html.erb` files — all text via `t('.key')` or passed as kwargs

## Dev Notes

### What Story 1.1 Created (Build On This — Do NOT Reinvent)

Story 1.1 established the full project scaffold. Key facts:

- **Rails 8.1.3** with Ruby 4.0.5 (YJIT in prod)
- **daisyUI v5.5.23** files committed to `app/assets/tailwind/daisyui.mjs` and `app/assets/tailwind/daisyui-theme.mjs`
- `app/assets/tailwind/application.css` already has all four directives — do NOT rewrite:
  ```css
  @import "tailwindcss";
  @source not "./daisyui{,*}.mjs";
  @plugin "./daisyui.mjs";
  @plugin "./daisyui-theme.mjs";
  ```
- `config/locales/en.yml` and `th.yml` exist with one key (`mailers.sender_display`) — extend, don't replace
- `app/controllers/application_controller.rb` minimal — do NOT add `verify_authorized` here (that's Story 1.4)
- `app/mailers/application_mailer.rb` scaffolded — do NOT modify
- `app/views/layouts/application.html.erb` exists — update it (Task 3), don't replace
- **`app/components/` directory does NOT exist yet** — create it in Task 4
- `view_component` gem is in the Gemfile and bundled; no re-installation needed

### "Forest & Copper" Theme — Canonical Tokens

Map these exactly in `daisyui-theme.mjs` as a custom daisyUI v5 theme:

```
Primary colors:
  green-900: #1B4332   sidebar, brand mark, strongest headings
  green-700: #2D6A4F   primary action / primary brand (daisyUI --color-primary)
  green-500: #40916C   links, active states, focus rings
  green-200: #95D5B2   subtle fills, hover backgrounds
  green-100: #D8F3DC   available slot fill, success bg

Copper accent (daisyUI --color-secondary):
  copper:       #B5651D   secondary accent / highlights
  copper-light: #E8A96A
  copper-bg:    #FDF3E7   warm accent surface

Surfaces / neutrals:
  cream:     #FAFAF7   page background (daisyUI --color-base-100)
  cream-100: #F0EDE6   alt surface / striped rows
  cream-200: #E8E3DA   deeper surface / disabled fill
  card:      #FFFFFF   card / panel surface
  border:    #E0DBD3   hairline borders, dividers

Text:
  ink:   #1C1C1C   primary text
  ink-2: #5A5A5A   secondary text
  ink-3: #9A9A9A   tertiary / placeholder / disabled

Status:
  success:    #2D6A4F   (= green-700)
  success-bg: #D8F3DC   (= green-100)
  warning:    #B5651D   (= copper)
  warning-bg: #FDF3E7   (= copper-bg)
  danger:     #B3261E
  danger-bg:  #FBEAE9
```

**Accessibility WARNING from DESIGN.md:** Verify at build — copper (#B5651D) on cream (#FAFAF7) and green-500 (#40916C) on white (#FFFFFF). If either falls short of 4.5:1 for body text, darken toward copper or green-700, or reserve lighter shade for large text only.

### daisyUI v5 Theme Format

daisyUI v5 uses a different theme format than v4. The `daisyui-theme.mjs` plugin file must export a valid daisyUI v5 `addBase` / `addUtilities` definition. The canonical approach for v5 custom themes uses CSS custom properties in the format daisyUI v5 expects:

```js
// daisyui-theme.mjs — Forest & Copper custom theme
export default {
  name: "forest-copper",
  // daisyUI v5 expects colors as oklch or hex
  // Map to daisyUI's semantic color names
  default: true, // set as default theme
  prefersDark: false,
  colorScheme: "light",
  // ... token map
}
```

Refer to the daisyUI v5 documentation for exact theme object structure. The `daisyui-theme.mjs` file was downloaded from the official release and supports this format. The key is mapping the design tokens to daisyUI's semantic color names (primary, secondary, base-100, etc.).

### Thai Typography — Non-Negotiable Rules

1. **Fonts:** Load from Google Fonts CDN:
   - Noto Serif Thai (headings/display, weights 400/600/700)
   - Noto Sans Thai (body/UI/labels, weights 400/500/600)
2. **Line height:** `1.65` on body — HARD MINIMUM. Thai vowel + tone marks stack above/below baseline and WILL clip without adequate leading.
3. **Minimum size:** 14px. Never smaller. Even in badges, table cells, helper text.
4. **Font sizes (from DESIGN.md prototype):**
   - display: 32px, h1: 28px, h2: 22px, h3: 18px, body: 16px, small: 14px
5. **Embedded TTF:** `app/assets/fonts/` will hold the Noto Sans Thai TTF for Prawn PDF rendering in Story 3.7. Story 1.2 does NOT need to embed it yet — just the web fonts via CDN link.

### ViewComponent Architecture Pattern

```
app/components/
├── application_component.rb          # base class: class ApplicationComponent < ViewComponent::Base; end
├── button_component.rb               # + button_component.html.erb
├── form_field_component.rb           # + form_field_component.html.erb
├── select_component.rb               # + select_component.html.erb
├── toggle_component.rb               # + toggle_component.html.erb
├── read_only_field_component.rb      # + read_only_field_component.html.erb
├── status_badge_component.rb         # + status_badge_component.html.erb
├── modal_component.rb                # + modal_component.html.erb
├── toast_component.rb                # + toast_component.html.erb
├── skeleton_component.rb             # + skeleton_component.html.erb
├── empty_state_component.rb          # + empty_state_component.html.erb
└── admin_sidebar_component.rb        # + admin_sidebar_component.html.erb
```

**Naming rule:** `XxxComponent` in `app/components/` with co-located `.html.erb` template. Never inline daisyUI classes in views — all daisyUI markup lives inside components.

**Base class pattern:**
```ruby
# app/components/application_component.rb
class ApplicationComponent < ViewComponent::Base
end
```

**Component pattern:**
```ruby
# app/components/button_component.rb
class ButtonComponent < ApplicationComponent
  def initialize(label:, variant: :primary, loading: false, type: :button, href: nil, **html_options)
    @label = label
    @variant = variant
    @loading = loading
    @type = type
    @href = href
    @html_options = html_options
  end
end
```

### I18n Rules (CI-Enforced)

- **Lazy scoped keys in ViewComponent:** ViewComponent `t('.key')` resolves relative to the component's translation path. For `ButtonComponent`, use explicit key `t('components.button.loading_text')` or configure the component to set `i18n_scope`. The safest pattern for components is explicit keys (`t('common.cancel')`) rather than lazy dot notation, since ViewComponent's I18n scope resolution differs from standard Rails views. Check `view_component` gem version for exact behavior.
- **No hardcoded strings** in `.html.erb` files — any user-visible text must be an I18n key
- **Component keys live under `components.*` or `common.*`** namespace
- `th.yml` must mirror `en.yml` key-for-key (same structure, Thai values empty/placeholder for now)
- `bundle exec i18n-tasks health` fails CI if any key is missing or unused
- `bundle exec i18n-tasks normalize` — run this after adding keys to keep files sorted

**Minimum keys to add to `en.yml`:**
```yaml
en:
  mailers:
    sender_display: Conf Rails   # already exists
  common:
    loading: "Loading..."
    cancel: "Cancel"
    confirm: "Confirm"
    close: "Close"
    required_field: "required"
    empty_state:
      no_results: "No results found"
  components:
    button:
      loading_text: "Please wait..."
    status_badge:
      registered: "Registered"
      cancelled: "Cancelled"
    modal:
      close_label: "Close dialog"
    toast:
      success_prefix: "Success"
      error_prefix: "Error"
    empty_state:
      default_message: "Nothing here yet"
```

### Spacing / Radius / Elevation (from DESIGN.md)

Apply these as CSS custom properties in `application.css`:
```css
:root {
  --radius-sm: 6px;    /* inputs, badges */
  --radius-md: 10px;   /* buttons, cards */
  --radius-lg: 16px;   /* panels, modals */
  --radius-xl: 20px;   /* large feature cards */
  --shadow-1: 0 1px 2px rgba(27,67,50,0.06);    /* inputs, hairline lift */
  --shadow-2: 0 2px 8px rgba(27,67,50,0.08);    /* card / booking card */
  --shadow-3: 0 8px 24px rgba(27,67,50,0.12);   /* modal / popover / elevated */
}
/* 8px base spacing scale — use Tailwind spacing utilities (p-2=8px, p-4=16px, etc.) */
```

### Components NOT In This Story (Defer to Their Epics)

These are listed in UX-DR3 but implemented in later epics. DO NOT create them now:
- `CalendarSlotComponent` — Story 2.3 (room calendar week scheduler)
- `BookingCardComponent` — Story 2.5 (edit/duplicate/cancel booking)
- `HeatmapCellComponent` — Story 4.1 (utilization heatmap)

### Accessibility (WCAG 2.1 AA — Non-Negotiable)

- **Focus rings:** every interactive element (button, input, select, toggle, modal trigger) must have a visible ≥2px focus ring using `green-500` color — NEVER remove outline without replacement
- **Labels always visible:** no placeholder-as-label pattern. `FormFieldComponent` always renders `<label>` above the input
- **No color-alone meaning:** `StatusBadgeComponent` always shows text label; calendar states use label+pattern (later stories); heatmap cells use count (Story 4.1)
- **Tap targets:** all interactive elements ≥44×44px, especially important on mobile registration pages (public zone) — buttons must have adequate padding
- **Aria:** modal needs `role="dialog"`, `aria-modal="true"`, `aria-labelledby`; form errors need `aria-describedby`
- **Contrast:** copper (#B5651D) on cream — check; green-500 (#40916C) on white — check. If below 4.5:1 for body text, darken or reserve for large text.

### Testing Pattern (Minitest + ViewComponent::TestCase)

```ruby
# test/components/button_component_test.rb
require "test_helper"

class ButtonComponentTest < ViewComponent::TestCase
  def test_renders_primary_button
    render_inline(ButtonComponent.new(label: "Submit", variant: :primary))
    assert_selector "button.btn-primary", text: "Submit"
  end

  def test_loading_state_disables_button
    render_inline(ButtonComponent.new(label: "Submit", loading: true))
    assert_selector "button[disabled]"
  end

  def test_renders_as_link_when_href_given
    render_inline(ButtonComponent.new(label: "Go", href: "/somewhere"))
    assert_selector "a[href='/somewhere']"
  end
end
```

Use `ViewComponent::TestCase` (included with `view_component` gem). Tests live in `test/components/` mirroring `app/components/`.

### What NOT to Do (Anti-Patterns)

- **DO NOT** inline daisyUI classes directly in view `.html.erb` files — they go in component templates only
- **DO NOT** hardcode any user-facing string — always `t('.key')` or kwarg
- **DO NOT** create RSpec tests — Minitest only (architecture decision)
- **DO NOT** add `verify_authorized` to ApplicationController — that's Story 1.4
- **DO NOT** implement CalendarSlotComponent, BookingCardComponent, or HeatmapCellComponent — those belong to their respective epics
- **DO NOT** embed Noto Thai TTF fonts for PDF yet — that's Story 3.7 (Prawn setup)
- **DO NOT** modify `application_mailer.rb` or `Gemfile` — those are already correct
- **DO NOT** use Node/npm for anything — Tailwind uses the standalone CLI; daisyUI is already bundled
- **DO NOT** commit credentials or `.env` files of any kind

### Story 1.1 Review Learnings (Apply Here)

From the Story 1.1 code review, these patterns were corrected — follow the fixed versions:
1. `Procfile.dev` has `jobs: bin/jobs` for Solid Queue — don't touch this
2. `config/database.yml` uses `pool:` key (not `max_connections`) — don't change
3. `config/environments/production.rb` has `config.assume_ssl` and `config.force_ssl` uncommented — don't revert
4. `test/application_system_test_case.rb` exists — require it in system tests

### Project Structure Notes

- **`app/components/` must be created** — this directory was NOT part of Story 1.1 output
- All component `.html.erb` files co-located with their `.rb` class (not in `app/views/`)
- Admin layout: `app/views/layouts/admin.html.erb` (new file) — used by `Admin::` controllers starting Story 2.1
- Test files in `test/components/` mirroring `app/components/`
- No separate JS files needed for basic components — Stimulus controllers (for modal, toast) can be inline or in `app/javascript/controllers/`

### References

- Forest & Copper design tokens: `_bmad-output/planning-artifacts/ux-designs/ux-conference-envocc-2026-06-07/DESIGN.md` §1 and frontmatter
- Component specs: `_bmad-output/planning-artifacts/ux-designs/ux-conference-envocc-2026-06-07/DESIGN.md` §4 (Component styles table)
- Thai typography rules: `_bmad-output/planning-artifacts/ux-designs/ux-conference-envocc-2026-06-07/DESIGN.md` §2 (UXD-007/008)
- Accessibility floor: `_bmad-output/planning-artifacts/ux-designs/ux-conference-envocc-2026-06-07/DESIGN.md` §5 (UXD-022)
- ViewComponent naming and location: `_bmad-output/planning-artifacts/architecture.md` §"Naming Patterns" and §"Components & JS"
- I18n rules: `_bmad-output/planning-artifacts/architecture.md` §"I18n keys" and §"Pattern Categories Defined"
- daisyUI no-Node setup: `_bmad-output/planning-artifacts/architecture.md` §"Selected Starter"
- Enforcement rules: `_bmad-output/planning-artifacts/architecture.md` §"Enforcement Guidelines"
- Story 1.1 File List and dev notes: `_bmad-output/implementation-artifacts/1-1-project-initialization-platform-scaffold.md`
- Epic 1 story context: `_bmad-output/planning-artifacts/epics.md` §"Story 1.2: Core design system & ViewComponent UI library"
- Story dependency: 1.2 depends on 1.1 (done); can run in parallel with 1.3 and 1.6: `_bmad-output/implementation-artifacts/dependency-graph.md`
- NFR references: NFR-006 (Thai localization), NFR-007 (WCAG 2.1 AA accessibility), UX-DR1/2/3/7/8/10

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

### ATDD Artifacts

- Checklist: `_bmad-output/test-artifacts/atdd/atdd-checklist-1-2-core-design-system-viewcomponent-ui-library.md`
- Component tests: `test/components/` (11 files — all red-phase, `skip` until implementation)
- Integration tests: `test/integration/design_system_test.rb` (23 tests — AC-1, AC-2, AC-3)

### File List
