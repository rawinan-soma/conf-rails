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
storyId: '1.6'
storyKey: 1-6-email-background-job-infrastructure
storyFile: _bmad-output/implementation-artifacts/1-6-email-background-job-infrastructure.md
atddChecklistPath: _bmad-output/test-artifacts/atdd/atdd-checklist-1-6-email-background-job-infrastructure.md
generatedTestFiles:
  - test/mailers/application_mailer_test.rb
  - test/jobs/application_job_test.rb
  - test/integration/email_infrastructure_test.rb
inputDocuments:
  - _bmad-output/implementation-artifacts/1-6-email-background-job-infrastructure.md
  - _bmad/tea/config.yaml
  - test/test_helper.rb
  - app/mailers/application_mailer.rb
  - app/jobs/application_job.rb
  - config/locales/en.yml
---

# ATDD Checklist: Story 1.6 — Email & Background-Job Infrastructure

## TDD Red Phase (Current)

Red-phase test scaffolds generated. All tests are marked with `skip` and will fail when activated until implementation is complete.

- Backend Tests (Minitest): 14 tests (all skipped)
  - Mailer unit tests: 3 tests
  - Job unit tests: 6 tests
  - Integration tests: 9 tests (including 2 InlineTestMailer pipeline tests)
- E2E Tests: N/A (backend-only story — no UI changes)

## Acceptance Criteria Coverage

| AC | Description | Test File | Test Name | Priority |
|----|-------------|-----------|-----------|----------|
| AC #1 | Solid Queue + scheduler operational; dead-letter path visible | `test/jobs/application_job_test.rb` | `solid_queue_failed_executions table exists` | P1 |
| AC #1 | Stub job classes load without NameError at boot | `test/jobs/application_job_test.rb` | `SendRegistrationConfirmationJob loads without NameError` | P1 |
| AC #1 | Stub job classes load without NameError at boot | `test/jobs/application_job_test.rb` | `SendEventReminderJob loads without NameError` | P1 |
| AC #1 | Stub job classes load without NameError at boot | `test/jobs/application_job_test.rb` | `CloseExpiredRegistrationsJob loads without NameError` | P1 |
| AC #1 | Retry/backoff configured on ApplicationJob | `test/jobs/application_job_test.rb` | `ApplicationJob retries on StandardError` | P0 |
| AC #1 | Discard on deserialization error | `test/jobs/application_job_test.rb` | `ApplicationJob discards on DeserializationError` | P1 |
| AC #1 | Mailer jobs route to dedicated mailers queue | `test/integration/email_infrastructure_test.rb` | `ApplicationMailer jobs route to mailers queue` | P1 |
| AC #2 | `deliver_later` does NOT immediately deliver | `test/integration/email_infrastructure_test.rb` | `deliver_later enqueues mail without immediate delivery` | P0 |
| AC #2 | After `deliver_later`, `perform_enqueued_jobs` delivers | `test/integration/email_infrastructure_test.rb` | `perform_enqueued_jobs delivers the enqueued mail` | P0 |
| AC #2 | Transaction commits independently of mail send | `test/integration/email_infrastructure_test.rb` | `deliver_later does not block the triggering transaction` | P0 |
| AC #3 | `ApplicationMailer.default[:from]` uses i18n key (lambda) | `test/mailers/application_mailer_test.rb` | `default from uses mailers.sender_display i18n key` | P1 |
| AC #3 | `from:` contains "ENVOCC" organization name | `test/mailers/application_mailer_test.rb` | `default from contains organization name ENVOCC` | P0 |
| AC #3 | `ApplicationMailer` routes to mailers queue | `test/mailers/application_mailer_test.rb` | `ApplicationMailer routes to mailers queue` | P1 |
| AC #3 | Delivered mail carries org name in From header | `test/integration/email_infrastructure_test.rb` | `delivered mail carries org name in From header` | P1 |

## Test-to-Task Mapping

| Task | Description | Tests Activated |
|------|-------------|-----------------|
| Task 1 | Wire ActionMailer to SMTP + dev delivery_method | `email_infrastructure_test.rb` — pipeline tests |
| Task 2 | Sender display name RFC 5322 + i18n keys | `application_mailer_test.rb` — all 3 tests + AC #3 integration tests |
| Task 3 | Solid Queue config/queue.yml mailers worker | `email_infrastructure_test.rb` — `mailers queue` test |
| Task 4 | config/recurring.yml entries | Manual verification (no test; Fugit cron syntax check) |
| Task 5 | ApplicationJob retry/backoff | `application_job_test.rb` — retry + discard tests |
| Task 6 | Stub job classes | `application_job_test.rb` — NameError + NotImplementedError tests |
| Task 7 | Stub mailer classes | `email_infrastructure_test.rb` — BookingMailer + RegistrationMailer tests |
| Task 8 | Tests themselves (this file) | N/A (ATDD precedes implementation) |
| Task 9 | CI: rubocop + brakeman + i18n-tasks + rails test | All tests pass in green phase |

## Next Steps (Task-by-Task Activation)

During implementation of each task:

1. Find the `skip` call(s) for the current task (see mapping above).
2. Remove the `skip` line from the test method.
3. Run: `bundle exec rails test <test_file>`
4. Verify the test **FAILS** first (red phase confirmed).
5. Implement the feature/configuration.
6. Run tests again — verify they **PASS** (green phase).
7. Commit passing tests.

**Full test suite after all tasks:**

```bash
bundle exec rails test test/mailers/application_mailer_test.rb
bundle exec rails test test/jobs/application_job_test.rb
bundle exec rails test test/integration/email_infrastructure_test.rb
```

## Key Risks & Assumptions

- `ActiveJob::TestHelper` is NOT currently included in `test/test_helper.rb`. **Task 8 must add it** before job/integration tests will work without individual includes.
- `InlineTestMailer` (defined inline in `email_infrastructure_test.rb`) will render an empty body unless a view or `render plain:` block is provided — the current scaffold uses `render plain:`.
- `BookingMailer.confirmation(stub)` will raise `NotImplementedError` from the stub — the integration tests that use it do NOT call `deliver_later` on stub mailers directly; they assert the class existence only.
- `test/jobs/` directory did not exist — it has been created.
- Story 1.1 confirmed: `config/environments/test.rb` uses `delivery_method: :test` — no SMTP needed in tests.
- `parallelize(workers: :number_of_processors)` in `test_helper.rb` may cause flakiness with `ActionMailer::Base.deliveries` (shared mutable state). If tests are flaky, add `parallelize(workers: 1)` override in `EmailInfrastructureTest`.

## Implementation Guidance

Files to create/modify (per story tasks):

- `app/mailers/application_mailer.rb` — add `queue_as :mailers`
- `app/mailers/booking_mailer.rb` — new stub
- `app/mailers/registration_mailer.rb` — new stub
- `app/jobs/application_job.rb` — add retry/backoff
- `app/jobs/send_registration_confirmation_job.rb` — new stub
- `app/jobs/send_event_reminder_job.rb` — new stub
- `app/jobs/close_expired_registrations_job.rb` — new stub
- `config/locales/en.yml` — update `mailers.sender_display` to RFC 5322 format
- `config/locales/th.yml` — mirror update
- `config/queue.yml` — add mailers worker
- `config/recurring.yml` — add close + reminder entries
- `config/environments/production.rb` — SMTP settings
- `config/environments/development.rb` — explicit delivery_method
- `test/test_helper.rb` — add `include ActiveJob::TestHelper`
- `.kamal/secrets` — add SMTP_PASSWORD reference

## ATDD Artifacts

- Checklist: `_bmad-output/test-artifacts/atdd/atdd-checklist-1-6-email-background-job-infrastructure.md`
- Mailer unit tests: `test/mailers/application_mailer_test.rb`
- Job unit tests: `test/jobs/application_job_test.rb`
- Integration tests: `test/integration/email_infrastructure_test.rb`
