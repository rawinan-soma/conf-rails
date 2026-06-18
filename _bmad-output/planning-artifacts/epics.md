---
stepsCompleted: [1, 2, 3, 4]
status: complete
completedAt: '2026-06-18'
inputDocuments:
  - _bmad-output/planning-artifacts/prds/prd-conference-envocc-2026-06-07/prd.md
  - _bmad-output/planning-artifacts/architecture.md
  - _bmad-output/planning-artifacts/ux-designs/ux-conference-envocc-2026-06-07/DESIGN.md
  - _bmad-output/planning-artifacts/ux-designs/ux-conference-envocc-2026-06-07/EXPERIENCE.md
project_name: conf-rails
product_name: "ENVOCC Conference Room Booking System"
---

# conf-rails (ENVOCC Conference Room Booking System) - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for conf-rails, decomposing
the requirements from the PRD, the UX Design, and the Architecture into implementable
stories. Stories are sequenced to honor the architecture's implementation order and are
written to be self-contained for the BAD autonomous pipeline. FR/NFR IDs are preserved
from the PRD for traceability.

## Requirements Inventory

### Functional Requirements

**F1 — Room Calendar & Availability**
- FR-001: Calendar view of all active rooms by date & time slot.
- FR-002: Visually distinguish booked / available / blocked slots.
- FR-003: Click an available slot to start a booking for that room/time.
- FR-004: Conflict detection at submission — no double-booking of overlapping slots (overlap = intersecting ranges; adjacent ≠ overlap; atomic guarantee at DB).

**F2 — Booking Creation**
- FR-010: Single unified booking form (room, event name, date, start/end, agenda optional, catering toggle, registration settings; contact pre-filled read-only).
- FR-011: Validate room availability before accepting submission.
- FR-012: On success, generate a unique registration link + show on confirmation.
- FR-013: Send booking confirmation email to organizer.
- FR-014: Duplicate a past booking to pre-fill a new form.
- FR-015: Edit or cancel a booking the organizer created.
- FR-016: On cancellation, email all registered attendees.

**F3 — Catering**
- FR-020: Catering toggle (lunch yes/no) on the booking form; organizer sets no meal types.
- FR-021: When catering on, each registrant picks their own meal type (FR-041a).
- FR-022: Aggregate registrant meal-type selections into per-type counts (organizer + admin).
- FR-023: Toggle catering on/off post-creation; meal data retained-but-dormant when off, restored when on; aggregation tolerates null meal type.

**F4 — Registration Management (Organizer)**
- FR-030: Registration toggle (enabled/disabled) at booking creation.
- FR-031: When enabled, prominently show the registration link on the dashboard with one-click copy.
- FR-032: No maximum registrant capacity; open until close date or manual close.
- FR-033: Auto-close when the closing date is reached.
- FR-034: Organizer sets a registration closing date; closes at end of that date (Asia/Bangkok).
- FR-034b: Organizer can manually close registration any time before the closing date.
- FR-034c: Close/cancel transactional vs. in-flight registrations — uncommitted-before-timestamp rejected with the closed message; committed-before-cancel get the cancellation email.
- FR-035: View registrant list with status Registered / Cancelled. (No "Attended" — out of scope for MVP.)
- FR-036: Generate downloadable sign-in sheet PDF per event.
- FR-037: Send a single fixed reminder email 1 day before the event to attendees + organizer.
- FR-038: Generate a per-event QR code linking to the registration page; downloadable.

**F5 — External Registration**
- FR-040: Branded registration page (logo, event name, date, time, room, agenda, contact resolved live from organizer profile).
- FR-041: Base form fields: title (Mr/Mrs/Ms/Other→free text), first name, last name, organization, email.
- FR-041a: When catering on, require meal type (Normal/Vegetarian/Muslim/Other→free text).
- FR-042: On submission, immediately send confirmation email via org SMTP.
- FR-043: Confirmation email includes a unique self-cancellation link.
- FR-044: External registrant cancels own registration via link, no login.
- FR-045: Registration pages publicly accessible without authentication.
- FR-046: When closed, page shows a clear "registration closed" message.
- FR-047: Resend lost confirmation by entering email; neutral acknowledgement (no disclosure).
- FR-048: Unique per (event, email); repeat = neutral no-op; internal+external same person reconciled to one record; cancel frees the pair.

**F6 — Organizer Dashboard**
- FR-050: Dashboard lists the logged-in organizer's upcoming bookings.
- FR-051: Each entry shows event name, room, date/time, registrant count, catering summary, registration link.
- FR-052: One-click copy of the registration link per booking.
- FR-053: One-click download of the sign-in sheet PDF per booking.

**F7 — Admin: Room Management**
- FR-060: Add, edit, deactivate rooms.
- FR-061: Room record: name, floor, capacity, photo (optional), features (multi-select).
- FR-062: Block time slots on a room for maintenance/reserved use.
- FR-063: Deactivating a room with future bookings auto-cancels them, notifies owning organizers + attendees, after a confirmation warning listing affected bookings.

**F8 — Admin: Analytics & Reporting**
- FR-070: Utilization heatmap (bookings per room per month).
- FR-071: Bulk calendar across all rooms.
- FR-072: Export booking & registrant data as CSV (UTF-8 BOM, injection-safe).
- FR-073: Audit log of bookings, cancellations, modifications (timestamp, actor, change).

**F9 — Email & Notifications**
- FR-080: All outbound email via the org's dedicated SMTP only.
- FR-081: Admin-configurable SMTP settings (host, port, sender name, sender email).
- FR-082: Transactional emails (booking created, booking cancelled, registration submitted, reminder, room-deactivation auto-cancel).
- FR-083: Sender display name shows the organization name.
- FR-084: Registration commit decoupled from email send; SMTP retry/queue/dead-letter + scheduling/idempotency (architecture-owned).

**F10 — Authentication & Access Control**
- FR-090: Internal users authenticate via the org identity provider (OIDC).
- FR-091: Organizer + attendee are default capacities; admin is the only assignable role (granted via settings).
- FR-092: External access is token-based via unique per-event links; no account.
- FR-093: Internal sessions time out after fixed 30-min inactivity (not configurable).
- FR-094: RBAC — manage own bookings only; any internal user may view another's event (details only) to register; admins read-all, no booking approval/edit (except FR-063 cascade).
- FR-095: User profile (title, first/last name, phone, email, organization); contact auto-used live on registration page; profile completed via first-login self-service screen; email read-only from IdP.

**F11 — Internal Registration (Attend an Event)**
- FR-100: Authenticated internal users register to attend an open event in-app (not the public link).
- FR-101: Internal registrant identity auto-filled read-only from profile; meal type only input (when catering on); confirm-only otherwise.
- FR-102: Internal registrant becomes a normal registrant (count, list, aggregation, sign-in sheet, notifications); confirmed in-app, no "submitted" email; still gets cancellation/reminder emails.
- FR-103: Internal registrant self-cancels in-app, no token link.
- FR-104: Close rules (FR-033/034/034b/046) apply to internal registration.
- FR-105: Owning organizer may self-register for their own event; counted once (FR-048); self-notification acceptable; admin viewing-to-register sees event details only.

### NonFunctional Requirements

- NFR-001 Security: no known critical/high vulns at launch; tokens & credentials stored securely (mechanisms in architecture — digested tokens, AR encryption, TLS, Brakeman+bundler-audit+gitleaks CI gate).
- NFR-002 Reliability: conflict detection prevents double-bookings, verified by a concurrency test; production "0 incidents" is a monitoring KPI.
- NFR-003 Performance: calendar/dashboard load within 3s; exact load envelope deferred to a k6 perf plan.
- NFR-004 Responsiveness: public registration/confirmation full responsive (mobile+desktop equal); organizer flow mobile-usable; no horizontal scroll/zoom.
- NFR-005 Data Retention: booking & registrant records retained indefinitely until admin deletion.
- NFR-006 Localization: production UI, emails, generated docs in Thai (single language).
- NFR-007 Accessibility: public + internal surfaces conform to WCAG 2.1 AA.

### Additional Requirements

*(From the Architecture — drive Epic 1 / cross-cutting setup.)*

- **Project init (first story):** `rails new conf-rails --database=postgresql --css=tailwind`; Rails 8.x, **Ruby 4.0.x** (YJIT in prod; ZJIT experimental). daisyUI v5 via bundled `daisyui.mjs`/`daisyui-theme.mjs` (no Node); "Forest & Copper" custom daisyUI theme.
- **Schema + correctness constraints:** enable `btree_gist`; `bookings_no_overlap` EXCLUDE (gist) constraint with half-open `[)` ranges; `registrations` unique partial index `(event_id, lower(email)) WHERE status <> 'cancelled'`.
- **Timezone:** `config.time_zone = "Bangkok"`; timestamps `timestamptz`; display via `l(...)`.
- **Auth:** OmniAuth + `omniauth_openid_connect`; first-login profile gate; Pundit (one policy per resource).
- **Background jobs:** Solid Queue (jobs + `config/recurring.yml` for auto-close + reminder); idempotent jobs; mailers async (`deliver_later`); dead-letter via failed jobs.
- **Secrets:** Rails encrypted credentials (master.key gitignored); AR Encryption for SMTP password; Kamal/ENV at deploy. **No credential — real or test — ever committed.**
- **View layer:** ViewComponent for the daisyUI component set; Turbo Frames/Streams + Stimulus.
- **Docs/artifacts:** Prawn + embedded Noto Thai TTF (sign-in PDF); `rqrcode` (QR); CSV UTF-8 BOM + injection-safe.
- **i18n:** Rails I18n, lazy view-scoped keys; `en.yml` authored; `th.yml` scaffolded key-for-key for Rawinan to translate; `i18n-tasks` in CI.
- **CI/CD:** GitHub Actions — RuboCop (omakase), Brakeman, bundler-audit, **gitleaks**, Minitest (incl. concurrency + system tests); build fails on high/critical vuln/CVE or any detected secret.
- **Deploy:** Kamal 2 + Thruster, Dockerized, VPS/on-prem.

### UX Design Requirements

*(From DESIGN.md + EXPERIENCE.md — first-class inputs.)*

- UX-DR1: Implement the **"Forest & Copper" design tokens** as a custom daisyUI theme (greens, copper accent, cream surfaces, ink text, semantic status colors, 3-tier green-tinted elevation, 8px spacing scale, radius scale).
- UX-DR2: **Thai typography** — Noto Serif Thai (headings) + Noto Sans Thai (body) via Google Fonts; body line-height ≥1.65 (never <1.5), never below 14px; load fonts (and embed Noto Thai TTF for Prawn).
- UX-DR3: Build the **ViewComponent UI library** mapping the UX component set: button (primary/secondary/ghost, loading state), form-field (label-always-visible, focus ring, error), select, toggle-switch, read-only field, status-badge (label not color-only), calendar-slot (available/booked/blocked by label+pattern), booking-card, modal (destructive confirm), admin-sidebar, heatmap-cell (6-step ramp), toast, skeleton, empty-state.
- UX-DR4: **10-surface IA** in two zones — internal app (Room Calendar, Event Detail, Booking Form, Organizer Dashboard, Admin Room Mgmt, Admin Analytics, Admin Settings, Login) + public (External Registration, Registration Confirmed/Self-Cancel).
- UX-DR5: **Room Calendar = week scheduler** — rooms on Y (rows) × days on X (columns); booking chips show time; empty day cell is clickable (no preset time); booking chip → Event Detail; no day view.
- UX-DR6: Implement the **4 key flows** — (1) organizer book+register, (2) external attendee register (≤2 min), (3) admin room caretaking + deactivation confirm modal + heatmap, (4) internal staff register-to-attend (prefilled, meal-only).
- UX-DR7: **State patterns** — empty (calm line + single action), loading (skeletons; submit disabled+spinner), form error (inline field-level, focus first error), system error (page banner + retry), success (toast / full success screen), destructive confirm (modal listing consequences).
- UX-DR8: **Accessibility (WCAG 2.1 AA)** — contrast ≥4.5:1 (audit copper-on-cream & green-500-on-white), visible focus rings, labels always visible, no color-alone meaning, tap targets ≥44px.
- UX-DR9: **Responsiveness** — external pages full responsive (mobile+desktop equal, single-column mobile); organizer flow mobile-usable; admin analytics desktop-first but tablet-safe.
- UX-DR10: **Voice & tone** — two registers (public warmer/trust-building; internal crisper); errors actionable not accusatory; all copy English placeholder via I18n keys for Thai translation.

### FR Coverage Map

- **Epic 1 — Foundation, Identity & Platform:** FR-080, FR-083, FR-084, FR-090, FR-091, FR-093, FR-094, FR-095
- **Epic 2 — Rooms & Booking:** FR-001, FR-002, FR-003, FR-004, FR-010, FR-011, FR-012, FR-013, FR-014, FR-015, FR-016, FR-020, FR-023, FR-060, FR-061, FR-062, FR-063
- **Epic 3 — Registration & Attendee Management:** FR-021, FR-022, FR-030, FR-031, FR-032, FR-033, FR-034, FR-034b, FR-034c, FR-035, FR-036, FR-037, FR-038, FR-040, FR-041, FR-041a, FR-042, FR-043, FR-044, FR-045, FR-046, FR-047, FR-048, FR-050, FR-051, FR-052, FR-053, FR-092, FR-100, FR-101, FR-102, FR-103, FR-104, FR-105
- **Epic 4 — Admin Analytics & System Settings:** FR-070, FR-071, FR-072, FR-073, FR-081
- **Cross-cutting:** FR-082 (transactional-email catalog — realized incrementally across Epics 2–4 as each email is produced); FR-073 audit log (auditable actions captured in the epic that produces them)

## Epic List

### Epic 1: Foundation, Identity & Platform
Internal users can sign in via the organization's identity provider, complete their profile on first login, and navigate a branded, accessible, Thai-ready application shell. Establishes the implementation platform every later epic builds on: project init (`rails new` + PostgreSQL + daisyUI/Forest & Copper theme + Thai fonts), DB foundation (`btree_gist` enabled), the core ViewComponent library + state patterns + accessibility baseline, OIDC authentication, the organizer/attendee capacities + admin role with Pundit, fixed session timeout, the email + background-job infrastructure (Solid Queue + ActionMailer with commit/send decoupling), the i18n en/th key scaffold, and CI (RuboCop/Brakeman/bundler-audit/gitleaks/Minitest) + Kamal deploy.
**FRs covered:** FR-080, FR-083, FR-084, FR-090, FR-091, FR-093, FR-094, FR-095

### Epic 2: Rooms & Booking
Admins set up and maintain the room inventory; organizers view the week-scheduler calendar and create, edit, duplicate, and cancel bookings with a guaranteed no-double-booking (database EXCLUDE constraint). The catering toggle is set on the booking form; booking-confirmation and cancellation emails fire.
**FRs covered:** FR-001, FR-002, FR-003, FR-004, FR-010, FR-011, FR-012, FR-013, FR-014, FR-015, FR-016, FR-020, FR-023, FR-060, FR-061, FR-062, FR-063

### Epic 3: Registration & Attendee Management
External guests self-register on a branded, token-accessed public page; internal staff register in-app (identity prefilled, meal-only); organizers manage their registrants (list, sign-in-sheet PDF, QR code, 1-day reminder, dashboard) with meal-type aggregation and registration close rules; everyone can self-cancel and recover a lost confirmation. Registration is unique per (event, email) and reconciles internal vs. external identity.
**FRs covered:** FR-021, FR-022, FR-030, FR-031, FR-032, FR-033, FR-034, FR-034b, FR-034c, FR-035, FR-036, FR-037, FR-038, FR-040, FR-041, FR-041a, FR-042, FR-043, FR-044, FR-045, FR-046, FR-047, FR-048, FR-050, FR-051, FR-052, FR-053, FR-092, FR-100, FR-101, FR-102, FR-103, FR-104, FR-105

### Epic 4: Admin Analytics & System Settings
Admins read room utilization (heatmap + bulk calendar), export booking & registrant data as CSV, review the audit log, configure the SMTP settings, and grant/revoke the admin role.
**FRs covered:** FR-070, FR-071, FR-072, FR-073, FR-081

---

## Epic 1: Foundation, Identity & Platform

Internal users can sign in via the org IdP, complete their profile, and use a branded,
accessible, Thai-ready app shell — on a platform (Rails 8 / Ruby 4.0 / PostgreSQL /
Hotwire / daisyUI / Solid Queue) that every later epic builds on.

### Story 1.1: Project initialization & platform scaffold

**GH Issue:** #1

As a developer,
I want the Rails 8 project initialized with the agreed stack, styling, and CI,
So that all later stories build on a consistent, secure, no-Node foundation.

**Context/Notes:** Architecture "First Implementation Priority". `rails new conf-rails
--database=postgresql --css=tailwind`; Ruby 4.0.x (YJIT); add daisyUI via committed
`daisyui.mjs`/`daisyui-theme.mjs` (no Node); gems: view_component, pundit,
omniauth_openid_connect, prawn, rqrcode, i18n-tasks, brakeman, bundler-audit.

**Acceptance Criteria:**

**Given** a clean machine with Ruby 4.0.x
**When** the project is generated and `bin/dev` is run
**Then** a Rails 8 app boots with PostgreSQL and Tailwind+daisyUI compiling via the standalone CLI (no Node/npm)
**And** `.gitignore` excludes `master.key`, `config/credentials/*.key`, `.env*`, `*.pem`

**Given** the CI workflow
**When** a push or PR runs
**Then** RuboCop (omakase), Brakeman, bundler-audit, gitleaks, and Minitest all run
**And** the build fails on any high/critical Brakeman/CVE finding or any detected secret

**Given** the deploy config
**When** `kamal` config is inspected
**Then** a Dockerized Kamal 2 + Thruster setup exists with secrets sourced from ENV/credentials (no secrets in source)

### Story 1.2: Core design system & ViewComponent UI library

**GH Issue:** #2

As an internal user,
I want a branded, accessible, Thai-ready interface shell and reusable components,
So that every screen is visually consistent and usable in Thai.

**Context/Notes:** UX-DR1/2/3/7/8/10, NFR-006/007. Implement the "Forest & Copper"
custom daisyUI theme + Noto Serif/Sans Thai fonts; build base ViewComponents (button,
form-field, select, toggle-switch, read-only field, status-badge, modal, toast,
skeleton, empty-state, app shell + admin-sidebar). Feature-specific components
(calendar-slot, booking-card, heatmap-cell) come in their epics. Set up Rails I18n with
`en.yml` authored and `th.yml` key-mirror, `Time.zone="Bangkok"`, and `i18n-tasks`.

**Acceptance Criteria:**

**Given** the theme and fonts
**When** any page renders
**Then** it uses the Forest & Copper tokens and Noto Thai fonts with body line-height ≥1.65 and no text below 14px

**Given** the component library
**When** a developer uses a base component
**Then** button/form-field/select/toggle/badge/modal/toast/skeleton/empty-state render per DESIGN.md, with visible focus rings, always-visible labels, and no color-alone meaning (WCAG 2.1 AA)

**Given** all user-facing copy
**When** a string is rendered
**Then** it comes from an I18n key (lazy view-scoped), `th.yml` mirrors `en.yml` key-for-key, and `i18n-tasks health` passes in CI

### Story 1.3: OIDC authentication & sessions

**GH Issue:** #3

As an internal user,
I want to sign in through my organization's identity provider,
So that I access the app with my existing org account and no separate password.

**Context/Notes:** FR-090, FR-093. OmniAuth + omniauth_openid_connect; find_or_create
User by IdP subject; email from OIDC claim (read-only). 30-min fixed inactivity timeout.

**Acceptance Criteria:**

**Given** an unauthenticated visitor to an internal page
**When** they choose sign in
**Then** they are redirected to the org IdP and, on success, a `User` is found or created by IdP subject and a session starts

**Given** an authenticated session idle for 30 minutes
**When** the next request is made
**Then** the session has expired and re-authentication is required (timeout is a fixed default, not configurable)

**Given** an OIDC callback failure
**When** authentication does not complete
**Then** the user sees a clear error and no session is created

### Story 1.4: Capacities, admin role & Pundit authorization baseline

**GH Issue:** #4

As the system,
I want every internal user to be organizer+attendee by default with admin as the only elevated role, enforced by policies,
So that access control is consistent and centrally enforced.

**Context/Notes:** FR-091, FR-094. User has organizer/attendee capacities (no assignment)
and an `admin` flag. Pundit `ApplicationPolicy` + `verify_authorized`; base rules:
manage-own-only, admin read-all, no booking approval authority. Role-grant UI is Epic 4.

**Acceptance Criteria:**

**Given** any authenticated user
**When** they act
**Then** they have organizer and attendee capacities by default with no assignment required

**Given** a controller action
**When** it executes
**Then** it is authorized through a Pundit policy (`verify_authorized`), and an unauthorized attempt returns 403 with a flash message

**Given** an admin user
**When** they read bookings/registrant data
**Then** policy grants system-wide read access, but no create/approve/edit of others' bookings

### Story 1.5: First-login profile completion

**GH Issue:** #5

As an internal user,
I want to complete my profile on first login,
So that my identity prefills registrations and the registration-page contact.

**Context/Notes:** FR-095 (+ open OQ-3 IdP claim mapping). Fields: title/prefix, first
name, last name, phone, organization (app-owned, editable later); email read-only from
OIDC. First-login gate blocks the app until required fields are complete.

**Acceptance Criteria:**

**Given** a user logging in for the first time with an incomplete profile
**When** they reach the app
**Then** they are routed to a self-service profile screen and cannot proceed until required fields are filled

**Given** the profile form
**When** it renders
**Then** email is shown read-only (from the IdP); title/first/last/phone/organization are editable

**Given** a completed profile
**When** the user later edits it
**Then** changes save and propagate live wherever the profile is used

### Story 1.6: Email & background-job infrastructure

**GH Issue:** #6

As the system,
I want outbound email sent asynchronously over the org SMTP, decoupled from request transactions,
So that features can notify users reliably without blocking on mail delivery.

**Context/Notes:** FR-080, FR-083, FR-084. Solid Queue (jobs + `config/recurring.yml`);
`ApplicationMailer` sender display = org name; all mail via `deliver_later`; retry+backoff;
failed jobs as dead-letter. SMTP creds via credentials now (admin UI in Epic 4). Email
sending must never roll back the triggering transaction.

**Acceptance Criteria:**

**Given** Solid Queue configured
**When** the app runs
**Then** background jobs and a recurring-task scheduler are operational with a dead-letter (failed-jobs) path

**Given** a mailer send
**When** it is triggered from a request
**Then** it is enqueued (`deliver_later`) and the triggering transaction commits even if the send later fails

**Given** any outbound email
**When** it is delivered
**Then** the sender display name is the organization name and delivery uses the org SMTP only (no third-party service)

---

## Epic 2: Rooms & Booking

Admins maintain the room inventory; organizers view the week-scheduler calendar and
create/edit/duplicate/cancel bookings with a database-guaranteed no-double-booking.

### Story 2.1: Room inventory management (admin)

**GH Issue:** #7

As an admin,
I want to add, edit, and deactivate rooms,
So that organizers can only book rooms that currently exist and are active.

**Context/Notes:** FR-060, FR-061. `Room` (name, floor, capacity [informational], photo
optional, features multi-select). Deactivated rooms are excluded from booking/calendar
(cascade behavior for rooms with future bookings is Story 2.6).

**Acceptance Criteria:**

**Given** an admin
**When** they create or edit a room
**Then** they set name, floor, capacity, optional photo, and features (multi-select), and validation enforces required fields

**Given** a deactivated room
**When** the calendar or booking form is viewed
**Then** that room does not appear and cannot be booked

**Given** a non-admin user
**When** they attempt room management
**Then** Pundit denies access (403)

### Story 2.2: Room time-slot blocking (admin)

**GH Issue:** #8

As an admin,
I want to block time slots on a room for maintenance or reserved use,
So that those slots cannot be booked.

**Context/Notes:** FR-062. `RoomBlock`. Define block-vs-existing-booking behavior
(blocks cannot overlap an existing active booking; surface a clear error).

**Acceptance Criteria:**

**Given** an admin viewing a room
**When** they block a time range
**Then** the block is saved and the range shows as blocked on the calendar (label + pattern, not color alone)

**Given** a block that overlaps an existing active booking
**When** the admin submits it
**Then** the system rejects it with a clear message listing the conflict

### Story 2.3: Room calendar — week scheduler

**GH Issue:** #9

As an organizer,
I want a week view of all rooms with their availability,
So that I can find and pick an open slot quickly.

**Context/Notes:** FR-001, FR-002, FR-003, UX-DR5. Week scheduler: rooms = rows, days =
columns; `calendar-slot` component; booking chips show time and open Event Detail; an
empty day cell is clickable (no preset time) and starts a booking. No day view.

**Acceptance Criteria:**

**Given** the calendar
**When** it loads
**Then** it shows all active rooms as rows across the days of the week, distinguishing booked / available / blocked by label+pattern (not color alone)

**Given** an available day cell
**When** the organizer clicks it
**Then** the booking form opens pre-scoped to that room (time entered in the form)

**Given** an existing booking chip
**When** the organizer clicks it
**Then** the Event Detail view opens (read-only event info)

### Story 2.4: Create a booking with atomic conflict detection

**GH Issue:** #10

As an organizer,
I want to create a booking in one unified form that can never double-book a room,
So that setup is fast and the schedule is always correct.

**Context/Notes:** FR-010, FR-011, FR-004, FR-012, FR-013, FR-020. Enable `btree_gist`;
add `bookings_no_overlap` EXCLUDE (gist, half-open `[)`) WHERE status<>'cancelled';
rescue `PG::ExclusionViolation` for loser-of-race UX. Generate per-event registration
link (token). Booking confirmation email via the Epic 1 mailer (FR-082 entry).

**Acceptance Criteria:**

**Given** the booking form
**When** the organizer submits room, event name, date, start/end, optional agenda, catering toggle, and registration settings
**Then** availability is validated, the booking is created, a unique registration link is generated and shown on a confirmation screen, and the event contact appears pre-filled read-only

**Given** two organizers submitting overlapping bookings for the same room concurrently
**When** both submit
**Then** exactly one succeeds and the other sees an inline "that slot was just taken" message with its input preserved (DB EXCLUDE constraint enforces this; verified by a concurrency test)

**Given** a booking with start ≥ end or a zero/negative duration
**When** submitted
**Then** it is rejected with a validation error

**Given** a successful booking
**When** it is created
**Then** a confirmation email is enqueued to the organizer

### Story 2.5: Edit, duplicate & cancel a booking

**GH Issue:** #11

As an organizer,
I want to edit, duplicate, or cancel my own bookings (including the catering toggle),
So that I can manage events and reuse past setups.

**Context/Notes:** FR-014, FR-015, FR-016, FR-023. Edit/cancel own-only (Pundit).
Duplicate pre-fills a new form (reset closing date / fresh link). Catering toggle on/off
post-creation with retained-but-dormant meal data (aggregation tolerates null). Cancel
emails registered attendees.

**Acceptance Criteria:**

**Given** a booking the organizer created
**When** they edit or cancel it
**Then** the change is applied (edits re-run conflict detection on the new slot); a non-owner is denied by policy

**Given** a cancelled booking with registered attendees
**When** cancellation completes
**Then** a cancellation email is enqueued to all registered attendees

**Given** catering is toggled off after registrants picked meal types
**When** the toggle changes
**Then** meal selections are retained but hidden from aggregation; toggling back on restores them; registrants who registered while off carry an unspecified/none meal type

**Given** a past booking
**When** the organizer duplicates it
**Then** a new booking form is pre-filled with its details (closing date reset, a fresh registration link generated on save)

### Story 2.6: Room deactivation cascade

**GH Issue:** #12

As an admin,
I want deactivating a room with future bookings to safely cancel and notify,
So that no one is left expecting an event in a removed room.

**Context/Notes:** FR-063. Confirmation modal lists affected bookings before proceeding;
on confirm, future bookings auto-cancel and the owning organizer + registered attendees
are notified. This is scoped operational action, not booking-approval authority.

**Acceptance Criteria:**

**Given** an admin deactivating a room with future bookings
**When** they initiate deactivation
**Then** a confirmation modal lists the affected bookings and warns they will be auto-cancelled and notified

**Given** the admin confirms
**When** deactivation proceeds
**Then** future bookings are cancelled and a cancellation email is enqueued to each owning organizer and its registered attendees

**Given** a room with no future bookings
**When** it is deactivated
**Then** it deactivates without the warning modal

---

## Epic 3: Registration & Attendee Management

External guests self-register on a branded token page; internal staff register in-app;
organizers manage registrants; everyone can self-cancel. The product's core value.

### Story 3.1: Registration settings & close lifecycle

**GH Issue:** #13

As an organizer,
I want to control whether and until when registration is open,
So that I collect attendees within the right window.

**Context/Notes:** FR-030, FR-032, FR-033, FR-034, FR-034b, FR-034c, FR-046, FR-092.
`Registration` model + per-event registration-link token (digested, ≥128-bit). Auto-close
via Solid Queue recurring task at end-of-date Asia/Bangkok; manual close; transactional
in-flight rejection; uncapped.

**Acceptance Criteria:**

**Given** booking creation
**When** the organizer sets the registration toggle and an optional closing date
**Then** the setting is saved; registration is uncapped (no max)

**Given** a closing date
**When** the end of that date passes (Asia/Bangkok)
**Then** a recurring job closes registration; the organizer can also close it manually any time before

**Given** registration is closed
**When** a visitor opens the registration page or an in-flight submission lands after the close timestamp
**Then** the page shows a clear "registration closed" message and no new registration is accepted

### Story 3.2: External registration (public token page)

**GH Issue:** #14

As an external guest,
I want to register for an event from a branded page without an account,
So that I can attend with minimal effort.

**Context/Notes:** FR-040, FR-041, FR-041a, FR-042, FR-043, FR-045, FR-048, FR-092,
UX-DR6 Flow 2. Public token-scoped route (`/r/:token`), no auth. Contact resolved live
from organizer profile. Dedup unique (event, lower(email)). Free-text "Other" fields
length-capped + sanitized. Target ≤2 min.

**Acceptance Criteria:**

**Given** a valid registration link
**When** the page loads (mobile or desktop)
**Then** it shows org logo, event name, date, time, room, agenda (if any), and the contact (name+phone, live from profile), fully responsive

**Given** the form
**When** the guest enters title (Mr/Mrs/Ms/Other→free text), first name, last name, organization, email, and (only when catering is on) meal type
**Then** validation passes and on submit a registration is created and a confirmation email with a self-cancellation link is enqueued

**Given** an email already registered (not cancelled) for that event
**When** the same email submits again
**Then** no duplicate is created and the same neutral acknowledgement is shown

### Story 3.3: External self-cancel & confirmation resend

**GH Issue:** #15

As an external registrant,
I want to cancel my registration or recover a lost confirmation by link/email,
So that I can manage my attendance without an account.

**Context/Notes:** FR-044, FR-047. Self-cancel token single-use, invalidated after use.
Resend: neutral acknowledgement regardless of match (no enumeration); constant-ish timing.

**Acceptance Criteria:**

**Given** a confirmation email's self-cancel link
**When** the registrant clicks it
**Then** their registration is cancelled with no login, freeing the (event, email) pair, and the token cannot be reused

**Given** the registration page
**When** a visitor enters an email to resend the confirmation
**Then** the same neutral acknowledgement is shown whether or not a registration exists, and if it exists the confirmation (with cancel link) is resent

### Story 3.4: Internal in-app registration

**GH Issue:** #16

As an internal user,
I want to register to attend a colleague's event from inside the app with no form,
So that I'm added in one tap using my profile data.

**Context/Notes:** FR-100, FR-101, FR-102, FR-103, FR-104, FR-105, UX-DR6 Flow 4. From
Event Detail; identity prefilled read-only; meal-type only when catering on, else
confirm-only; in-app confirmation (no "submitted" email); self-cancel in-app; owning
organizer may self-register (counted once per FR-048); admin viewing-to-register sees
event details only.

**Acceptance Criteria:**

**Given** an internal user on an open event's Event Detail
**When** they tap "Register to attend"
**Then** their identity is prefilled read-only; meal type is the only input when catering is on (otherwise a single confirm), and they become a counted registrant confirmed by an in-app toast (no submitted email)

**Given** an internal registrant
**When** they self-cancel from Event Detail
**Then** their attendance is cancelled in-app without a token link

**Given** the owning organizer (or an admin) registers to attend their/another event
**When** they register via the in-app action
**Then** they are counted once (dedup), and an admin viewing another's event to register sees only event details, not the registrant list

### Story 3.5: Meal-type aggregation

**GH Issue:** #17

As an organizer (and admin),
I want per-meal-type counts aggregated from registrant choices,
So that I can order catering accurately.

**Context/Notes:** FR-021, FR-022. Meal type owned by registrant. Aggregation tolerates
registrants with no meal type (registered while catering off — see FR-023).

**Acceptance Criteria:**

**Given** an event with catering on and registrants who chose meal types
**When** the organizer or admin views the event
**Then** counts per meal type (Normal/Vegetarian/Muslim/Other) are shown, aggregated from registrant selections

**Given** registrants with no meal type (registered while catering was off)
**When** the aggregation renders
**Then** they are counted under unspecified/none without error

### Story 3.6: Registrant list & status

**GH Issue:** #18

As an organizer,
I want to see the list of registrants for my event with their status,
So that I know who is coming.

**Context/Notes:** FR-035. Status: Registered / Cancelled (no "Attended" in MVP). Own-only
via Pundit.

**Acceptance Criteria:**

**Given** an event the organizer owns
**When** they open the registrant list
**Then** each registrant shows identity fields and status (Registered or Cancelled)

**Given** a non-owner (non-admin)
**When** they try to view another event's registrant list
**Then** access is denied (event details remain viewable for registering, but not registrant data)

### Story 3.7: Sign-in sheet PDF & event QR code

**GH Issue:** #19

As an organizer,
I want a printable sign-in sheet and an event QR code,
So that I can run on-site sign-in and share the registration page.

**Context/Notes:** FR-036, FR-038. Prawn + embedded Noto Thai TTF (correct Thai rendering);
rqrcode for the QR linking to the registration page. Sign-in sheet lists registered (not
cancelled) attendees; point-in-time snapshot.

**Acceptance Criteria:**

**Given** an event with registrants
**When** the organizer downloads the sign-in sheet
**Then** a PDF lists registered attendees with Thai text rendering correctly

**Given** an event
**When** the organizer downloads the QR code
**Then** it encodes the event's registration page URL and is suitable for on-site display

### Story 3.8: One-day-before reminder

**GH Issue:** #20

As a registered attendee and organizer,
I want a reminder the day before the event,
So that no one forgets.

**Context/Notes:** FR-037, FR-082. Solid Queue recurring task fires at a fixed
Asia/Bangkok clock time the calendar day before; idempotent (no duplicate per
registrant/event); recipients = registered attendees + organizer.

**Acceptance Criteria:**

**Given** an event happening tomorrow
**When** the reminder job runs
**Then** a single reminder email is enqueued to each registered attendee and the organizer

**Given** the reminder job runs twice or catches up after a missed run
**When** it processes an event already reminded
**Then** no duplicate reminder is sent

### Story 3.9: Organizer dashboard

**GH Issue:** #21

As an organizer,
I want a dashboard of my upcoming bookings with key info and actions,
So that I manage everything from one place.

**Context/Notes:** FR-050, FR-051, FR-052, FR-053. Lists own upcoming bookings with
registrant count, catering summary, registration link (one-click copy), sign-in PDF
(one-click download). `booking-card` component.

**Acceptance Criteria:**

**Given** an organizer with bookings
**When** they open the dashboard
**Then** their upcoming bookings list with event name, room, date/time, registrant count, catering summary, and the registration link

**Given** a booking entry
**When** the organizer uses its actions
**Then** one-click copy of the registration link and one-click download of the sign-in PDF work

---

## Epic 4: Admin Analytics & System Settings

Admins read utilization, export data, review the audit trail, configure SMTP, and manage
the admin role.

### Story 4.1: Utilization heatmap

**GH Issue:** #22

As an admin,
I want a utilization heatmap of bookings per room per month,
So that I can see usage at a glance.

**Context/Notes:** FR-070, UX-DR. `heatmap-cell` 6-step intensity ramp; raw counts; no
hover tooltip in MVP; ≤30s comprehension target.

**Acceptance Criteria:**

**Given** booking data
**When** the admin opens analytics
**Then** a heatmap shows booking counts per room per month with a 6-step intensity ramp readable at a glance

**Given** a non-admin
**When** they attempt to view analytics
**Then** access is denied (403)

### Story 4.2: Bulk calendar (all rooms)

**GH Issue:** #23

As an admin,
I want a calendar of all bookings across all rooms,
So that I can see the whole schedule.

**Context/Notes:** FR-071. Desktop-first, tablet-safe.

**Acceptance Criteria:**

**Given** bookings across rooms
**When** the admin opens the bulk calendar
**Then** all bookings across all rooms are displayed in one view

### Story 4.3: CSV export of booking & registrant data

**GH Issue:** #24

As an admin,
I want to export booking and registrant data as CSV,
So that I can analyze or archive it.

**Context/Notes:** FR-072. UTF-8 with BOM (Excel + Thai); CSV-formula-injection
neutralized; define columns and whether cancelled/duplicate registrants are included.

**Acceptance Criteria:**

**Given** booking and registrant data
**When** the admin exports CSV
**Then** the file is UTF-8 with BOM, opens correctly with Thai text in Excel, and neutralizes formula-injection in any free-text field

**Given** the export
**When** generated
**Then** its columns and inclusion rules (e.g. cancelled registrants) are documented and consistent

### Story 4.4: Audit log

**GH Issue:** #25

As an admin,
I want an audit log of bookings, cancellations, and modifications,
So that I can review who changed what and when.

**Context/Notes:** FR-073. Single write path `AuditLog.record(actor:, action:, subject:,
changes:)`; dotted action verbs; admin-only viewer. (Auditable actions are recorded by
the epics that produce them; this story delivers the model + viewer.)

**Acceptance Criteria:**

**Given** an auditable action (booking created/cancelled/modified, room deactivated, role change, SMTP change)
**When** it occurs
**Then** an audit entry records timestamp, actor, and change

**Given** an admin
**When** they open the audit log
**Then** entries are listed and filterable; non-admins are denied

### Story 4.5: SMTP settings configuration

**GH Issue:** #26

As an admin,
I want to configure the SMTP settings in-app,
So that outbound email uses the org's mail server without a redeploy.

**Context/Notes:** FR-081, FR-080. `SmtpSetting` (host, port, sender name, sender email);
password via Active Record Encryption (never plaintext, never committed). Mailer reads
these settings.

**Acceptance Criteria:**

**Given** an admin on system settings
**When** they set SMTP host, port, sender name, and sender email
**Then** the settings are saved (password stored encrypted) and used for outbound email

**Given** a non-admin
**When** they attempt to access SMTP settings
**Then** access is denied (403)

### Story 4.6: Admin role assignment

**GH Issue:** #27

As an admin,
I want to grant or revoke the admin role for internal users,
So that I control who has elevated access.

**Context/Notes:** FR-091 (admin slice). Grant/revoke the only assignable role via
settings; organizer/attendee remain default capacities.

**Acceptance Criteria:**

**Given** an admin on the settings panel
**When** they grant or revoke admin for an internal user
**Then** that user's elevated access changes accordingly, and the action is audited

**Given** a non-admin
**When** they attempt role assignment
**Then** access is denied (403)
