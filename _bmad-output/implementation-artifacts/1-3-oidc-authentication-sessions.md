# Story 1.3: OIDC Authentication & Sessions

Status: ready-for-dev

## Story

As an internal user,
I want to sign in through my organization's identity provider,
so that I access the app with my existing org account and no separate password.

## Acceptance Criteria

1. **Given** an unauthenticated visitor to an internal page, **when** they choose sign in, **then** they are redirected to the org IdP and, on success, a `User` is found or created by IdP subject and a session starts.

2. **Given** an authenticated session idle for 30 minutes, **when** the next request is made, **then** the session has expired and re-authentication is required (timeout is a fixed default, not configurable).

3. **Given** an OIDC callback failure, **when** authentication does not complete, **then** the user sees a clear error and no session is created.

## Tasks / Subtasks

- [ ] Task 1: Create `User` model with IdP integration fields (AC: #1)
  - [ ] Generate migration: `id` (bigint PK), `provider` (string, not null), `uid` (string, not null), `email` (string, not null), `admin` (boolean, default false, not null), `profile_completed_at` (timestamptz, nullable), `created_at`/`updated_at` (timestamptz)
  - [ ] Add unique index on `(provider, uid)` — this is the find-or-create key
  - [ ] Add unique index on `email` (case-insensitive lookup later)
  - [ ] Add model validations: `presence` on provider/uid/email; `uniqueness` on `[provider, uid]`
  - [ ] Add `scope :admins, -> { where(admin: true) }` and `admin?` predicate (used by Pundit in Story 1.4)
  - [ ] Add `profile_complete?` predicate: returns true when `profile_completed_at.present?` (used by first-login gate in Story 1.5)
  - [ ] Run `db:migrate`; confirm `schema.rb` updated

- [ ] Task 2: Configure OmniAuth OIDC initializer (AC: #1)
  - [ ] Create `config/initializers/omniauth.rb` with `omniauth_openid_connect` provider
  - [ ] Read `client_id` and `client_secret` from Rails credentials (`Rails.application.credentials.oidc.client_id` and `.client_secret`) — never hardcode
  - [ ] Set `issuer`, `discovery` (use `true` for OIDC Discovery endpoint), `scope` (`[:openid, :email, :profile]`)
  - [ ] Set `response_type: :code` (authorization code flow)
  - [ ] Enable `pkce: true` (PKCE security — supported by omniauth_openid_connect)
  - [ ] Set callback path to `/auth/openid_connect/callback` (OmniAuth default)
  - [ ] Set `OmniAuth.config.allowed_request_methods = [:post, :get]` only if needed for IdP redirect; prefer POST-only for CSRF protection (OmniAuth 2.x default is POST-only — do NOT revert to GET)
  - [ ] Confirm OIDC credentials path in `config/credentials.yml.enc` structure: `oidc: { client_id: ..., client_secret: ..., issuer_url: ... }`

- [ ] Task 3: Create `SessionsController` with OmniAuth callbacks (AC: #1, #3)
  - [ ] Create `app/controllers/sessions_controller.rb` inheriting `ApplicationController`
  - [ ] `create` action: reads `request.env['omniauth.auth']`; calls `User.find_or_create_by_omniauth(auth_hash)`; sets `session[:user_id]`; sets `session[:last_active_at]` to `Time.current.to_i`; redirects to `root_path` (or `session[:return_to]`)
  - [ ] `failure` action: clears any partial session state; sets error flash; redirects to `new_session_path`
  - [ ] `destroy` action (sign out): clears `session[:user_id]` and `session[:last_active_at]`; calls `reset_session`; redirects to `new_session_path`
  - [ ] `new` action: renders sign-in page (the "Choose sign in" entry point)
  - [ ] Add class method `User.find_or_create_by_omniauth(auth)` in `user.rb`:
    ```ruby
    def self.find_or_create_by_omniauth(auth)
      find_or_create_by(provider: auth.provider, uid: auth.uid) do |u|
        u.email = auth.info.email
      end
    end
    ```

- [ ] Task 4: Add routes for sessions and OmniAuth callbacks (AC: #1, #3)
  - [ ] Add to `config/routes.rb`:
    ```ruby
    get  '/auth/:provider/callback', to: 'sessions#create', as: :auth_callback
    get  '/auth/failure',            to: 'sessions#failure', as: :auth_failure
    get  '/sign_in',                 to: 'sessions#new',     as: :new_session
    delete '/sign_out',              to: 'sessions#destroy',  as: :sign_out
    ```
  - [ ] Confirm OmniAuth middleware is mounted at `/auth/openid_connect` (done by gem initializer — verify no route collision)

- [ ] Task 5: Add authentication helpers to `ApplicationController` (AC: #1, #2)
  - [ ] Add `current_user` helper (memoized): looks up `User.find_by(id: session[:user_id])`
  - [ ] Add `require_authentication` before_action: calls `redirect_to new_session_path` if no `current_user`; stores `session[:return_to] = request.fullpath` for post-login redirect
  - [ ] Add `30-min inactivity timeout` enforcement:
    - On each authenticated request, check `session[:last_active_at]`
    - If `Time.current.to_i - session[:last_active_at] > 30.minutes.to_i` → call `reset_session`, flash a timeout message, `redirect_to new_session_path`
    - On each valid authenticated request: update `session[:last_active_at] = Time.current.to_i`
  - [ ] Add `helper_method :current_user` so views can access it
  - [ ] DO NOT add `verify_authorized` here — that is Story 1.4 (adding it now will break all requests before Pundit policies exist)
  - [ ] DO NOT add first-login gate here — that is Story 1.5

- [ ] Task 6: Create sign-in view and update application layout (AC: #1, #3)
  - [ ] Create `app/views/sessions/new.html.erb` — sign-in page with IdP button as a **POST form** (not a link — OmniAuth 2.x requires POST to initiate auth):
    ```erb
    <%= button_to t('.sign_in_with_idp'), '/auth/openid_connect', method: :post, data: { turbo: false } %>
    ```
    All copy via I18n keys. `data: { turbo: false }` prevents Turbo intercepting the redirect to IdP.
  - [ ] Create `app/views/sessions/failure.html.erb` — clear error message; use I18n key `t('.authentication_failed')`; no session created messaging
  - [ ] Update `app/views/layouts/application.html.erb` to show sign-out link (as a DELETE form) if `current_user` present, sign-in link if not
  - [ ] Add I18n keys to `config/locales/en.yml`:
    ```yaml
    en:
      sessions:
        new:
          title: "Sign In"
          sign_in_with_idp: "Sign in with Organization Account"
        failure:
          title: "Authentication Failed"
          authentication_failed: "Sign-in failed. Please try again."
          back_to_sign_in: "Back to Sign In"
      layouts:
        application:
          sign_out: "Sign Out"
          sign_in: "Sign In"
      flash:
        session_timeout: "Your session has expired. Please sign in again."
        signed_out: "You have been signed out."
    ```
  - [ ] Mirror all new keys to `config/locales/th.yml` (key-for-key; Thai values left blank for Rawinan)

- [ ] Task 6b: Create user fixtures (AC: #1)
  - [ ] Create `test/fixtures/users.yml` with at least two fixtures:
    ```yaml
    regular_user:
      provider: openid_connect
      uid: "test-uid-regular-001"
      email: regular@example.test
      admin: false
      profile_completed_at: null

    admin_user:
      provider: openid_connect
      uid: "test-uid-admin-001"
      email: admin@example.test
      admin: true
      profile_completed_at: 2026-01-01 00:00:00
    ```
  - [ ] No real PII or real-looking UIDs — use `example.test` domain; `gitleaks` scans fixtures too

- [ ] Task 7: Write tests (AC: #1, #2, #3)
  - [ ] `test/models/user_test.rb`: test `find_or_create_by_omniauth` with valid auth hash (new user created); same uid returns existing user; validates presence of provider/uid/email; `admin?` predicate; `profile_complete?` predicate
  - [ ] `test/controllers/sessions_controller_test.rb`: test OmniAuth callback creates session (mock auth hash); test failure action clears session; test destroy clears session; test redirect to `return_to`
  - [ ] `test/integration/authentication_flow_test.rb`: test unauthenticated access redirects to sign-in; test post-auth redirect to original URL; test 30-min timeout expires session
  - [ ] In `test/test_helper.rb`: add OmniAuth test mode + mock hash helper:
    ```ruby
    OmniAuth.config.test_mode = true
    # Helper to mock OIDC auth hash
    def mock_omniauth(uid: "user-123", email: "user@example.test")
      OmniAuth.config.mock_auth[:openid_connect] = OmniAuth::AuthHash.new(
        provider: "openid_connect",
        uid: uid,
        info: OmniAuth::AuthHash::InfoHash.new(email: email)
      )
    end
    ```
  - [ ] No live OIDC credentials in tests — mocked entirely

- [ ] Task 8: Run CI gates locally and verify (AC: all)
  - [ ] `bin/rubocop` — 0 offenses
  - [ ] `bin/brakeman --no-pager` — 0 high/critical warnings
  - [ ] `bundle exec bundler-audit check --update` — 0 high/critical CVEs
  - [ ] `bundle exec rails test` — all tests pass
  - [ ] `bundle exec i18n-tasks health` — 0 missing/unused keys
  - [ ] Manual: boot `bin/dev` and confirm sign-in page renders at `/sign_in`

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

### Completion Notes List

### File List
