# Story 1.6: Email & Background-Job Infrastructure

Status: ready-for-dev

## Story

As the system,
I want outbound email sent asynchronously over the org SMTP, decoupled from request transactions,
so that features can notify users reliably without blocking on mail delivery.

## Acceptance Criteria

1. **Given** Solid Queue configured, **when** the app runs, **then** background jobs and a recurring-task scheduler are operational with a dead-letter (failed-jobs) path visible and surfaced.

2. **Given** a mailer send, **when** it is triggered from a request, **then** it is enqueued (`deliver_later`) and the triggering transaction commits even if the send later fails.

3. **Given** any outbound email, **when** it is delivered, **then** the sender display name is the organization name and delivery uses the org SMTP only (no third-party service).

## Tasks / Subtasks

- [ ] Task 1: Wire ActionMailer to SMTP via org credentials (AC: #3)
  - [ ] Uncomment and configure `config.action_mailer.smtp_settings` in `config/environments/production.rb` to read SMTP host, port, username, and password from Rails encrypted credentials (`Rails.application.credentials.dig(:smtp, ...)`)
  - [ ] Set `config.action_mailer.delivery_method = :smtp` in production
  - [ ] Set `config.action_mailer.perform_deliveries = true` in production (explicit — this is the default, but must be clear)
  - [ ] Set `config.action_mailer.raise_delivery_errors = true` in production (so failed sends propagate to Solid Queue retry/dead-letter, not silently swallowed)
  - [ ] Add `config.action_mailer.default_url_options = { host: Rails.application.credentials.dig(:app, :host) || "conf.envocc.org" }` in production so mailer link helpers work (needed for confirmation links in Epic 3)
  - [ ] Confirm development environment uses `:letter_opener` or `:async` delivery method (do NOT add real SMTP creds to dev — the current dev config has no `delivery_method` set, which defaults to `:smtp`; set it explicitly to `:async` or install `letter_opener` gem if desired — check Gemfile first)
  - [ ] Confirm test environment retains `delivery_method: :test` (already set — verify only, no change needed)
  - [ ] Add SMTP password to `.kamal/secrets` as `SMTP_PASSWORD` — this resolves the deferred-work item from Story 1.1 review: "SMTP_PASSWORD not in .kamal/secrets yet — deferred to Story 1.6". Update `config/deploy.yml` if needed to reference the secret at deploy time via ENV. Do NOT hardcode the actual password — just add the secret key reference.

- [ ] Task 2: Wire ApplicationMailer sender display name from org name i18n key (AC: #3)
  - [ ] `ApplicationMailer` already has `default from: -> { I18n.t("mailers.sender_display") }` (scaffolded in Story 1.1 — do NOT change this line)
  - [ ] Update `config/locales/en.yml` to set `en.mailers.sender_display` to `"ENVOCC <noreply@example.com>"` placeholder format — the actual org name and address will be filled by Rawinan when the SMTP admin UI (Story 4.5) and th.yml translation are complete; for now the key must exist and be non-empty
  - [ ] Mirror `th.mailers.sender_display` in `config/locales/th.yml` with the same placeholder value (key-for-key mirror rule)
  - [ ] Run `bundle exec i18n-tasks health` — must pass clean

- [ ] Task 3: Configure Solid Queue queues for mailers (AC: #1, #2)
  - [ ] In `config/queue.yml`, add a dedicated `mailers` queue to the workers section so mail jobs run on their own queue with appropriate thread count (e.g., 2 threads for mailers, separate from default `*` queue)
  - [ ] Ensure the `default` worker still covers `*` for non-mailer jobs
  - [ ] Verify `config/queue.yml` has a `production` section that inherits or expands the default

- [ ] Task 4: Add recurring-task entries to `config/recurring.yml` (AC: #1)
  - [ ] Add `close_expired_registrations` recurring entry: class `CloseExpiredRegistrationsJob`, queue `default`, schedule `every day at midnight` (Asia/Bangkok, i.e., UTC+7 → `at 17:00` UTC cron); this job is a stub for Story 3.1 — schedule entry added now so Solid Queue loads it
  - [ ] Add `send_event_reminders` recurring entry: class `SendEventRemindersJob`, queue `default`, schedule `every day at 8:00am` Bangkok time (i.e., `at 1:00` UTC); this job is a stub for Story 3.8 — schedule entry added now
  - [ ] Wrap entries under the `production:` key to match the existing `clear_solid_queue_finished_jobs` pattern
  - [ ] Use Fugit-compatible cron strings (Solid Queue uses Fugit for `config/recurring.yml` — `at 17:00` means 17:00 UTC daily)

- [ ] Task 5: Implement ApplicationJob base with retry/backoff (AC: #1, #2)
  - [ ] Update `app/jobs/application_job.rb` to enable automatic retry with exponential backoff for transient errors:
    - `retry_on StandardError, wait: :polynomially_longer, attempts: 5`
    - `discard_on ActiveJob::DeserializationError` (already commented — uncomment)
    - Keep `retry_on ActiveRecord::Deadlocked` commented pattern visible (uncomment it — useful for DB operations)
  - [ ] Dead-letter path: exhausted retries cause Solid Queue to move the job to `solid_queue_failed_executions` table (built into Solid Queue — no extra code needed; verify `db/queue_schema.rb` already has this table — it does from Story 1.1)
  - [ ] Do NOT add `rescue_from` in controllers for mail failures — the decoupling is the point

- [ ] Task 6: Create stub job classes for future mailer jobs (AC: #1, #2)
  - [ ] Create `app/jobs/send_registration_confirmation_job.rb` — stub that raises `NotImplementedError` (implemented in Story 3.2); must be idempotent (add a `performed?` guard pattern stub comment)
  - [ ] Create `app/jobs/send_event_reminder_job.rb` — stub that raises `NotImplementedError` (implemented in Story 3.8); idempotent guard comment
  - [ ] Create `app/jobs/close_expired_registrations_job.rb` — stub that raises `NotImplementedError` (implemented in Story 3.1); idempotent guard comment
  - [ ] All stubs must be real classes in `app/jobs/` so Solid Queue can load the recurring entries without `NameError` at boot
  - [ ] **Do NOT** implement job logic — that belongs in the story that owns the feature (Stories 3.1, 3.2, 3.8)

- [ ] Task 7: Create stub mailer classes (AC: #3)
  - [ ] Create `app/mailers/booking_mailer.rb` — stub extending `ApplicationMailer` with method stubs `confirmation` and `cancellation` that raise `NotImplementedError`; implemented in Story 2.4/2.5
  - [ ] Create `app/mailers/registration_mailer.rb` — stub extending `ApplicationMailer` with method stubs `confirmation`, `cancellation`, `reminder` that raise `NotImplementedError`; implemented in Stories 3.2, 3.3, 3.8
  - [ ] Each mailer must extend `ApplicationMailer` so it inherits sender display name and layout
  - [ ] Create corresponding stub view templates so ActionMailer doesn't error on initialization: `app/views/booking_mailer/.keep` and `app/views/registration_mailer/.keep`

- [ ] Task 8: Write tests (AC: #1, #2, #3)
  - [ ] `test/mailers/application_mailer_test.rb` — test that `ApplicationMailer.default[:from]` returns the `mailers.sender_display` i18n key value (call the lambda: `ApplicationMailer.default[:from].call`)
  - [ ] `test/jobs/application_job_test.rb` — test that a test job subclass inherits retry configuration (define a `TestJob < ApplicationJob` inline; assert it responds to `perform_now`)
  - [ ] `test/integration/email_infrastructure_test.rb` — integration test for:
    - (AC #2) `deliver_later` does NOT immediately deliver (use `assert_no_emails` + `assert_enqueued_emails(1)`)
    - (AC #2) After `deliver_later`, `perform_enqueued_jobs` delivers the mail (use `assert_emails(1)`)
    - (AC #3) The `from:` on `ApplicationMailer.default[:from].call` contains "ENVOCC"
  - [ ] **CRITICAL: `test_helper.rb` does NOT include `ActiveJob::TestHelper`** — either add `include ActiveJob::TestHelper` to `ActiveSupport::TestCase` in `test/test_helper.rb`, OR include it individually in each job/integration test file. The global approach in `test_helper.rb` is cleaner and consistent with the project's existing `fixtures :all` global setup.
  - [ ] Use `ActionMailer::Base.deliveries` assertions with `:test` delivery method (already set in `config/environments/test.rb`)
  - [ ] Use `ActiveJob::TestHelper` (`assert_enqueued_with`, `perform_enqueued_jobs`, `assert_enqueued_emails`, `assert_emails`) — do NOT test stub jobs with real delivery
  - [ ] Use `assert_enqueued_emails(1) { BookingMailer.confirmation(stub_booking).deliver_later }` pattern when testing a concrete mailer (note: stub mailers raise `NotImplementedError` — test `ApplicationMailer` derived behavior, not the stubs)

- [ ] Task 9: Verify CI passes (AC: all)
  - [ ] Run `bundle exec rubocop` — 0 offenses
  - [ ] Run `bundle exec brakeman --no-pager` — 0 high/critical warnings
  - [ ] Run `bundle exec i18n-tasks health` — no missing or unused keys
  - [ ] Run `bundle exec rails test` — all tests pass
  - [ ] Verify no credentials are hardcoded — gitleaks will catch any that slip through

## Dev Notes

### What Story 1.1 Already Did (Do NOT Redo)
Story 1.1 is complete (`done`). The following are already in place — do NOT recreate them:
- `app/mailers/application_mailer.rb` with `default from: -> { I18n.t("mailers.sender_display") }` and `layout "mailer"`
- `app/jobs/application_job.rb` (stub — extend it in Task 5)
- `config/queue.yml` (Solid Queue config — extend in Task 3)
- `config/recurring.yml` (stub — extend in Task 4)
- `db/queue_schema.rb` with `solid_queue_failed_executions` table (dead-letter — already exists)
- `config/environments/test.rb` with `delivery_method: :test`
- `config/environments/production.rb` with `active_job.queue_adapter = :solid_queue` and `solid_queue.connects_to`
- `Procfile.dev` already starts `bin/jobs` alongside Rails (review patch from Story 1.1)
- `config/locales/en.yml` with `en.mailers.sender_display: "Conf Rails"` (update placeholder in Task 2)
- `config/locales/th.yml` with mirrored key (update in Task 2)

### SMTP Configuration — Credentials Only, No Admin UI Yet
FR-081 (admin-configurable SMTP settings via `SmtpSetting` model) is **Epic 4 (Story 4.5)** scope. This story (1.6) wires SMTP from Rails encrypted credentials only. The `SmtpSetting` model with Active Record Encryption does NOT exist yet and must NOT be created here.

SMTP credential path in `config/credentials.yml.enc`:
```
smtp:
  host: smtp.example.com
  port: 587
  username: noreply@example.com
  password: [encrypted — never committed]
  authentication: plain
  starttls: true
```

In `config/environments/production.rb`, the mailer config reads:
```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.raise_delivery_errors = true
config.action_mailer.smtp_settings = {
  address:              Rails.application.credentials.dig(:smtp, :host),
  port:                 Rails.application.credentials.dig(:smtp, :port),
  user_name:            Rails.application.credentials.dig(:smtp, :username),
  password:             Rails.application.credentials.dig(:smtp, :password),
  authentication:       Rails.application.credentials.dig(:smtp, :authentication) || "plain",
  enable_starttls_auto: Rails.application.credentials.dig(:smtp, :starttls) != false
}
```

**Do NOT hardcode any SMTP value — credentials only.** Test environment uses `:test` delivery method (no SMTP needed).

### `config/recurring.yml` — Fugit Cron Syntax
Solid Queue uses [Fugit](https://github.com/floraison/fugit) for cron parsing. Valid forms:
- `every day at 17:00` — fires daily at 17:00 UTC (midnight Bangkok)
- `every day at 01:00` — fires daily at 01:00 UTC (8:00am Bangkok)
- `every hour at minute 12` — already used for `clear_solid_queue_finished_jobs`

All recurring times must be expressed in UTC but anchored to Asia/Bangkok business meaning. Add new entries **under the existing `production:` key**:
```yaml
production:
  clear_solid_queue_finished_jobs:     # already exists
    command: "SolidQueue::Job.clear_finished_in_batches(sleep_between_batches: 0.3)"
    schedule: every hour at minute 12
  close_expired_registrations:
    class: CloseExpiredRegistrationsJob
    queue: default
    schedule: every day at 17:00      # midnight Asia/Bangkok (UTC+7 → 17:00 UTC)
  send_event_reminders:
    class: SendEventRemindersJob
    queue: default
    schedule: every day at 01:00      # 8:00am Asia/Bangkok (UTC+7 → 01:00 UTC)
```

### `config/queue.yml` — Dedicated Mailers Queue
Architecture specifies mailers use a `mailers` queue [Source: architecture.md § "Communication Patterns"]:
> "Mailers on a `mailers` queue; recurring tasks declared in `config/recurring.yml`."

Update `config/queue.yml` default section:
```yaml
default: &default
  dispatchers:
    - polling_interval: 1
      batch_size: 500
  workers:
    - queues: "mailers"
      threads: 2
      processes: 1
      polling_interval: 0.1
    - queues: "*"
      threads: 3
      processes: <%= ENV.fetch("JOB_CONCURRENCY", 1) %>
      polling_interval: 0.1
```

The `mailers` worker is listed first so mail jobs get dedicated threads and are not starved by other work.

### Job Idempotency Pattern
All jobs in this project **must be idempotent** (architecture rule). The stubs created in Task 6 should include a comment template showing the idempotency guard pattern that the implementing stories must follow:

```ruby
# frozen_string_literal: true

class SendRegistrationConfirmationJob < ApplicationJob
  queue_as :mailers

  # IDEMPOTENCY GUARD: Implementing story (3.2) must add a sent-at marker to prevent
  # duplicate sends if this job is retried or run more than once.
  # Example: return if registration.confirmation_sent_at.present?
  def perform(registration_id)
    raise NotImplementedError, "Implemented in Story 3.2"
  end
end
```

Key idempotency patterns for future implementing stories:
- Reminder jobs: check `reminder_sent_at` timestamp on booking/event
- Close jobs: check `registration_closed_at` — idempotent (closing a closed registration is a no-op)
- Confirmation jobs: check `confirmation_sent_at` on registration record

### `deliver_later` — Queue Assignment
All ActionMailer calls must use `deliver_later` (never `deliver_now` in request flow — architecture hard rule). The mailer queue is `mailers`. In stub mailers, use `queue_as :mailers` on the class, and when later implemented use `deliver_later(queue: "mailers")` or rely on the class-level `queue_as`.

**Set `queue_as :mailers` on `ApplicationMailer` itself** so all child mailers inherit it by default:
```ruby
class ApplicationMailer < ActionMailer::Base
  default from: -> { I18n.t("mailers.sender_display") }
  layout "mailer"
  queue_as :mailers   # ADD THIS — inherits to all child mailers
end
```

### Deferred Work Resolution — SMTP Kamal Secrets
The `_bmad-output/implementation-artifacts/deferred-work.md` explicitly notes: "SMTP_PASSWORD not in `.kamal/secrets` yet — deferred to Story 1.6." This story resolves that deferred item. Add to `.kamal/secrets`:
```
SMTP_PASSWORD=$SMTP_PASSWORD
```
And reference it in `config/deploy.yml` under the `env.secret` block (similar to how `SECRET_KEY_BASE` would be referenced). The actual credential is stored in Rails encrypted credentials for app-level use; the Kamal secret is for environment injection at deploy time if needed by the SMTP config path. Do NOT expose the actual password value in any committed file.

### Sender Display Name (FR-083)
The sender display name must be the **organization name**, not the app name. The `en.mailers.sender_display` key should be in `"Name <email>"` RFC 5322 format to carry both the display name and the from address. Example: `"ENVOCC Conference <noreply@conf.envocc.org>"`. The placeholder `"Conf Rails"` from Story 1.1 is insufficient — update to a proper placeholder with the RFC 5322 format. Rawinan will update the actual org name/email value.

### SMTP Security Rules (NFR-001)
- **Never commit SMTP credentials** — encrypted credentials only
- **Never log SMTP password** — Rails `filter_parameters` already masks `:password`; verify `:smtp_password` or similar is also masked if you add it to filter_parameter_logging.rb
- **Active Record Encryption for `SmtpSetting.password`** is Story 4.5 scope — do NOT create `SmtpSetting` here
- `config/credentials.yml.enc` is safe to reference in code but the `.enc` file contents are encrypted; `master.key` is gitignored

### Email Never Blocks a Transaction (FR-084)
The architecture defines: "Registration transaction **commits independently of the send** (FR-084)." This is guaranteed by `deliver_later` — the mailer is enqueued to Solid Queue after the request transaction commits. The dev agent must never call `deliver_now` inside a transaction block.

Correct pattern:
```ruby
# In a controller or service:
booking = Booking.create!(...)          # transaction commits
BookingMailer.confirmation(booking).deliver_later  # enqueued after commit
```

Wrong pattern (never do this):
```ruby
Booking.transaction do
  booking = Booking.create!(...)
  BookingMailer.confirmation(booking).deliver_now  # WRONG — blocks transaction
end
```

### Dead-Letter / Failed Jobs
`solid_queue_failed_executions` table exists (from `db/queue_schema.rb` in Story 1.1). When a job exhausts retries (5 attempts with polynomial backoff from Task 5), Solid Queue moves the job record to this table. The admin UI for viewing dead-letter jobs is out of scope for this story; it will be addressed in Epic 4 or a later story. For now, the table existence is sufficient per AC #1 ("dead-letter path").

### Project Structure — New Files This Story Creates

```
app/
├── jobs/
│   ├── application_job.rb                          # UPDATE — add retry/backoff config
│   ├── send_registration_confirmation_job.rb       # NEW stub (NotImplementedError)
│   ├── send_event_reminder_job.rb                  # NEW stub (NotImplementedError)
│   └── close_expired_registrations_job.rb          # NEW stub (NotImplementedError)
├── mailers/
│   ├── application_mailer.rb                       # UPDATE — add queue_as :mailers
│   ├── booking_mailer.rb                           # NEW stub (NotImplementedError)
│   └── registration_mailer.rb                      # NEW stub (NotImplementedError)
└── views/
    ├── booking_mailer/                             # NEW empty dir with .keep
    └── registration_mailer/                        # NEW empty dir with .keep
config/
├── queue.yml                                       # UPDATE — add dedicated mailers worker
├── recurring.yml                                   # UPDATE — add close + reminder entries
├── locales/
│   ├── en.yml                                      # UPDATE mailers.sender_display to RFC5322 format
│   └── th.yml                                      # UPDATE mirror key
└── environments/
    ├── production.rb                               # UPDATE — smtp_settings + delivery_method
    └── development.rb                              # UPDATE — set explicit delivery_method (not default smtp)
.kamal/
└── secrets                                         # UPDATE — add SMTP_PASSWORD entry (resolves deferred-work.md)
test/
├── test_helper.rb                                  # UPDATE — add ActiveJob::TestHelper include
├── mailers/
│   └── application_mailer_test.rb                  # NEW
├── jobs/
│   └── application_job_test.rb                     # NEW (test/jobs/ dir doesn't exist — create it)
└── integration/
    └── email_infrastructure_test.rb                # NEW
```

### Architecture Compliance Checklist for Dev Agent
- [ ] All mail calls use `deliver_later` (never `deliver_now` in request context)
- [ ] `ApplicationMailer` has `queue_as :mailers` so all child mailers inherit it
- [ ] All new job classes extend `ApplicationJob` (not `ActiveJob::Base` directly)
- [ ] Recurring entries use UTC times anchored to Bangkok meaning
- [ ] No SMTP credentials appear in source code (credentials.yml.enc only, .kamal/secrets reference only)
- [ ] `i18n-tasks health` passes (no new literal strings without I18n keys)
- [ ] No new user-facing copy hardcoded — all through `t('...')` keys
- [ ] All job stubs are idempotent-ready (guard comment pattern)
- [ ] `config/locales/th.yml` mirrors `en.yml` key-for-key
- [ ] Pundit: no new controllers introduced in this story (background infra only)
- [ ] `test_helper.rb` includes `ActiveJob::TestHelper` in `ActiveSupport::TestCase`
- [ ] Deferred-work.md SMTP_PASSWORD item is resolved (`.kamal/secrets` updated)
- [ ] `development.rb` has explicit `delivery_method` set (not defaulting to `:smtp`)

### Anti-Patterns to Avoid
- **DO NOT** create `SmtpSetting` model — that is Story 4.5
- **DO NOT** implement actual job logic in stubs — just `raise NotImplementedError`
- **DO NOT** call `deliver_now` anywhere in this story
- **DO NOT** add `letter_opener` gem or any dev email preview gem unless already in the Gemfile (check before adding)
- **DO NOT** create mailer views with actual content — stubs only (.keep files)
- **DO NOT** commit credentials of any kind — test assertions use `:test` delivery method; `.kamal/secrets` gets a reference key only, not the actual value
- **DO NOT** change `config/environments/test.rb` mailer settings (already correct)
- **DO NOT** add redis — Solid Queue is DB-backed (no Redis in this project)
- **DO NOT** leave `development.rb` with no explicit `delivery_method` — the Rails default without one is `:smtp`, which will attempt real SMTP sends in dev and likely fail or expose creds

### Previous Story Learnings (from Story 1.1)
- RuboCop Rails Omakase runs automatically — pay attention to spacing and style in YAML and Ruby files
- `test/jobs/` directory does not exist yet — you must create it (with `test/jobs/.keep` or by adding the first test file)
- The `Procfile.dev` was patched in Story 1.1 to start `bin/jobs` — verify it still has `jobs: bin/jobs` before assuming background jobs run locally
- `db/queue_schema.rb` contains the Solid Queue schema (including `solid_queue_failed_executions`) — already applied to the database; do NOT run migrations for this table again
- `test/test_helper.rb` uses `include ActiveJob::TestHelper` — check if it already includes this; if not, add it or include in individual test files
- Story 1.1 noted PostgreSQL server was running on port 5433 locally — confirm DB connection before running tests

### Testing Requirements
- Testing framework: **Minitest only** (no RSpec — explicit architecture decision)
- Use `ActiveJob::TestHelper` for job queue assertions (`assert_enqueued_with`, `perform_enqueued_jobs`)
- Use `ActionMailer::Base.deliveries` for mail delivery assertions in `:test` mode
- No live SMTP in tests — `config/environments/test.rb` uses `:test` delivery method
- Fixtures: no real PII, no credentials
- New test directory: `test/jobs/` (create if doesn't exist)
- System tests: not needed for this story (no UI changes)

### References

- Story requirements and FRs [Source: `_bmad-output/planning-artifacts/epics.md` § "Story 1.6: Email & background-job infrastructure"]
- FR-080, FR-083, FR-084 requirements [Source: `_bmad-output/planning-artifacts/epics.md` § "F9 — Email & Notifications"]
- Email reliability architecture decision (C-4/H-5) [Source: `_bmad-output/planning-artifacts/architecture.md` § "API & Communication Patterns"]
- Job naming conventions (`XxxJob`, idempotent, `mailers` queue) [Source: `_bmad-output/planning-artifacts/architecture.md` § "Communication Patterns"]
- Queue and recurring job config patterns [Source: `_bmad-output/planning-artifacts/architecture.md` § "API & Communication Patterns"]
- `ApplicationMailer` sender display name (FR-083) [Source: `_bmad-output/planning-artifacts/architecture.md` § "API & Communication Patterns"]
- SMTP-only constraint (no third-party services) [Source: `_bmad-output/planning-artifacts/architecture.md` § "Technical Constraints & Dependencies"]
- Security/secrets hard rules [Source: `_bmad-output/planning-artifacts/architecture.md` § "Security & Secrets (hard rule)"]
- Story 1.1 groundwork for Solid Queue and ApplicationMailer [Source: `_bmad-output/implementation-artifacts/1-1-project-initialization-platform-scaffold.md` § "Dev Notes / Solid Queue Configuration"]
- Story 1.1 review patch: `Procfile.dev` now includes `jobs: bin/jobs` [Source: `_bmad-output/implementation-artifacts/1-1-project-initialization-platform-scaffold.md` § "Review Findings"]
- SMTP_PASSWORD Kamal secrets deferred item (resolve in this story) [Source: `_bmad-output/implementation-artifacts/deferred-work.md`]
- Asia/Bangkok timezone rules for cron [Source: `_bmad-output/planning-artifacts/architecture.md` § "Data Architecture"]
- i18n lazy-scoped key rules [Source: `_bmad-output/planning-artifacts/architecture.md` § "Naming Patterns"]
- Enforcement guidelines (deliver_later, credentials, i18n-tasks) [Source: `_bmad-output/planning-artifacts/architecture.md` § "Enforcement Guidelines"]
- Job directory structure [Source: `_bmad-output/planning-artifacts/architecture.md` § "Complete Project Directory Structure"]

### ATDD Artifacts

- Checklist: `_bmad-output/test-artifacts/atdd/atdd-checklist-1-6-email-background-job-infrastructure.md`
- Mailer unit tests: `test/mailers/application_mailer_test.rb`
- Job unit tests: `test/jobs/application_job_test.rb`
- Integration tests: `test/integration/email_infrastructure_test.rb`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

### File List
