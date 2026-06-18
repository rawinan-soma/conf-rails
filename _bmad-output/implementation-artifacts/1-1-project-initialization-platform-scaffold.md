# Story 1.1: Project initialization & platform scaffold

Status: ready-for-dev

## Story

As a developer,
I want the Rails 8 project initialized with the agreed stack, styling, and CI,
so that all later stories build on a consistent, secure, no-Node foundation.

## Acceptance Criteria

1. **Given** a clean machine with Ruby 4.0.x, **when** the project is generated and `bin/dev` is run, **then** a Rails 8 app boots with PostgreSQL and Tailwind+daisyUI compiling via the standalone CLI (no Node/npm), **and** `.gitignore` excludes `master.key`, `config/credentials/*.key`, `.env*`, `*.pem`.

2. **Given** the CI workflow, **when** a push or PR runs, **then** RuboCop (omakase), Brakeman, bundler-audit, gitleaks, and Minitest all run, **and** the build fails on any high/critical Brakeman/CVE finding or any detected secret.

3. **Given** the deploy config, **when** `kamal` config is inspected, **then** a Dockerized Kamal 2 + Thruster setup exists with secrets sourced from ENV/credentials (no secrets in source).

## Tasks / Subtasks

- [ ] Task 1: Generate Rails 8 application (AC: #1)
  - [ ] Run `rails new conf-rails --database=postgresql --css=tailwind` with Ruby 4.0.x
  - [ ] Confirm `config/application.rb` sets `config.time_zone = "Bangkok"` and `config.i18n.default_locale = :en`
  - [ ] Verify `config/database.yml` uses PostgreSQL

- [ ] Task 2: Add daisyUI v5 (no Node) (AC: #1)
  - [ ] Download `daisyui.mjs` and `daisyui-theme.mjs` to `app/assets/tailwind/` (committed to repo, no CDN at runtime)
  - [ ] Configure `app/assets/tailwind/application.css` with `@import "tailwindcss"`, `@source not "./daisyui{,*}.mjs"`, `@plugin "./daisyui.mjs"`, `@plugin "./daisyui-theme.mjs"`
  - [ ] Verify `bin/dev` compiles Tailwind+daisyUI via standalone CLI (no Node/npm required)

- [ ] Task 3: Configure Gemfile with required gems (AC: #1, #2)
  - [ ] Add runtime gems: `pg`, `omniauth_openid_connect`, `pundit`, `view_component`, `prawn`, `rqrcode`, `solid_queue`, `solid_cache`, `solid_cable`, `tailwindcss-rails`, `lograge`
  - [ ] Add development/test gems: `i18n-tasks`, `brakeman`, `bundler-audit`, `rubocop-rails-omakase`
  - [ ] Run `bundle install` and commit `Gemfile.lock`

- [ ] Task 4: Set up .gitignore (AC: #1)
  - [ ] Ensure `.gitignore` excludes `master.key`, `config/credentials/*.key`, `.env*`, `*.pem`
  - [ ] Verify no credential files are staged

- [ ] Task 5: Set up GitHub Actions CI workflow (AC: #2)
  - [ ] Create `.github/workflows/ci.yml`
  - [ ] Pipeline steps: RuboCop (omakase), Brakeman (fail on high/critical), bundler-audit (fail on high/critical CVE), gitleaks (fail on any detected secret), Minitest
  - [ ] Ensure `i18n-tasks health` runs in CI
  - [ ] Confirm build fails on any high/critical Brakeman/CVE finding or detected secret

- [ ] Task 6: Configure Kamal 2 + Thruster deploy (AC: #3)
  - [ ] Set up `config/deploy.yml` for Kamal 2 with Thruster (TLS via Let's Encrypt)
  - [ ] Configure Dockerfile (Rails 8 default + Thruster)
  - [ ] Ensure all secrets sourced from ENV/Kamal secrets — never hardcoded in source
  - [ ] Verify `.gitignore` covers all credential files

- [ ] Task 7: Enable btree_gist extension (groundwork for Story 2.4)
  - [ ] Create migration to enable `btree_gist` extension: `enable_extension 'btree_gist'`
  - [ ] Run `db:migrate` and verify `schema.rb` includes `enable_extension "btree_gist"`

- [ ] Task 8: Initialize i18n structure (AC: #1, groundwork for Story 1.2)
  - [ ] Create `config/locales/en.yml` with root structure (at minimum `en: {}`)
  - [ ] Create `config/locales/th.yml` as key-for-key mirror (Thai translation scaffold — Rawinan fills in)
  - [ ] Configure `config/application.rb`: `config.i18n.available_locales = [:en, :th]`

- [ ] Task 9: Configure Solid Queue (groundwork for Story 1.6)
  - [ ] Ensure `config/queue.yml` exists for Solid Queue configuration
  - [ ] Create `config/recurring.yml` stub (jobs added in Story 1.6)
  - [ ] Scaffold `app/mailers/application_mailer.rb` with `default from: -> { I18n.t('mailers.sender_display') }` (actual sender display name wired in Story 1.6)
  - [ ] Scaffold `app/controllers/application_controller.rb` inheriting `ActionController::Base` — do NOT add `verify_authorized` here (that is Story 1.4); just the minimal base

- [ ] Task 10: Smoke test — boot and CI pass (AC: #1, #2)
  - [ ] Verify `bin/dev` boots the app with no errors
  - [ ] Verify `bin/rubocop`, `bin/brakeman`, `bundler-audit`, `bundle exec rails test` all pass locally
  - [ ] Verify `gitleaks` scan finds no secrets

## Dev Notes

### Stack Versions (Non-Negotiable)
- **Ruby:** 4.0.x (YJIT enabled in production; ZJIT is experimental — do NOT use ZJIT in prod)
- **Rails:** 8.x
- **PostgreSQL:** any modern version compatible with Rails 8 (tstzrange + GiST EXCLUDE support required)
- **Tailwind:** v4 via `tailwindcss-rails` (standalone binary, zero Node/npm)
- **daisyUI:** v5 (bundled `.mjs` files committed to repo — NOT from CDN, NOT from npm)

### daisyUI No-Node Setup (Critical)
The architecture mandates NO Node/npm. daisyUI v5 is loaded as bundled ESM plugin files:
```bash
curl -sLO --output-dir app/assets/tailwind \
  https://github.com/saadeghi/daisyui/releases/latest/download/daisyui.mjs
curl -sLO --output-dir app/assets/tailwind \
  https://github.com/saadeghi/daisyui/releases/latest/download/daisyui-theme.mjs
```
`app/assets/tailwind/application.css` must read:
```css
@import "tailwindcss";
@source not "./daisyui{,*}.mjs";
@plugin "./daisyui.mjs";
@plugin "./daisyui-theme.mjs";
```
The "Forest & Copper" theme is wired to `daisyui-theme.mjs` — the theme itself is implemented in Story 1.2. Placeholder/empty theme file is acceptable here.

### Gemfile — Required Gems
**Runtime:**
- `rails ~> 8.0`, `pg`, `propshaft` (asset pipeline — Rails 8 default), `importmap-rails` (JS)
- `tailwindcss-rails` (standalone CLI, no Node)
- `solid_queue`, `solid_cache`, `solid_cable` (DB-backed, no Redis)
- `omniauth_openid_connect` (OIDC auth — configured in Story 1.3)
- `pundit` (authorization — configured in Story 1.4)
- `view_component` (UI component library — built in Story 1.2)
- `prawn` (PDF — used in Story 3.7)
- `rqrcode` (QR codes — used in Story 3.7)
- `lograge` (structured logging — configured in `config/initializers/lograge.rb`)

**Development/Test:**
- `rubocop-rails-omakase` (lint)
- `brakeman` (security static analysis)
- `bundler-audit` (CVE scanning)
- `i18n-tasks` (locale health check)
- `capybara`, `selenium-webdriver` (system tests — Story 1.3+)

Note: Do NOT add gems for things not in scope for this story (e.g., authentication middleware is wired in Story 1.3 — just add the gem here).

### btree_gist Migration — Required in This Story
Although the EXCLUDE constraint itself is in Story 2.4, the `btree_gist` extension must be enabled here so migration history is clean. Create a migration:
```ruby
class EnableBtreegist < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'btree_gist'
  end
end
```

### .gitignore Hard Rules (NFR-001 / Security)
**Must include:**
```
config/master.key
config/credentials/*.key
.env
.env.*
*.pem
```
CI runs `gitleaks` — any credential-shaped string in a commit causes build failure.

### CI Pipeline Requirements (GitHub Actions)
File: `.github/workflows/ci.yml`

**Required steps in order:**
1. `bundle exec rubocop` (Rails Omakase — `rubocop-rails-omakase`)
2. `bundle exec brakeman --no-pager` — exit non-zero on high/critical finding
3. `bundle exec bundler-audit check --update` — exit non-zero on high/critical CVE
4. `gitleaks detect --source . --exit-code 1` — fail on any detected secret
5. `bundle exec rails test` — full Minitest suite
6. `bundle exec i18n-tasks health` — fails on missing/unused keys

**Build fails on:** any high/critical Brakeman finding, any high/critical CVE, any secret detected by gitleaks.

### Kamal 2 + Thruster Deploy
- `config/deploy.yml` for Kamal 2
- Production secrets (SMTP, OIDC client_secret, DB credentials) injected via Kamal secrets or ENV — never in source
- Thruster handles TLS (Let's Encrypt)
- `Dockerfile` uses Rails 8 default multi-stage build + Thruster entrypoint
- `master.key` and all `*.key` files gitignored and never committed

### Timezone & I18n Configuration
In `config/application.rb`:
```ruby
config.time_zone = "Bangkok"        # Asia/Bangkok (UTC+7)
config.i18n.default_locale = :en    # English for dev/build; Thai for prod when th.yml filled
config.i18n.available_locales = [:en, :th]
```
All timestamps stored as `timestamptz` (UTC) and displayed via `l(...)` helper in Asia/Bangkok.

### Solid Queue Configuration
`config/queue.yml` configures Solid Queue. `config/recurring.yml` is created as a stub (actual recurring jobs added in Story 1.6). `bin/dev` should start the Solid Queue worker alongside Rails.

### Anti-patterns to Avoid
- **DO NOT** install Node, npm, or any JS build tool — Tailwind uses the standalone CLI binary
- **DO NOT** commit `master.key`, `*.key`, `.env*`, or `*.pem` — CI fails on this
- **DO NOT** add `redis` gem — all background infrastructure is DB-backed (Solid Queue/Cache/Cable)
- **DO NOT** add RSpec — Minitest is the confirmed testing framework
- **DO NOT** inline daisyUI classes in views — Story 1.2 builds ViewComponents for that
- **DO NOT** send email synchronously (`deliver_now`) — use `deliver_later`
- **DO NOT** hardcode user-facing strings — use I18n keys (`t('.key')`)

### Project Structure Notes
This story establishes the canonical project structure. Files created here set the pattern for all subsequent stories:

```
conf-rails/
├── Gemfile                       # Exact versions per arch decision
├── .ruby-version                 # 4.0.x
├── .gitignore                    # master.key, credentials/*.key, .env*, *.pem
├── config/
│   ├── application.rb            # time_zone=Bangkok; default_locale=:en
│   ├── database.yml              # postgresql
│   ├── queue.yml                 # Solid Queue
│   ├── recurring.yml             # stub — jobs added in Story 1.6
│   ├── deploy.yml                # Kamal 2
│   ├── initializers/
│   │   └── lograge.rb            # structured logging config
│   └── locales/
│       ├── en.yml                # English (authored)
│       └── th.yml                # Thai (key-mirror stub for Rawinan)
├── app/
│   ├── controllers/
│   │   └── application_controller.rb   # minimal base (no verify_authorized yet — Story 1.4)
│   └── mailers/
│       └── application_mailer.rb       # sender display name stub (wired in Story 1.6)
├── app/assets/tailwind/
│   ├── application.css           # @import tailwindcss + daisyUI plugins
│   ├── daisyui.mjs               # committed bundle (no Node)
│   └── daisyui-theme.mjs         # committed bundle (Forest & Copper placeholder)
├── db/migrate/
│   └── *_enable_btreegist.rb     # enable_extension 'btree_gist'
├── docs/                         # project knowledge directory (see config.yaml)
├── .github/workflows/ci.yml      # 6-step pipeline
└── Dockerfile                    # Rails 8 default + Thruster
```

**Controller boundary:** `application_controller.rb` at this story is minimal Rails default. `include Pundit::Authorization` and `verify_authorized` are wired in Story 1.4. Do NOT add Pundit here — it will fail tests before Pundit policies exist.

**Mailer boundary:** `application_mailer.rb` is scaffolded but the actual org SMTP and sender display name (`t('mailers.sender_display')`) are fully configured in Story 1.6. Placeholder is acceptable.

### Testing Requirements
- All Minitest tests must pass (the test suite at this story is minimal — just the default Rails generator tests)
- No RSpec (Minitest only — this is an explicit architecture decision)
- Fixtures in `test/fixtures/` contain no real PII or credentials
- OmniAuth and SMTP are mocked/stubbed in tests (no live credentials) — stub setup begins in Story 1.3

### References

- Architecture decision: Rails 8 + Ruby 4.0 selection [Source: `_bmad-output/planning-artifacts/architecture.md` § "Starter Template Evaluation"]
- daisyUI no-Node setup [Source: `_bmad-output/planning-artifacts/architecture.md` § "Selected Starter: canonical rails new"]
- btree_gist extension requirement [Source: `_bmad-output/planning-artifacts/architecture.md` § "Data Architecture"]
- Security/secrets rules [Source: `_bmad-output/planning-artifacts/architecture.md` § "Security & Secrets (hard rule)"]
- CI pipeline requirements [Source: `_bmad-output/planning-artifacts/architecture.md` § "Infrastructure & Deployment" and "Enforcement Guidelines"]
- Gemfile gem list [Source: `_bmad-output/planning-artifacts/architecture.md` § "Complete Project Directory Structure"]
- Timezone configuration [Source: `_bmad-output/planning-artifacts/architecture.md` § "Data Architecture"]
- Story dependency: 1.1 is the serial gate for entire project [Source: `_bmad-output/implementation-artifacts/dependency-graph.md`]
- Epic 1 story requirements [Source: `_bmad-output/planning-artifacts/epics.md` § "Story 1.1"]

### ATDD Artifacts

- Checklist: `_bmad-output/test-artifacts/atdd/atdd-checklist-1-1-project-initialization-platform-scaffold.md`
- Integration tests: `test/integration/project_scaffold_test.rb`
- System tests: `test/system/platform_scaffold_system_test.rb`
- TDD Phase: RED (35 tests skipped — activate per task during implementation)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

### File List
