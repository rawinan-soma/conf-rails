---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
lastStep: 8
status: 'complete'
completedAt: '2026-06-18'
inputDocuments:
  - _bmad-output/planning-artifacts/prds/prd-conference-envocc-2026-06-07/prd.md
  - _bmad-output/planning-artifacts/prds/prd-conference-envocc-2026-06-07/.decision-log.md
  - _bmad-output/planning-artifacts/prds/prd-conference-envocc-2026-06-07/validation-report.md
  - _bmad-output/planning-artifacts/ux-designs/ux-conference-envocc-2026-06-07/DESIGN.md
  - _bmad-output/planning-artifacts/ux-designs/ux-conference-envocc-2026-06-07/EXPERIENCE.md
  - _bmad-output/design-thinking-2026-06-04.md
workflowType: 'architecture'
project_name: 'conf-rails'
product_name: 'ENVOCC Conference Room Booking System'
user_name: 'Rawinan'
date: '2026-06-18'
deferredFromPrd:
  - 'C-1/C-2: atomic conflict-detection guarantee + loser-of-race UX (FR-004, NFR-002)'
  - 'C-3: canonical timezone Asia/Bangkok — exact close/reminder fire times, scheduling, missed-run/idempotency (FR-034, FR-037, FR-084)'
  - 'C-4/H-5: SMTP-only email delivery-failure handling — retry/backoff, queue, visibility, dead-letter (FR-084)'
  - 'H-3: token security (entropy/expiry/single-use) + credential hashing, at-rest encryption, TLS, vuln-scan standard + CVSS cutoff (FR-043, FR-092, NFR-001)'
  - 'NFR-003: performance load envelope + perf-test plan'
  - 'OQ-3: IdP attribute mapping for FR-095 profile prefill'
  - 'FR-048: (event, email) dedup matching / internal-vs-external identity reconciliation'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements:**
~55 FRs across 11 feature groups (F1–F11): Room Calendar & Availability (F1),
Booking Creation (F2), Catering (F3), Registration Management (F4), External
Registration (F5), Organizer Dashboard (F6), Admin Room Management (F7), Admin
Analytics & Reporting (F8), Email & Notifications (F9), Authentication & Access
Control (F10), Internal Registration (F11). Architecturally these collapse into
~7 capability areas: (1) booking + atomic conflict detection, (2) dual-path
registration (public token + in-app), (3) catering/meal aggregation, (4) admin
room/analytics, (5) async email & notifications, (6) auth/RBAC + profile/IdP,
(7) document generation (PDF/QR/CSV/heatmap).

**Non-Functional Requirements:**
- NFR-001 Security — no critical/high vulns at launch; token + credential
  security (mechanisms deferred to this doc).
- NFR-002 Reliability — atomic double-booking prevention, concurrency-tested.
- NFR-003 Performance — 3s calendar/dashboard load; load envelope to be defined here.
- NFR-004 Responsiveness — public pages mobile+desktop equal priority; organizer
  flow mobile-usable.
- NFR-005 Data Retention — indefinite until admin deletion.
- NFR-006 Localization — Thai single-language UI, emails, generated docs.
- NFR-007 Accessibility — WCAG 2.1 AA on public + internal surfaces.

**Scale & Complexity:**
- Primary domain: full-stack web (server-rendered).
- Complexity level: medium — wide surface, but single-tenant, no real-time
  collaboration, two external deps (SMTP, IdP).
- Estimated architectural components: ~7 capability areas + cross-cutting infra.

### Technical Constraints & Dependencies

- **SMTP-only** outbound email — no third-party deliverability layer (Constraint).
- **Org IdP (OIDC)** for internal auth (FR-090); attribute mapping open (OQ-3).
- **No external calendar integration** (Constraint).
- **Canonical timezone Asia/Bangkok (UTC+7)** for all business-time logic (Constraint).
- **Thai-only** UI/emails/PDF — font + line-height/size floors (NFR-006, UX UXD-008).
- **Full replacement** of the legacy two-app system (no patch/extend path).
- Single organization, no multi-tenancy.

### Cross-Cutting Concerns Identified

- **Transactional integrity** — atomic conflict detection (FR-004) and in-flight
  close/cancel (FR-034c) require a persistence-level guarantee (→ PostgreSQL
  exclusion constraints / serializable txns).
- **Background jobs & scheduling** — auto-close, 1-day reminders, email send/retry,
  with idempotency + missed-run recovery, Asia/Bangkok-anchored.
- **Auth & RBAC** — OIDC internal auth; organizer/attendee capacities + admin role;
  cross-organizer read-to-register (FR-094); token-based public access (FR-092).
- **Email reliability** — commit/send decoupling, retry/backoff, dead-letter,
  failure visibility (FR-084).
- **Token security** — entropy, expiry, single-use for access + self-cancel links.
- **Identity reconciliation** — (event,email) dedup + internal/external linking (FR-048).
- **Audit logging** — bookings/cancellations/modifications (FR-073); scope to confirm.
- **i18n & accessibility** — Thai localization + WCAG 2.1 AA across both zones.
- **Observability & performance** — to size NFR-003 envelope and verify NFR-002.

## Starter Template Evaluation

### Primary Technology Domain

Full-stack web — a **Rails 8 server-rendered monolith** (Hotwire), PostgreSQL,
deployed with Kamal. One app serves both the authenticated internal app and the
public token-based registration pages.

### Starter Options Considered

- **Canonical `rails new` (Rails 8)** — SELECTED. Rails 8 defaults already cover the
  project's cross-cutting needs (jobs, deploy, security scanning); no third-party
  starter earns its dependency cost for a single-org internal tool (the rebuild's
  whole point is escaping an unmaintained stack).
- **thoughtbot Suspenders** — rejected: its opinions (RSpec, extra gems) are better
  chosen explicitly than inherited.
- **Jumpstart Pro / Bullet Train** — rejected: SaaS-oriented (teams, billing,
  multi-tenancy) this single-org tool doesn't need; commercial license.

### Selected Starter: canonical `rails new` (Rails 8, Ruby 4.0)

**Initialization Command:**

```bash
rails new conf-rails --database=postgresql --css=tailwind
# Ruby 4.0.x, Rails 8.x

# daisyUI without Node — drop the bundled ESM plugin next to the Tailwind input:
curl -sLO --output-dir app/assets/tailwind \
  https://github.com/saadeghi/daisyui/releases/latest/download/daisyui.mjs
curl -sLO --output-dir app/assets/tailwind \
  https://github.com/saadeghi/daisyui/releases/latest/download/daisyui-theme.mjs
```

In `app/assets/tailwind/application.css`:

```css
@import "tailwindcss";
@source not "./daisyui{,*}.mjs";
@plugin "./daisyui.mjs";
@plugin "./daisyui-theme.mjs";   /* "Forest & Copper" mapped to a custom daisyUI theme */
```

**Architectural Decisions Provided by Starter:**

**Language & Runtime:** Ruby 4.0.x (released Dec 2025), Rails 8.x. **Use YJIT** in
production — Ruby 4.0's new ZJIT is still experimental and not recommended for production
yet. (Rails 8 requires Ruby ≥3.2 and is compatible with Ruby 4.0.)

**Frontend / Styling:** Hotwire (Turbo + Stimulus), server-rendered — no SPA build.
Tailwind v4 via `tailwindcss-rails` (standalone CLI binary, **no Node/npm**), with
**daisyUI v5** loaded as a bundled `.mjs` plugin file (committed to the repo, no CDN
at runtime). The "Forest & Copper" palette + Thai Noto fonts (DESIGN.md) become a
**custom daisyUI theme**; daisyUI components (button, badge, modal, toggle, toast,
skeleton) map directly onto the UX component list. Propshaft asset pipeline; Importmap for JS.

**Localization (i18n):** **Build everything in English using Rails I18n keys** — no
hardcoded copy; every user-facing string, email, and generated-document label goes
through `t('...')`. `config/locales/en.yml` is authored in full; `config/locales/th.yml`
is scaffolded with the **same key set left for Rawinan to translate** (Thai is the
production language per NFR-006 / UXD-004). `default_locale` is English for
development/build; the production locale is Thai once `th.yml` is filled.

**Background Jobs & Scheduling:** Solid Queue (DB-backed, `FOR UPDATE SKIP LOCKED`),
with recurring/cron support for registration auto-close and the 1-day reminder.
Solid Cache + Solid Cable also DB-backed — no Redis.

**Database:** PostgreSQL — for `tstzrange` + `EXCLUDE` (GiST) constraints to guarantee
no double-booking at the persistence layer (NFR-002).

**Security tooling:** Brakeman (static analysis) by default — serves NFR-001;
bundler-audit added for dependency CVEs.

**Testing:** Minitest (Rails default) + GitHub Actions CI scaffold. (Minitest vs RSpec
confirmed as an explicit decision in the decisions step.)

**Deployment:** Kamal 2 + Thruster — Dockerized deploy to a VPS/on-prem (fits an
internal org tool with SMTP/IdP on the network; no PaaS).

**Code Organization:** "Fat models, thin controllers" (Rawinan's principle) — domain
logic in models / POROs / service objects; controllers orchestrate only.

**Note:** Running `rails new` + the daisyUI bundle setup is the first implementation story.

## Core Architectural Decisions

### Decision Priority Analysis

**Critical (block implementation):** conflict-detection guarantee, timezone model,
auth (OIDC + tokens), email reliability, dedup. **Important:** authorization, view
layer, PDF/QR, audit log, encryption of secrets. **Deferred (post-MVP):** attendance
tracking, the §7 Out-of-Scope list.

### Data Architecture

- **Database:** PostgreSQL (+ `btree_gist` extension enabled via migration).
- **✅ Atomic conflict detection (C-1/C-2 · FR-004/NFR-002):** an **`EXCLUDE USING gist`
  constraint** on `bookings` — `EXCLUDE USING gist (room_id WITH =, tstzrange(starts_at,
  ends_at, '[)') WITH &&) WHERE (status <> 'cancelled')`. Half-open `[)` ranges → a
  booking ending exactly when another starts does **not** conflict. The guarantee lives
  in the DB, not app code; the model also validates `ends_at > starts_at` and min
  duration. **Loser-of-race UX:** the create action rescues `PG::ExclusionViolation`,
  re-renders the form (Turbo) with an inline "that slot was just taken" error and
  preserves input. Concurrency test (NFR-002) fires K simultaneous overlapping inserts →
  exactly one succeeds.
- **✅ Registration dedup (FR-048):** unique index `(event_id, lower(email)) WHERE status
  <> 'cancelled'`. Internal/external reconciliation: a `Registration` links to the
  booking and, when the email matches an internal `User`, to that user — so a person is
  one registrant per event regardless of path. Cancel frees the pair.
- **✅ Timezone (C-3):** all timestamps stored as `timestamptz` (UTC); `Time.zone =
  "Bangkok"`. "End of date" (FR-034) = `end_of_day` in Asia/Bangkok; the reminder
  (FR-037) fires at a fixed Bangkok clock time the calendar day before.
- **Core entities:** `User` (capacities + admin flag + profile), `Room`, `RoomBlock`,
  `Booking`, `Registration`, `AuditLog`, `SmtpSetting`. Meal counts derived from
  `Registration.meal_type`. Retention indefinite (NFR-005); cancellations soft (status).
- **Validation:** model validations + DB constraints (belt-and-suspenders). Standard
  Rails migrations.

### Authentication & Security

- **✅ Internal auth (FR-090):** OmniAuth + **`omniauth_openid_connect`** against the org
  IdP. No local passwords. **✅ Profile prefill / OQ-3:** email taken from the OIDC
  `email` claim, read-only; remaining profile fields completed on a first-login
  self-service screen (gate to the app). Exact extra claims the IdP can supply confirmed
  against the real IdP at integration time (the remaining OQ-3 open point).
- **Authorization:** **Pundit** — one policy per resource. Organizer/attendee are
  capacities of every `User`; `admin` is a boolean/role. Policies enforce FR-094
  (manage-own-only, cross-organizer read-to-register, admin read-all).
- **✅ Tokens (H-3 · FR-043/FR-092):** per-event registration link + per-registration
  self-cancel link use **`has_secure_token`** (≥128-bit, URL-safe), stored as a
  **digest** (lookup by digest, never log the raw token). Registration-link validity
  tracks the event/registration-open lifecycle; the self-cancel token is invalidated
  after use. Public routes are token-scoped, never ID-guessable.
- **Secrets & at-rest:** Rails encrypted credentials; **Active Record Encryption** for
  the DB-stored SMTP password (FR-081). TLS in transit via Kamal/Thruster (Let's Encrypt).
- **Input safety (M-10):** free-text ("Other" title/meal) length-capped, HTML-escaped on
  render (default), and **CSV-injection-neutralized** on export (FR-072).
- **✅ Vuln scanning (NFR-001):** Brakeman + bundler-audit in CI; **build fails on any
  high/critical** finding (the CVSS cutoff).

### API & Communication Patterns

- **No public API** — server-rendered Hotwire. Internal JSON only where Turbo needs it.
- **✅ Email reliability (C-4/H-5 · FR-084):** ActionMailer over the org **SMTP** only.
  All sends are `deliver_later` → **Solid Queue**, so the registration transaction
  **commits independently of the send** (FR-084). Per-job **retry with backoff**;
  exhausted jobs land in Solid Queue's **failed-jobs** table (dead-letter) and surface to
  admins. **Time-triggered jobs** (auto-close, 1-day reminder) are **Solid Queue
  recurring tasks** (`config/recurring.yml`, Fugit cron, Bangkok); jobs are **idempotent**
  (a reminder/close marker prevents duplicate sends if a run repeats or catches up).
- **Error handling:** inline field errors (Turbo) + page-level banners with retry, per
  the UX state patterns.
- **QR (FR-038):** `rqrcode` (pure Ruby) → PNG/SVG. **Sign-in sheet PDF (FR-036):**
  **Prawn** with an embedded **Noto Sans Thai** TTF for correct Thai rendering.

### Frontend Architecture

- **Hotwire:** Turbo Drive + Turbo Frames/Streams for the calendar grid, registrant
  lists, and dashboard partial updates; Stimulus controllers for the catering/registration
  toggles, meal-type "Other" reveal, and copy-link/QR actions.
- **View layer:** **ViewComponent** — the daisyUI component set (button, badge, modal,
  toggle, toast, skeleton, calendar-slot, booking-card) becomes a tested component
  library; all copy via I18n keys.
- **Calendar:** server-rendered **week scheduler** (rooms × days), no live collaboration.
- **State:** server-authoritative; minimal client state.

### Infrastructure & Deployment

- **Deploy:** Kamal 2 + Thruster, Dockerized, to a VPS/on-prem alongside the org's
  SMTP/IdP. PostgreSQL co-located or managed.
- **CI/CD:** GitHub Actions — RuboCop (omakase), Brakeman, bundler-audit, Minitest
  (incl. the concurrency test + system tests).
- **Config:** Rails credentials/ENV; SMTP settings admin-editable in DB (encrypted).
- **Observability:** `lograge` structured logs; DB-backed **audit log** (FR-073) covering
  bookings/cancellations/modifications (scope to confirm in patterns step).
- **✅ Performance (NFR-003):** **load envelope deferred to a perf-test plan** here —
  baseline target p95 ≤ 3s for calendar/dashboard; load profiled with **k6** (TEA) against
  a seed dataset; envelope finalized once real org volumes are known.

### Decision Impact Analysis

**Implementation sequence:** (1) `rails new` + daisyUI bundle + CI; (2) DB schema +
`btree_gist` + EXCLUDE/dedup constraints; (3) OIDC auth + profile first-login + Pundit;
(4) booking + conflict detection; (5) registration (public token + in-app) + dedup;
(6) Solid Queue email + recurring close/reminder; (7) admin (rooms, analytics, settings);
(8) PDF/QR/CSV; (9) i18n key extraction + th.yml scaffold.

**Cross-component dependencies:** EXCLUDE constraint underpins NFR-002; tokens gate public
registration; Solid Queue underpins all email + scheduled behavior; Pundit policies depend
on the User capacity/role model; ViewComponent + daisyUI theme depend on the DESIGN tokens.

## Implementation Patterns & Consistency Rules

### Pattern Categories Defined

The governing rule: **Rails convention-over-configuration is authoritative.** Where
Rails has a convention, agents follow it — no re-litigating. The rules below cover the
project-specific choices and the few places agents could still diverge. Enforced
mechanically by **RuboCop Rails Omakase** + **Brakeman** + **i18n-tasks** + **gitleaks** in CI.

### Naming Patterns

**Database (Rails defaults):** plural snake_case tables (`bookings`, `registrations`,
`room_blocks`); snake_case columns; FKs `room_id`/`booking_id`; `created_at`/`updated_at`;
booleans `*?`-friendly (`active`, `catering_enabled`). **Named constraints** (referenced
in stories): `bookings_no_overlap` (EXCLUDE), `index_registrations_on_event_and_email`
(unique partial). Enums stored as strings (`status`), not integers.

**Models:** singular CamelCase (`Booking`). No STI. Domain logic lives here (fat models);
multi-model orchestration goes to `app/services` POROs named imperatively
(`CreateBooking`, `CloseExpiredRegistrations`) exposing `.call`.

**Controllers & routes:** plural RESTful controllers, standard 7 actions only — extra
behavior becomes a new resource. Namespaces: `Admin::` (room mgmt, analytics, settings),
public token registration under a `Public::`/token-scoped namespace; **no API namespace**.
Routes via `resources`; public links are `/r/:token` style, never ID-exposing.

**Components & JS:** ViewComponents are `XxxComponent` in `app/components`
(`ButtonComponent`, `BookingCardComponent`). Stimulus controllers kebab-case
(`catering-toggle`, `copy-link`). daisyUI classes live inside components, never sprinkled
ad hoc in views.

**I18n keys:** **lazy, view-scoped** (`t('.title')` → `bookings.new.title`); model names
& attributes under `activerecord.*`; emails under `mailers.*`; shared UI under `common.*`.
`th.yml` mirrors `en.yml` key-for-key. **No literal user-facing strings in code** —
CI fails on violations via `i18n-tasks` (also flags missing/unused keys for Rawinan's
translation pass).

### Structure Patterns

Standard Rails layout. Project-specific homes: `app/components` (ViewComponent),
`app/services` (POROs), `app/policies` (Pundit), `app/jobs`, `app/mailers`,
`app/components/**` co-located `*.html.erb`. Tests in `test/` mirroring source
(`test/models`, `test/components`, `test/system`, `test/jobs`) — Minitest, fixtures for
data, Capybara system tests for flows. The Thai TTF for Prawn lives in `app/assets/fonts`.

### Format Patterns

Server-rendered HTML + **Turbo Streams** for partial updates (no JSON envelope — N/A).
Timestamps stored `timestamptz` (UTC), **always displayed via `l(...)` in Asia/Bangkok**
(never raw `.to_s`). Real booleans. CSV export UTF-8 **with BOM** (Excel + Thai) and
formula-injection-neutralized.

### Communication Patterns

**Jobs:** Active Job on Solid Queue, named `XxxJob` (`SendRegistrationConfirmationJob`,
`SendEventReminderJob`, `CloseExpiredRegistrationsJob`, `DeactivateRoomCascadeJob`).
**Every job is idempotent** (guard on a sent-at / closed-at marker). Mailers on a
`mailers` queue; recurring tasks declared in `config/recurring.yml`.

**Audit log:** one path — `AuditLog.record(actor:, action:, subject:, changes:)` invoked
from services, never scattered inline. Actions are dotted verbs (`booking.created`,
`booking.cancelled`, `room.deactivated`, `registration.cancelled`).

### Process Patterns

- **Error handling:** validation failures re-render the form with inline field errors
  (Turbo, focus first error); `Pundit::NotAuthorizedError` → 403 + flash; `RecordNotFound`
  → 404; invalid/expired token → neutral "registration closed/unavailable" page (no
  enumeration); `PG::ExclusionViolation` rescued in `BookingsController#create` → slot-taken
  message + alternatives.
- **Loading:** skeletons for calendar/lists/dashboard; submit buttons disabled + spinner.
- **Auth flow:** OmniAuth OIDC callback → `find_or_create` User by IdP subject →
  first-login profile gate before app access.
- **Validation timing:** server-side is authoritative; client validation is progressive
  enhancement only.

### Security & Secrets (hard rule)

**No credential — real OR test/dummy — is ever committed to the git repo.** This is
non-negotiable and CI-enforced.

- **Real secrets:** Rails **encrypted credentials** (`config/credentials.yml.enc`); the
  **`master.key` / per-env keys are gitignored** and never committed. Production secrets
  (SMTP, OIDC client secret, DB URL, AR-Encryption keys) are injected at deploy time via
  **Kamal secrets / ENV**, never in source. Any `.env*` file is gitignored.
- **Test/CI credentials:** tests use **non-real, obviously-fake placeholder values**
  (`"test-client-secret"`, `example.test` hosts) defined in `test/` config or supplied by
  CI **secrets**, not hardcoded real keys. OmniAuth/SMTP are **mocked/stubbed** in tests
  (no live credentials). Fixtures contain no real PII or keys.
- **Tooling:** add **`gitleaks`** (secret scanning) to the GitHub Actions pipeline; CI
  **fails** if any credential-shaped string is detected in the diff or history. `.gitignore`
  covers `master.key`, `config/credentials/*.key`, `.env*`, and `*.pem`.

### Enforcement Guidelines

**All AI agents (BAD pipeline) MUST:**
- Run `bin/rubocop` (Rails Omakase), `bin/brakeman`, `bundler-audit`, `gitleaks`, and the
  full test suite green before a PR — CI gates on all five; **build fails on any
  high/critical** Brakeman/CVE finding (NFR-001) **or any detected secret**.
- **Never commit a credential of any kind** — real or test. Use encrypted credentials /
  ENV / mocks; keep keys and `.env*` gitignored.
- Route every controller action through a Pundit policy (`verify_authorized`).
- Add no user-facing literal strings — only I18n keys (CI: `i18n-tasks health`).
- Keep controllers thin; put logic in models/services.
- Make every new background job idempotent and add its recurring entry if time-triggered.

**Anti-patterns to avoid:** committing secrets/keys/`.env` files (even test ones);
business logic in controllers or views; raw SQL where AR/Arel suffices (except the
deliberate `btree_gist` EXCLUDE migration); bypassing ViewComponents with inline daisyUI
markup; sending email synchronously (`deliver_now`) in request flow; comparing/storing
business time in UTC literals instead of Bangkok.

## Project Structure & Boundaries

### Complete Project Directory Structure

```
conf-rails/
├── Gemfile                      # rails ~> 8, pg, omniauth_openid_connect, pundit,
│                                #   view_component, prawn, rqrcode, tailwindcss-rails,
│                                #   i18n-tasks, brakeman, bundler-audit (dev/test)
├── Gemfile.lock
├── .ruby-version                # 4.0.x
├── .gitignore                   # + master.key, config/credentials/*.key, .env*, *.pem
├── config/
│   ├── application.rb           # config.time_zone = "Bangkok"; i18n.default_locale
│   ├── routes.rb                # resources + Admin:: + token-scoped public (/r/:token)
│   ├── database.yml             # postgresql
│   ├── recurring.yml            # Solid Queue: close-registrations, send-reminders (Bangkok cron)
│   ├── queue.yml                # Solid Queue config
│   ├── credentials.yml.enc      # encrypted; master.key gitignored
│   ├── deploy.yml               # Kamal 2
│   ├── initializers/
│   │   ├── omniauth.rb          # OIDC provider (secrets via ENV/credentials)
│   │   ├── pundit.rb
│   │   └── view_component.rb
│   └── locales/
│       ├── en.yml               # authored in full (English)
│       └── th.yml               # key-for-key mirror — Rawinan translates
├── app/
│   ├── models/
│   │   ├── user.rb              # capacities + admin?; profile fields; F10
│   │   ├── room.rb              # F7; active scope
│   │   ├── room_block.rb        # F7 blocked slots
│   │   ├── booking.rb           # F2; conflict (EXCLUDE) + meal aggregation; fat model
│   │   ├── registration.rb      # F4/F5/F11; external+internal; tokens; dedup
│   │   ├── audit_log.rb         # F8 FR-073
│   │   └── smtp_setting.rb      # F9 FR-081; AR-encrypted password
│   ├── controllers/
│   │   ├── application_controller.rb   # Pundit, current_user, profile gate, locale
│   │   ├── sessions_controller.rb      # OmniAuth callback (F10)
│   │   ├── profiles_controller.rb      # first-login self-service profile (FR-095)
│   │   ├── calendar_controller.rb      # F1 week scheduler
│   │   ├── bookings_controller.rb      # F2 (rescues PG::ExclusionViolation)
│   │   ├── events_controller.rb        # internal Event Detail + register-to-attend (F11)
│   │   ├── dashboard_controller.rb     # F6
│   │   ├── admin/
│   │   │   ├── rooms_controller.rb         # F7
│   │   │   ├── room_blocks_controller.rb   # F7
│   │   │   ├── analytics_controller.rb     # F8 heatmap, bulk calendar, CSV
│   │   │   └── settings_controller.rb      # F9 SMTP + role assignment
│   │   └── public/
│   │       └── registrations_controller.rb # F5 token page, submit, self-cancel, resend
│   ├── components/              # ViewComponent + daisyUI (co-located .html.erb)
│   │   ├── button_component.rb        booking_card_component.rb
│   │   ├── status_badge_component.rb  calendar_slot_component.rb
│   │   ├── modal_component.rb          toast_component.rb
│   │   ├── toggle_component.rb         skeleton_component.rb
│   │   └── heatmap_cell_component.rb
│   ├── services/                # POROs, .call (multi-model orchestration)
│   │   ├── create_booking.rb          cancel_booking.rb
│   │   ├── register_attendee.rb       # external + internal, dedup reconciliation (FR-048)
│   │   ├── cancel_registration.rb     close_expired_registrations.rb
│   │   ├── deactivate_room.rb         # cascade cancel + notify (FR-063)
│   │   ├── sign_in_sheet_pdf.rb       # Prawn + Noto Thai (FR-036)
│   │   ├── event_qr_code.rb           # rqrcode (FR-038)
│   │   └── registrants_csv.rb         # UTF-8 BOM, injection-safe (FR-072)
│   ├── policies/                # Pundit — one per resource
│   │   ├── application_policy.rb  booking_policy.rb
│   │   ├── room_policy.rb          registration_policy.rb  admin_policy.rb
│   ├── jobs/                    # Solid Queue, idempotent
│   │   ├── send_registration_confirmation_job.rb
│   │   ├── send_event_reminder_job.rb        # FR-037
│   │   ├── close_expired_registrations_job.rb # FR-033/034
│   │   └── deactivate_room_cascade_job.rb
│   ├── mailers/
│   │   ├── application_mailer.rb     # sender = org name (FR-083)
│   │   ├── booking_mailer.rb         registration_mailer.rb
│   ├── views/ ...               # ERB; all copy via t('.key')
│   └── assets/
│       ├── tailwind/
│       │   ├── application.css   # @import tailwindcss; @plugin daisyui.mjs + theme
│       │   ├── daisyui.mjs        daisyui-theme.mjs   # committed bundle (no Node)
│       └── fonts/                # Noto Sans/Serif Thai TTF (Prawn + web)
├── db/
│   ├── migrate/                 # incl. enable btree_gist; bookings_no_overlap EXCLUDE;
│   │                            #   registrations unique (event_id, lower(email))
│   ├── schema.rb  seeds.rb
├── test/                        # Minitest — mirrors app/
│   ├── models/  components/  policies/  jobs/  mailers/
│   ├── controllers/  system/   # Capybara flows (the 4 UX flows)
│   ├── fixtures/                # no real PII/keys
│   └── test_helper.rb           # OmniAuth/SMTP mocked
├── .github/workflows/ci.yml     # rubocop, brakeman, bundler-audit, gitleaks, tests
├── Dockerfile                   # Rails 8 default + Thruster
└── bin/                         # rails, rubocop, brakeman, kamal, dev
```

### Architectural Boundaries

- **Trust boundary** — authenticated internal app (OmniAuth/OIDC + Pundit) vs. the
  public token-scoped `Public::` namespace (no session, token only). They share models
  but never controllers/policies.
- **Component boundary** — all UI rendered through ViewComponents; controllers pass data,
  components own daisyUI markup + i18n.
- **Service boundary** — anything touching ≥2 models or external effects (email, PDF, CSV,
  cascade) is an `app/services` PORO; models hold single-aggregate logic.
- **Data boundary** — correctness invariants enforced at the DB (EXCLUDE no-overlap,
  unique dedup, FKs); app validations mirror them for UX.

### Requirements → Structure Mapping

| Feature group | Primary homes |
|---|---|
| F1 Calendar | `calendar_controller`, `calendar_slot_component`, `Room`/`Booking` |
| F2 Booking | `bookings_controller`, `CreateBooking`, `Booking` + EXCLUDE migration |
| F3 Catering | `Booking` (toggle + aggregation), `register_attendee`, `Registration.meal_type` |
| F4 Reg. mgmt | `bookings`/`events` show, `sign_in_sheet_pdf`, `event_qr_code`, `Registration` |
| F5 External reg. | `public/registrations_controller`, `register_attendee`, tokens |
| F6 Dashboard | `dashboard_controller`, `booking_card_component` |
| F7 Admin rooms | `admin/rooms`, `admin/room_blocks`, `deactivate_room` |
| F8 Analytics | `admin/analytics`, `heatmap_cell_component`, `registrants_csv`, `AuditLog` |
| F9 Email | `*_mailer`, `*_job`, `admin/settings`, `SmtpSetting` |
| F10 Auth | `sessions`, `profiles`, `omniauth.rb`, `policies/*`, `User` |
| F11 Internal reg. | `events_controller`, `register_attendee` (shared w/ F5) |

### Integration Points

- **External:** org **OIDC IdP** (login + email claim); org **SMTP** (all mail). No other
  third parties. **Data flow:** request → controller (thin) → model/service → DB; effects
  (email/PDF) enqueued to Solid Queue; scheduled jobs read DB and enqueue mail.

### Development Workflow

`bin/dev` runs Rails + the Tailwind/daisyUI watcher (standalone CLI, no Node). CI mirrors
the local gates. Deploy via `kamal deploy` (Dockerized, Thruster TLS).

## Architecture Validation Results

### Coherence Validation ✅

**Decision Compatibility:** Rails 8 + Ruby 4.0 + PostgreSQL + Hotwire + daisyUI
(standalone, no Node) + Solid Queue/Cache/Cable + Pundit + ViewComponent + Minitest +
Prawn + Kamal are a mutually-compatible, version-verified stack with no contradictions.
The "fat models / thin controllers" principle, the no-Node constraint, and the
no-credentials rule are consistent across decisions, patterns, and structure.

**Pattern Consistency:** Naming, structure, jobs, error-handling, and security patterns
all derive from Rails convention + the chosen libraries; nothing in the patterns
contradicts a decision (e.g. Solid Queue underpins both the email-reliability decision
and the recurring-job patterns; ViewComponent underpins both the frontend decision and
the daisyUI component naming).

**Structure Alignment:** The directory tree provides a concrete home for every decision
(EXCLUDE migration, `app/services`, `app/policies`, `app/components`, `config/recurring.yml`,
Thai fonts, gitignore for keys) and respects the internal-vs-public trust boundary.

### Requirements Coverage Validation ✅

**Functional (F1–F11):** every feature group maps to specific files (see Requirements →
Structure Mapping). The dual registration paths (F5 public token + F11 in-app) share
`register_attendee` with DB-level dedup (FR-048).

**Non-Functional:** NFR-001 (tokens digested, Brakeman+bundler-audit+gitleaks gate,
AR-Encryption, TLS) ✅ · NFR-002 (EXCLUDE constraint + concurrency test) ✅ ·
NFR-003 (3s target; **load envelope intentionally deferred** to a k6 perf plan once real
volumes are known) ⚠️ minor · NFR-004 (Hotwire + responsive daisyUI; UX owns breakpoints) ✅ ·
NFR-005 (indefinite retention, soft-cancel) ✅ · NFR-006 (Rails I18n, en authored / th
scaffolded) ✅ · NFR-007 (semantic ViewComponents; UX owns AA specifics) ✅.

**Deferred-from-PRD worklist (7):** conflict detection ✅, timezone ✅, email reliability ✅,
tokens ✅, dedup ✅ — fully resolved. IdP attribute mapping (OQ-3) and the NFR-003 load
envelope are **approach-defined, final values confirmed at integration/perf-test** — not
blocking.

### Implementation Readiness Validation ✅

Decisions documented with versions; patterns enforceable in CI; structure complete and
specific; FR→structure mapping done. An AI agent (BAD pipeline) has an unambiguous home
and convention for each story.

### Gap Analysis Results

**Critical:** none.
**Minor (documented, non-blocking):**
- NFR-003 exact load envelope — finalize via k6 once org volumes are known.
- OQ-3 exact OIDC claim mapping — confirm against the real IdP at auth integration.
- Audit-log scope (FR-073) — PRD names bookings/cancellations/modifications; broadening to
  role grants + SMTP changes + room deactivation is supported by `AuditLog.record` and
  recommended, but is a product call to confirm.
**Cross-artifact sync (flag for UX):** `DESIGN.md` still shows an "Attended" status badge;
the PRD removed "Attended" for MVP (FR-035 / DEC-032). UX should drop it on its next pass.

### Architecture Completeness Checklist

**Requirements Analysis**
- [x] Project context thoroughly analyzed
- [x] Scale and complexity assessed
- [x] Technical constraints identified
- [x] Cross-cutting concerns mapped

**Architectural Decisions**
- [x] Critical decisions documented with versions
- [x] Technology stack fully specified
- [x] Integration patterns defined
- [x] Performance considerations addressed (target set; envelope deferred with a plan)

**Implementation Patterns**
- [x] Naming conventions established
- [x] Structure patterns defined
- [x] Communication patterns specified
- [x] Process patterns documented

**Project Structure**
- [x] Complete directory structure defined
- [x] Component boundaries established
- [x] Integration points mapped
- [x] Requirements to structure mapping complete

### Architecture Readiness Assessment

**Overall Status:** READY FOR IMPLEMENTATION
**Confidence Level:** high — all 16 checklist items confirmed, no critical gaps; the two
deferrals are intentional and have a defined resolution path.

**Key Strengths:** correctness pushed to the DB (EXCLUDE/unique constraints); a single
maintained stack with near-zero extra dependencies; security enforced mechanically in CI
(secrets, vulns, authz); clean internal/public trust split; i18n-first so Rawinan's Thai
translation slots in cleanly.

**Areas for Future Enhancement:** finalize NFR-003 envelope; broaden audit-log scope;
attendance tracking + the §7 post-MVP list; UX "Attended" cleanup.

### Implementation Handoff

**AI Agent Guidelines:** follow the documented decisions exactly; use the patterns
consistently; respect the trust/component/service boundaries; never commit a credential;
treat this document as the architectural source of truth.

**First Implementation Priority:**
`rails new conf-rails --database=postgresql --css=tailwind` + the daisyUI bundle setup,
then enable `btree_gist` and add the `bookings_no_overlap` EXCLUDE constraint.
