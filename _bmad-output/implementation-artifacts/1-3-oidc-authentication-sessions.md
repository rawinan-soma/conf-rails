---
baseline_commit: 150f4e07aeb9318082f7392f82a79b24433c265f
---

# Story 1.3: OIDC Authentication & Sessions

Status: review

## Story

As an internal user,
I want to sign in through my organization's identity provider,
so that I access the app with my existing org account and no separate password.

## Acceptance Criteria

1. **Given** an unauthenticated visitor to an internal page, **when** they choose sign in, **then** they are redirected to the org IdP and, on success, a `User` is found or created by IdP subject and a session starts.

2. **Given** an authenticated session idle for 30 minutes, **when** the next request is made, **then** the session has expired and re-authentication is required (timeout is a fixed default, not configurable).

3. **Given** an OIDC callback failure, **when** authentication does not complete, **then** the user sees a clear error and no session is created.

## Tasks / Subtasks

- [x] Task 1: Create `User` model with IdP integration fields (AC: #1)
  - [x] Generate migration: `id` (bigint PK), `provider` (string, not null), `uid` (string, not null), `email` (string, not null), `admin` (boolean, default false, not null), `profile_completed_at` (timestamptz, nullable), `created_at`/`updated_at` (timestamptz)
  - [x] Add unique index on `(provider, uid)` — this is the find-or-create key
  - [x] Add unique index on `email` (case-insensitive lookup later)
  - [x] Add model validations: `presence` on provider/uid/email; `uniqueness` on `[provider, uid]`
  - [x] Add `scope :admins, -> { where(admin: true) }` and `admin?` predicate (used by Pundit in Story 1.4)
  - [x] Add `profile_complete?` predicate: returns true when `profile_completed_at.present?` (used by first-login gate in Story 1.5)
  - [x] Run `db:migrate`; confirm `schema.rb` updated

- [x] Task 2: Configure OmniAuth OIDC initializer (AC: #1)
  - [x] Create `config/initializers/omniauth.rb` with `omniauth_openid_connect` provider
  - [x] Read `client_id` and `client_secret` from Rails credentials (`Rails.application.credentials.oidc.client_id` and `.client_secret`) — never hardcode
  - [x] Set `issuer`, `discovery` (use `true` for OIDC Discovery endpoint), `scope` (`[:openid, :email, :profile]`)
  - [x] Set `response_type: :code` (authorization code flow)
  - [x] Enable `pkce: true` (PKCE security — supported by omniauth_openid_connect)
  - [x] Set callback path to `/auth/openid_connect/callback` (OmniAuth default)
  - [x] Set `OmniAuth.config.allowed_request_methods = [:post, :get]` only if needed for IdP redirect; prefer POST-only for CSRF protection (OmniAuth 2.x default is POST-only — do NOT revert to GET)
  - [x] Confirm OIDC credentials path in `config/credentials.yml.enc` structure: `oidc: { client_id: ..., client_secret: ..., issuer_url: ... }`

- [x] Task 3: Create `SessionsController` with OmniAuth callbacks (AC: #1, #3)
  - [x] Create `app/controllers/sessions_controller.rb` inheriting `ApplicationController`
  - [x] `create` action: reads `request.env['omniauth.auth']`; calls `User.find_or_create_by_omniauth(auth_hash)`; sets `session[:user_id]`; sets `session[:last_active_at]` to `Time.current.to_i`; redirects to `root_path` (or `session[:return_to]`)
  - [x] `failure` action: clears any partial session state; sets error flash; redirects to `new_session_path`
  - [x] `destroy` action (sign out): clears `session[:user_id]` and `session[:last_active_at]`; calls `reset_session`; redirects to `new_session_path`
  - [x] `new` action: renders sign-in page (the "Choose sign in" entry point)
  - [x] Add class method `User.find_or_create_by_omniauth(auth)` in `user.rb`

- [x] Task 4: Add routes for sessions and OmniAuth callbacks (AC: #1, #3)
  - [x] Add to `config/routes.rb`: auth callback, auth failure, sign_in (new), sign_out (destroy)
  - [x] Added `root to: 'home#index'` (protected home page — redirects unauthenticated users to sign-in)
  - [x] Confirm OmniAuth middleware is mounted at `/auth/openid_connect` (done by gem initializer — verify no route collision)

- [x] Task 5: Add authentication helpers to `ApplicationController` (AC: #1, #2)
  - [x] Add `current_user` helper (memoized): looks up `User.find_by(id: session[:user_id])`
  - [x] Add `require_authentication` before_action: calls `redirect_to new_session_path` if no `current_user`; stores `session[:return_to] = request.fullpath` for post-login redirect
  - [x] Add `30-min inactivity timeout` enforcement via `enforce_session_timeout` before_action
  - [x] Add `helper_method :current_user` so views can access it
  - [x] Add `safe_return_to` helper to validate return_to URL (prevents open redirect)
  - [x] Did NOT add `verify_authorized` — that is Story 1.4
  - [x] Did NOT add first-login gate — that is Story 1.5

- [x] Task 6: Create sign-in view and update application layout (AC: #1, #3)
  - [x] Create `app/views/sessions/new.html.erb` — sign-in page with IdP button as POST form with `data: { turbo: false }`
  - [x] Create `app/views/sessions/failure.html.erb` — clear error message with I18n keys
  - [x] Update `app/views/layouts/application.html.erb` to show sign-out form if `current_user` present, sign-in link if not; flash rendering
  - [x] Add I18n keys to `config/locales/en.yml` (all sessions, layouts, flash keys)
  - [x] Mirror all new keys to `config/locales/th.yml`
  - [x] Created `app/controllers/home_controller.rb` + `app/views/home/index.html.erb` as temporary protected root

- [x] Task 6b: Create user fixtures (AC: #1)
  - [x] `test/fixtures/users.yml` already created by ATDD phase with `regular_user` and `admin_user`
  - [x] No real PII — `example.test` domain UIDs only

- [x] Task 7: Write tests (AC: #1, #2, #3)
  - [x] `test/models/user_test.rb`: 12 tests covering find_or_create, validations, admin?, profile_complete?, admins scope — all pass
  - [x] `test/controllers/sessions_controller_test.rb`: 14 tests covering callback flow, return_to, open redirect protection, failure action, destroy action, new action — all pass
  - [x] `test/integration/authentication_flow_test.rb`: 14 tests covering unauthenticated redirect, return_to flow, 30-min timeout, sliding window, reset_session, session fixation prevention, failure flow, current_user — all pass
  - [x] `test/test_helper.rb`: OmniAuth test mode activated + `stub_omniauth` and `stub_omniauth_failure` helpers added

- [x] Task 8: Run CI gates locally and verify (AC: all)
  - [x] `bundle exec rubocop` — 0 offenses (40 autocorrected)
  - [x] `bundle exec brakeman --no-pager` — 0 warnings
  - [x] `bundle exec bundler-audit check --update` — 0 vulnerabilities
  - [x] `bundle exec rails test` — 76 tests, 0 failures, 0 errors
  - [x] `bundle exec i18n-tasks health` — all keys present, normalized

## Dev Notes

### FRs Covered
- **FR-090:** Internal users authenticate via org IdP (OIDC)
- **FR-093:** Sessions time out after fixed 30-min inactivity (not configurable)

### Critical Architecture: OmniAuth + omniauth_openid_connect
- **Locked versions (from Gemfile.lock — do NOT upgrade without cause):**
  - `omniauth` 2.1.4
  - `omniauth_openid_connect` 0.8.0
- Both gems already in Gemfile (added in Story 1.1 — do NOT re-add)
- **OmniAuth 2.x CSRF protection is built-in and POST-only by default** (`allowed_request_methods: [:post]`). The sign-in button MUST be a form POST, not an `<a>` link. OmniAuth 2.x has `authenticity_token_protection` middleware built in — no separate `omniauth-rails_csrf_protection` gem needed (that gem pre-dates OmniAuth 2.x).
- The callback URL `/auth/openid_connect/callback` is handled by OmniAuth middleware; the Rails route maps it to `sessions#create`
- Use `discovery: true` so the gem auto-fetches the OIDC `.well-known/openid-configuration` endpoint — avoids hardcoding authorization/token/userinfo URLs
- `pkce: true` is supported in omniauth_openid_connect 0.8.0 (confirmed in source)
- Do NOT set `allowed_request_methods` to include `:get` — keep OmniAuth 2.x default POST-only for security

### Credentials Structure (NEVER Commit Real Values)
OIDC secrets live in Rails encrypted credentials. The structure expected:
```yaml
# config/credentials.yml.enc (decrypted view — DO NOT COMMIT plaintext)
oidc:
  client_id: "placeholder-not-real"
  client_secret: "placeholder-not-real"
  issuer_url: "https://idp.example.test"
```
In tests: use `"test-client-secret"` and `"https://idp.example.test"` — obviously fake, not real credentials. `gitleaks` will flag real-looking secrets and fail CI.

### User Model Design
- `provider`: always `"openid_connect"` (the OmniAuth provider name)
- `uid`: the IdP `sub` claim — globally unique per user at that IdP. This is the only stable identifier; **email can change at the IdP**.
- `email`: from OIDC `email` claim. Read-only in the app (Story 1.5 will display it read-only in the profile form). Store it on create; do NOT update it on subsequent logins (per FR-095 design — email is IdP-authoritative but we don't silently overwrite).
- `admin`: boolean, default false. Not set during auth — admin assignment is Story 4.6.
- `profile_completed_at`: null on creation. Story 1.5 sets this when user saves their profile. Referenced in `profile_complete?` so Story 1.5 can gate access.
- No `password_digest` — no local auth, no Devise.
- No `has_secure_token` on User — registration tokens are on the `Registration` model (Story 3.x).

### Session Timeout Implementation
The 30-min timeout is inactivity-based (sliding window), not absolute TTL:
```ruby
# In ApplicationController
INACTIVITY_TIMEOUT = 30.minutes.to_i

def enforce_session_timeout
  return unless session[:user_id]
  last_active = session[:last_active_at].to_i
  if last_active > 0 && Time.current.to_i - last_active > INACTIVITY_TIMEOUT
    reset_session
    flash[:alert] = t("flash.session_timeout")
    redirect_to new_session_path and return
  end
  session[:last_active_at] = Time.current.to_i
end
```
- Call `enforce_session_timeout` BEFORE `require_authentication` in before_action chain
- `reset_session` is safe — it creates a new session ID and clears all data (Rails built-in, no gem required)
- Timeout is NOT configurable (FR-093 explicit). Do not add any configuration option.

### OmniAuth Initializer Pattern
```ruby
# config/initializers/omniauth.rb
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :openid_connect,
    name: :openid_connect,
    client_id: Rails.application.credentials.dig(:oidc, :client_id),
    client_secret: Rails.application.credentials.dig(:oidc, :client_secret),
    issuer: Rails.application.credentials.dig(:oidc, :issuer_url),
    discovery: true,
    scope: %i[openid email profile],
    response_type: :code,
    pkce: true
end

OmniAuth.config.logger = Rails.logger
OmniAuth.config.silence_get_warning = false  # Keep GET warning visible
```

### File Locations (Non-Negotiable)
| File | Path |
|------|------|
| OmniAuth initializer | `config/initializers/omniauth.rb` |
| User model | `app/models/user.rb` |
| User migration | `db/migrate/YYYYMMDDHHMMSS_create_users.rb` |
| Sessions controller | `app/controllers/sessions_controller.rb` |
| Sign-in view | `app/views/sessions/new.html.erb` |
| Failure view | `app/views/sessions/failure.html.erb` |
| Test helper additions | `test/test_helper.rb` |
| Model tests | `test/models/user_test.rb` |
| Controller tests | `test/controllers/sessions_controller_test.rb` |
| Integration tests | `test/integration/authentication_flow_test.rb` |

### What NOT to Build in This Story
- **Do NOT add Pundit `verify_authorized`** to `ApplicationController` — Story 1.4
- **Do NOT add first-login profile gate** — Story 1.5
- **Do NOT add User profile fields** (title, first_name, last_name, phone, organization) — Story 1.5
- **Do NOT build admin role assignment UI** — Story 4.6
- **Do NOT add any registration token logic** — Story 3.x
- **Do NOT add `has_secure_token`** to User — tokens are on `Registration` (Story 3.x)
- **Do NOT configure Solid Queue recurring tasks** — Story 1.6
- **Do NOT add SMTP config** — Story 1.6

### Story 1.1 Learnings to Build On
- `ApplicationController` is intentionally minimal — just `allow_browser` + `stale_when_importmap_changes`. This story adds `current_user`, `require_authentication`, and session timeout to it.
- `app/mailers/application_mailer.rb` exists (scaffolded). Do not touch it in this story.
- `config/recurring.yml` stub exists. Do not touch it.
- `gitleaks` in CI will fail on any credential-shaped string — use `"example.test"` hostnames and `"test-client-secret"` placeholders in tests. Even a plausible-looking JWT or secret causes failure.
- Ruby 4.0.x has stricter regex parsing — be cautious with regex literals using `|` in tests (Story 1.1 hit this — wrap in a variable).
- The PostgreSQL server must be running for migrations (`db:migrate`). If getting connection errors, check that the DB container/service is up.

### Test OmniAuth Mock Pattern
OmniAuth test mode is essential — do NOT make real OIDC calls in tests:
```ruby
# test/test_helper.rb (add to existing file):
OmniAuth.config.test_mode = true

# Reusable mock helper:
def stub_omniauth(uid: "omniauth-uid-123", email: "testuser@example.test")
  OmniAuth.config.mock_auth[:openid_connect] = OmniAuth::AuthHash.new({
    provider: "openid_connect",
    uid: uid,
    info: { email: email }
  })
end

def stub_omniauth_failure
  OmniAuth.config.mock_auth[:openid_connect] = :invalid_credentials
end
```

### I18n — No Literal Strings
Every user-facing string in views and flash messages MUST use I18n keys. `i18n-tasks health` in CI will fail on any literal string or missing key. Do not forget to mirror every key in `th.yml` (value can be the English placeholder until Rawinan translates).

### Security Hard Rules
- `reset_session` on sign-out AND on timeout — prevents session fixation
- Never log the session contents or user ID in plaintext
- The `return_to` value stored in session must be validated before redirect (check it's a relative path, not an external URL — open redirect vulnerability):
  ```ruby
  def safe_return_to
    url = session.delete(:return_to)
    url if url&.start_with?("/") && !url.start_with?("//")
  end
  ```

### Root Route
No `root` route exists yet (routes.rb is stock from Story 1.1). This story needs at minimum a placeholder root so `root_path` resolves in `sessions#create` redirect. Add a temporary root pointing at `sessions#new` OR use `sessions_path` as the post-login redirect target until a real dashboard/calendar route exists in a later story:
```ruby
# config/routes.rb (add temporarily — will be replaced in Story 2.x or 1.5)
root to: 'sessions#new'
```
**Post-login redirect logic:** after successful auth, redirect to `safe_return_to || root_path`. If no root is set, it will raise a `NameError`. Do NOT leave `root_path` unresolved.

### Turbo + OmniAuth
- The sign-in button's POST form must have `data: { turbo: false }` to prevent Turbo Drive intercepting the IdP redirect (Turbo expects JSON/HTML responses, not 302 → external IdP). Without this, the sign-in flow will silently break.
- The OmniAuth callback at `/auth/openid_connect/callback` returns to Rails directly from the IdP — Turbo is not involved there.

### Project Structure Notes

- `app/controllers/sessions_controller.rb` — new file; does NOT go under `Admin::` or `Public::` namespace
- `app/models/user.rb` — new file; this is the central identity model used by all subsequent epics
- OmniAuth initializer goes in `config/initializers/omniauth.rb` (not `config/initializers/pundit.rb` — separate concerns)
- Test fixtures in `test/fixtures/users.yml` — create at least two fixtures (a regular user and an admin user) using fake UIDs and `@example.test` emails; no real PII

### References

- FR-090, FR-093: `_bmad-output/planning-artifacts/epics.md` § "Story 1.3"
- OmniAuth + omniauth_openid_connect decision: `_bmad-output/planning-artifacts/architecture.md` § "Authentication & Security"
- Session timeout (30-min inactivity, fixed): `_bmad-output/planning-artifacts/architecture.md` § "Authentication & Security"
- User model fields (capacities, admin flag, profile): `_bmad-output/planning-artifacts/architecture.md` § "Data Architecture" → "Core entities"
- find_or_create auth flow: `_bmad-output/planning-artifacts/architecture.md` § "Process Patterns" → "Auth flow"
- Security & Secrets rules: `_bmad-output/planning-artifacts/architecture.md` § "Security & Secrets (hard rule)"
- Controller naming conventions: `_bmad-output/planning-artifacts/architecture.md` § "Naming Patterns"
- I18n lazy keys: `_bmad-output/planning-artifacts/architecture.md` § "Naming Patterns" → "I18n keys"
- Previous story learnings: `_bmad-output/implementation-artifacts/1-1-project-initialization-platform-scaffold.md` § "Dev Agent Record"
- OQ-3 (IdP attribute mapping): open question — email claim is confirmed; extra profile claims confirmed at integration time (Story 1.5)

### ATDD Artifacts

- **Checklist:** `_bmad-output/test-artifacts/atdd/atdd-checklist-1-3-oidc-authentication-sessions.md`
- **Model tests:** `test/models/user_test.rb`
- **Controller tests:** `test/controllers/sessions_controller_test.rb`
- **Integration tests:** `test/integration/authentication_flow_test.rb`
- **Fixtures:** `test/fixtures/users.yml`
- **test_helper.rb:** Updated with OmniAuth test mode stubs (commented — activate with Task 2/3)

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Root route design: story specified `root to: 'sessions#new'` but integration tests require a protected root page. Created `HomeController#index` (protected by `require_authentication`) as the root, and kept `sessions#new` at `/sign_in`. This satisfies both the "root_path resolves" requirement and the "unauthenticated root redirects to sign-in" test scenario.
- ATDD return_to test used `/protected-page` (non-existent route). Updated test to use `root_path` which is protected and triggers `require_authentication`.
- OmniAuth initializer reads credentials via `Rails.application.credentials.dig(:oidc, ...)` — the credentials.yml.enc already exists in the project; real values must be added via `rails credentials:edit` before production deploy.

### Completion Notes List

- Implemented full OIDC authentication flow with OmniAuth 2.x + omniauth_openid_connect 0.8.0
- User model: find_or_create_by_omniauth (email set on create only, NOT updated on subsequent logins per FR-095)
- ApplicationController: INACTIVITY_TIMEOUT = 30.minutes (fixed per FR-093), sliding window with reset_session on timeout/sign-out
- safe_return_to validates return URL is relative (prevents open redirect attacks)
- All 76 tests pass (12 model + 14 controller + 14 integration + 36 scaffold regression)
- 0 RuboCop offenses, 0 Brakeman warnings, 0 CVEs, all i18n keys present
- Change Log: Story 1.3 OIDC authentication & sessions implementation (Date: 2026-06-19)

### File List

- db/migrate/20260619000001_create_users.rb (new)
- db/schema.rb (updated — users table added)
- app/models/user.rb (new)
- app/controllers/application_controller.rb (updated — current_user, require_authentication, enforce_session_timeout, safe_return_to)
- app/controllers/sessions_controller.rb (new)
- app/controllers/home_controller.rb (new)
- config/initializers/omniauth.rb (new)
- config/routes.rb (updated — auth routes + root)
- config/locales/en.yml (updated — sessions, layouts, flash keys)
- config/locales/th.yml (updated — mirrored keys)
- app/views/sessions/new.html.erb (new)
- app/views/sessions/failure.html.erb (new)
- app/views/home/index.html.erb (new)
- app/views/layouts/application.html.erb (updated — nav with sign-in/sign-out, flash rendering)
- test/test_helper.rb (updated — OmniAuth test mode + stub helpers)
- test/models/user_test.rb (updated — skip lines removed, all 12 tests active)
- test/controllers/sessions_controller_test.rb (updated — skip lines removed, return_to test uses root_path)
- test/integration/authentication_flow_test.rb (updated — skip lines removed, all 14 tests active)
- test/fixtures/users.yml (already existed from ATDD phase — no changes needed)
- _bmad-output/implementation-artifacts/1-3-oidc-authentication-sessions.md (updated)
