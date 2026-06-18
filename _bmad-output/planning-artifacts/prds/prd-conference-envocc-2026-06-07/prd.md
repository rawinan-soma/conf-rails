---
title: "ENVOCC Conference Room Booking System — PRD"
status: final
created: 2026-06-07
updated: 2026-06-18
finalized: 2026-06-07
project_name: conf-rails
product_name: "ENVOCC Conference Room Booking System"
user_name: Rawinan
---

# Product Requirements Document
## ENVOCC Conference Room Booking System

---

## 1. Problem Statement

ENVOCC currently manages conference room bookings through two separate applications — one for room booking, one for attendee registration via Google Form. External attendees have no dedicated channel and are entirely dependent on organizers manually sharing links. The existing system runs on unsupported frameworks with active security vulnerabilities and cannot be safely patched.

This product is a unified, secure replacement that:
- Combines room booking and attendee registration into a single organizer workflow
- Provides external attendees a professional, branded self-service registration channel
- Gives admins real-time visibility into room utilization and registrant data
- Eliminates the fragmentation and security risk of the current two-app system

---

## 2. Goals & Success Metrics

### Goals
1. Organizers complete the full booking + registration setup in a single workflow without switching applications
2. External registrants can self-register without an account or organizer intervention
3. Admins can manage rooms and view utilization data without any booking approval responsibility
4. The system prevents double-bookings — guaranteed at the persistence layer and verified by a concurrency test (see NFR-002), not merely by a best-effort check
5. The system is built on a secure, maintainable foundation with no known critical vulnerabilities at launch

### Success Metrics

| Metric | Target |
|--------|--------|
| Organizer task completion (full booking flow) | ≥ 80% without assistance |
| External registration completion rate | ≥ 90% |
| External registration time-to-complete | ≤ 2 minutes |
| Organizer satisfaction vs. current two-app process | Rated easier |
| Admin heatmap comprehension time | ≤ 30 seconds |
| Double-booking incidents | 0 (conflict detection blocks 100%) |

---

## 3. Users & Roles

### Internal Users (authenticated — org staff)
Every authenticated internal user (via the organization's identity provider) is, by default, **both an organizer and an attendee** — these are two capacities of one account, not separate roles:
- **Organizer capacity** (default for all): create and manage their own bookings, set up registration for each event, communicate with their attendees, and track their own registrant data. Cannot manage room inventory or system settings.
- **Attendee capacity** (default for all): register, from within the app, to attend events created by other organizers (see F11).

**Admin** is the only assignable role — an elevated permission granted to selected internal users by an existing admin. Admins manage room inventory and system configuration and have read access to all bookings and registrant data across the organization for operational visibility. **Admins have no approval authority over bookings** — they do not approve, reject, or gatekeep bookings. Admins are also internal users and retain the default organizer and attendee capacities.

### External Registrant (unauthenticated)
Accesses the system via a unique per-event link shared by the organizer. No account or login required. Can register for an event and cancel their own registration via a link in their confirmation email.

---

## 4. Functional Requirements

### F1 — Room Calendar & Availability

**FR-001** The system shall display all active rooms in a calendar view showing availability by date and time slot.

**FR-002** The calendar shall visually distinguish booked, available, and blocked time slots.

**FR-003** Organizers shall be able to click an available time slot to initiate a new booking for that room and time.

**FR-004** The system shall enforce conflict detection at the point of booking submission — a room cannot be double-booked for overlapping time slots. Two bookings overlap when their time ranges intersect; a booking that ends exactly when another begins is adjacent, not overlapping. *The atomic mechanism that guarantees no double-booking under concurrent submissions (a persistence-level guarantee, not a check-then-insert), and the "loser of the race" user experience (error shown, form data preserved, alternative slots offered), are **deferred to the architecture spec** — see NFR-002.*

---

### F2 — Booking Creation

**FR-010** Organizers shall complete the entire booking in a single unified form covering: room selection, event name, date, start and end time, agenda (optional), catering toggle, and registration settings. The event contact (the organizer's name and phone) is shown on the form pre-filled and read-only — see FR-040 and FR-095.

**FR-011** The system shall validate room availability for the selected date and time before accepting submission.

**FR-012** On successful submission, the system shall generate a unique registration link for the event and display it on the booking confirmation screen.

**FR-013** The system shall send a booking confirmation email to the organizer immediately upon successful submission.

**FR-014** Organizers shall be able to duplicate a past booking to pre-fill a new booking form with the same details.

**FR-015** Organizers shall be able to edit or cancel a booking they created.

**FR-016** When a booking is cancelled, the system shall send a notification email to all registered attendees for that event.

---

### F3 — Catering

**FR-020** Each booking shall include a catering toggle (lunch provided: yes / no) within the booking form. Organizers do not pre-select meal types.

**FR-021** When catering is enabled, each external registrant selects their own meal type during registration (see FR-041a). Meal-type selection is owned by the registrant, not the organizer.

**FR-022** The system shall aggregate registrant meal-type selections into per-meal-type counts, displayed to the organizer on the dashboard and to admins.

**FR-023** Organizers shall be able to turn the catering toggle on or off after booking creation. When catering is turned **off** after registrants have already selected meal types, those selections shall be **retained but dormant** — hidden from the aggregation and dashboard (FR-022), not deleted. If catering is turned back **on**, the previously-collected selections are restored. A registrant who registered while catering was off provided no meal type (FR-101); such registrants appear in the aggregation with an **unspecified / none** meal type until they optionally update it, and the aggregation (FR-022) shall tolerate registrants with no meal-type value.

---

### F4 — Registration Management (Organizer)

**FR-030** Each booking shall have a registration toggle (enabled / disabled) set at booking creation.

**FR-031** When registration is enabled, the unique registration link shall be prominently displayed on the organizer dashboard for each booking, with a one-click copy action.

**FR-032** The system shall not impose a maximum registrant capacity. Registration remains open until the closing date is reached or the organizer manually closes it.

**FR-033** Registration shall automatically close when the registration closing date is reached.

**FR-034** Organizers shall be able to set a registration closing date at booking creation. Registration shall close automatically at the end of that date.

**FR-034b** Organizers shall be able to manually close registration at any time before the closing date is reached.

**FR-034c** Registration close (automatic or manual) and booking cancellation shall be transactional with respect to in-flight registrations: any registration not fully committed before the close/cancel timestamp shall be rejected and shown the standard "registration closed" message (FR-046). A registration committed before a booking-cancel timestamp is a valid registrant and receives the cancellation notification (FR-016). *The concurrency/transaction implementation is deferred to the architecture spec.*

**FR-035** Organizers shall be able to view the registrant list for their events with status per registrant: **Registered**, **Cancelled**. *(Post-event attendance tracking — recording who actually showed up — is out of scope for MVP; see §7. The sign-in sheet (FR-036) and event QR (FR-038) support on-site sign-in on paper, not a system "Attended" status.)*

**FR-036** The system shall generate a downloadable sign-in sheet (PDF format) for each event listing all registered attendees.

**FR-037** The system shall send a reminder email **1 day before the event** to both the registered attendees and the organizer. This is a single fixed reminder — there are no multiple intervals and no per-booking configuration.

**FR-038** The system shall generate a QR code per event that links to the event's registration page. The QR code shall be downloadable by the organizer for on-site display.

---

### F5 — External Registration

**FR-040** Each event shall have a branded registration page displaying: the organization logo, event name, date, time, room name, agenda if the organizer provided one, and the event contact — the organizer's name and phone number — for registrant inquiries. The contact is **resolved live from the organizer's current profile** (FR-095): if the organizer later updates their profile name or phone, already-published registration pages reflect the change. The contact is not editable per event (it is never a free-text per-booking field).

**FR-041** The registration form shall collect five base fields: title (Mr, Mrs, Ms, or Other), first name, last name, organization, and email address. Selecting "Other" for title shall reveal a free-text field for the registrant to specify their preferred title.

**FR-041a** When catering is enabled for the event, the registration form shall additionally require the registrant to select a meal type: **Normal**, **Vegetarian**, **Muslim**, or **Other**. Selecting "Other" shall reveal a free-text field for the registrant to describe their dietary requirement.

**FR-042** On submission, the system shall immediately send a confirmation email to the registrant's email address via the organization's SMTP server.

**FR-043** The confirmation email shall include a unique self-cancellation link.

**FR-044** External registrants shall be able to cancel their own registration by clicking the link in the confirmation email — no login required.

**FR-045** Registration pages shall be publicly accessible without authentication.

**FR-046** When registration is closed (closing date passed or manually closed), the page shall display a clear message to visitors.

**FR-047** An external registrant who has lost their confirmation email shall be able to request that it be resent by entering their email address on the event's registration page. If a registration exists for that email on that event, the system resends the confirmation email (including the self-cancellation link). To avoid disclosing whether an email is registered, the page shows the same neutral acknowledgement regardless of whether a match was found.

**FR-048** Registration shall be **unique per (event, email address)**. An email already registered (and not cancelled) for an event cannot create a second registration for that same event; a repeat submission with an already-registered email is acknowledged with the same neutral response as FR-047 and does **not** create a duplicate registrant or a second confirmation email. This keeps the registrant count (FR-051), catering aggregation (FR-022), and sign-in sheet (FR-036) accurate, and makes the FR-047 resend unambiguous (exactly one registration to resend). A person who registers internally (F11) using a profile email that matches an existing external registration for the same event — or vice versa — shall be reconciled to a **single registrant record**, so each person is counted once per event regardless of registration path. A cancelled registration frees the (event, email) pair for a fresh registration. *The matching/reconciliation mechanism (e.g. case-folding of email, internal-vs-external identity linking) is deferred to the architecture spec.*

---

### F6 — Organizer Dashboard

**FR-050** The organizer dashboard shall display all upcoming bookings created by the logged-in organizer.

**FR-051** Each booking entry shall show: event name, room, date and time, registrant count, catering summary (count per meal type, aggregated from registrant selections), and the registration link.

**FR-052** The dashboard shall provide one-click copy of the registration link per booking.

**FR-053** The dashboard shall provide one-click download of the sign-in sheet PDF per booking.

---

### F7 — Admin: Room Management

**FR-060** Admins shall be able to add, edit, and deactivate rooms.

**FR-061** Each room record shall include: name, floor, capacity, photo (optional), and available features (projector, whiteboard, video conferencing — multi-select).

**FR-062** Admins shall be able to block time slots on any room for maintenance or reserved use.

**FR-063** Deactivated rooms shall not be available for new bookings and shall not appear in the room calendar. When an admin deactivates a room that has future bookings, the system shall automatically cancel those bookings and send a cancellation notification to each booking's owning organizer and its registered attendees. The admin shall be shown a confirmation warning listing the affected bookings before deactivation proceeds.

---

### F8 — Admin: Analytics & Reporting

**FR-070** Admins shall be able to view a utilization heatmap showing number of bookings per room per month across all rooms.

**FR-071** Admins shall be able to view a bulk calendar displaying all bookings across all rooms.

**FR-072** Admins shall be able to export booking and registrant data as CSV.

**FR-073** The system shall maintain an audit log of all bookings, cancellations, and modifications, recording: timestamp, actor, and change made.

---

### F9 — Email & Notifications

**FR-080** All outbound email shall be sent through the organization's dedicated SMTP server. No third-party email delivery service shall be used.

**FR-081** Admins shall be able to configure SMTP settings (host, port, sender name, sender email address) through a system settings panel.

**FR-082** The system shall send the following transactional emails:

| Trigger | Recipient |
|---------|-----------|
| Booking created | Organizer |
| Booking cancelled | All registered attendees |
| Registration submitted | External registrant |
| Reminder (1 day before the event) | All registered attendees + the organizer |
| Booking auto-cancelled by room deactivation | Owning organizer + that booking's registered attendees |

**FR-083** The sender display name in all outbound email shall show the organization name — not a generic system address — to ensure external recipients recognize and trust the sender.

**FR-084** Registration success shall be **decoupled from email-delivery success**: a registration (external FR-042 or internal F11) is committed and the registrant is counted even if its confirmation email fails to send — email failure shall never block or roll back a registration. *Because delivery uses the organization's SMTP only, with no third-party deliverability layer (Constraints), the delivery-failure handling — retry policy and backoff, queueing, failure visibility to the organizer/admin, and dead-letter/alerting — is **deferred to the architecture spec**, along with the scheduling and missed-run/idempotency behavior of the time-triggered emails (auto-close-related and the FR-037 reminder).*

---

### F10 — Authentication & Access Control

**FR-090** Internal users (organizers and admins) shall authenticate through the organization's identity provider.

**FR-091** The organizer and attendee capacities are the default for every authenticated internal user and require no assignment. The only assignable role is **admin** — an elevated permission that admins grant to or revoke from internal users through the system settings panel.

**FR-092** External registrant access shall be token-based via unique per-event links. No account creation or login is required.

**FR-093** Internal user sessions shall time out after a fixed period of inactivity (default 30 minutes), requiring re-authentication. This is a system default and is not exposed as an admin-configurable setting.

**FR-094** Role-based access control shall enforce:
- Organizers can **manage** (edit/cancel) only the bookings they created.
- Any internal user may **view**, read-only, another organizer's event **for the purpose of registering to attend** (FR-100) — limited to event details (event name, date, time, room, agenda, contact). They cannot see that event's registrant list or registrant data, and cannot edit or cancel the booking.
- Admins have read access to all bookings and registrant data across the system. Admins cannot create, approve, or manually edit bookings; the only system-initiated change to a booking resulting from an admin action is the automatic cancellation of future bookings when their room is deactivated (FR-063).

**FR-095** Each internal user profile shall include: **title/prefix, first name, last name, phone number, email address, and organization** (department/affiliation). The booking organizer's name (first + last) and phone are used automatically as the registration-page contact (FR-040) and are not editable on a per-booking basis. The profile's title, name, email, and organization are used to auto-populate the user's internal registrant record when they register to attend an event (FR-101).

**Profile population:** The profile is completed by the user through a **self-service profile screen presented on first login**. The user cannot reach the main application until the required fields are complete. **Email is sourced from the organization's identity provider (FR-090) and is read-only** — the user cannot edit it. All other fields (title, first name, last name, phone, organization) are user-entered and app-owned, and **editable later by the user**; because the registration-page contact is resolved live (FR-040), an organizer's profile edits propagate to their already-published registration pages. *The precise identity-provider attribute mapping — which profile fields, if any beyond email, the IdP can pre-supply — is **deferred to the architecture spec**, to be settled once the real IdP's available attributes are known.*

---

### F11 — Internal Registration (Attend an Event)

**FR-100** Authenticated internal users shall be able to register to attend any event that is open for registration, from within the application — without using the public per-event link. This path is distinct from external registration (F5), which remains anonymous and token-based (FR-045).

**FR-101** For internal registration, the registrant's identity — title/prefix, name, organization, and email — shall be auto-populated from the user's profile (FR-095) and shown read-only. When catering is enabled for the event, meal-type selection (FR-041a) is the only field the internal user provides; when catering is disabled, registration requires confirmation only, with no fields to complete.

**FR-102** An internal registrant shall become a registrant of the event identical to an external registrant — counted in the registrant total, listed in the registrant list (FR-035), included in catering aggregation (FR-022), the sign-in sheet (FR-036), and all attendee notifications (FR-082). For notification purposes, internal registrants are "registered attendees." Internal registration is confirmed **in-app** (no separate "registration submitted" email is sent to internal registrants); they still receive the cancellation and reminder emails directed at registered attendees (FR-082).

**FR-103** Internal registrants shall be able to cancel their own attendance from within the application, without a token link.

**FR-104** Registration close rules (FR-033, FR-034, FR-034b, FR-046) shall apply equally to internal registration; a closed event accepts no internal registrations.

**FR-105** The owning organizer **may** also register to attend their own event via the same in-app "Register to attend" action (FR-100). When they do, they are counted as a registrant identical to any other internal registrant — included in the registrant total, registrant list (FR-035), catering aggregation (FR-022), sign-in sheet (FR-036), and notifications (FR-082). Per FR-048 they are counted **once** as a registrant of their own event regardless of path. If they cancel the booking (FR-015) while registered to attend it, they receive the resulting cancellation notification (FR-016) as a registered attendee even though they triggered it — this self-notification is acceptable. An **admin** viewing another organizer's event in order to register (FR-094) acts in their attendee capacity for that action and sees only event details, not the registrant list, for that event; their system-wide admin read access (FR-094) is a separate capability and is unchanged.

---

## 5. Non-Functional Requirements

**NFR-001 Security** — The system shall have no known critical or high-severity vulnerabilities at launch. Session tokens and authentication credentials shall be stored securely. *The concrete security mechanisms — credential hashing algorithm, at-rest encryption, the entropy / expiry / single-use semantics of the external per-event access tokens and self-cancellation links (FR-043, FR-092), TLS in transit, and the vulnerability-scanning standard and CVSS cutoff used to verify "no critical/high" — are **deferred to the architecture spec**.*

**NFR-002 Reliability** — Conflict detection shall prevent double-bookings. This is **verified by a concurrency test**: multiple simultaneous overlapping booking submissions for the same room must yield exactly one success and reject the rest. The production "zero double-booking incidents" figure (§2) is a **monitoring KPI, not an acceptance gate** (zero observed incidents can only ever be falsified, never positively proven). *The atomic mechanism that delivers this guarantee is deferred to the architecture spec — see FR-004.*

**NFR-003 Performance** — The room calendar and organizer dashboard shall load within 3 seconds. *The concrete load envelope this target must hold under — concurrent organizers, room count, registration throughput, and dataset size — is **deferred to the architecture spec** and its performance-test plan; until defined there, the 3-second figure is an aspirational target, not an acceptance gate.*

**NFR-004 Responsiveness** — The external registration and confirmation pages shall be fully usable on **both mobile and desktop browsers with equal priority** (not smartphone-only). The organizer booking flow shall be usable on a smartphone browser. In all cases, no horizontal scrolling or zoom shall be required.

**NFR-005 Data Retention** — Booking and registrant records shall be retained indefinitely until explicitly deleted by an admin.

**NFR-006 Localization** — The production user interface shall be presented in **Thai** as a single language. All user-facing text, transactional emails, and generated documents (e.g., the sign-in sheet PDF) shall be in Thai. *(System fonts must support the Thai script — see the UX spec.)*

**NFR-007 Accessibility** — The public registration and confirmation pages (FR-045) and the internal application shall conform to **WCAG 2.1 Level AA**. Behavioral and visual accessibility specifics (focus order, contrast ratios, Thai line-height) are detailed in the UX spec.

---

## 6. Constraints

- **SMTP only** — all outbound email must use the organization's dedicated SMTP server. Third-party email delivery services (e.g., SendGrid, Mailgun) are not permitted.
- **No calendar sync** — no integration with Google Calendar, Outlook, or other external calendar systems is required.
- **External registrant data minimization** — external registrants provide only: title, first name, last name, organization, email, and (when catering is enabled) a meal-type selection. No additional data collection.
- **Admin has no approval authority** — the admin role is operational and analytical only. Admins do not approve or reject bookings.
- **Rooms are uncapped** — rooms have no enforced seating-capacity limit, and registration is never constrained by room capacity (FR-032). The room `capacity` field (FR-061), if provided, is informational only.
- **No separate catering cutoff** — meal-type counts follow registration; there is no meal-count cutoff distinct from registration close (FR-033/FR-034).
- **Canonical timezone** — all business-time computations (the registration-close "end of date" in FR-034, the "1 day before the event" reminder fire time in FR-037, and audit timestamps in FR-073) use a single canonical timezone, **Asia/Bangkok (UTC+7)**, consistent with the Thai-only UI (NFR-006). The exact fire times, scheduling approach, and missed-run/idempotency behavior are deferred to the architecture spec (FR-084).
- **Full replacement** — this system fully replaces the existing booking and registration tools. Patching or extending the current system is not acceptable due to security vulnerabilities.

---

## 7. Out of Scope (Post-MVP)

The following capabilities were identified as valuable but are deferred after initial launch:

- Waitlist feature with auto-notification when a slot opens
- Meeting template / reusable event setup library
- Room filtering on calendar by features (projector, capacity range, floor)
- Admin heatmap filtering by floor or capacity range
- Admin heatmap hover tooltips (show exact booking count per cell on hover)
- Post-event feedback form sent automatically to registrants
- Invite-only registration (vs. open link sharing)
- **Attendance tracking** — a system "Attended" status and any check-in mechanism (manual marking or QR-based self check-in). MVP records only Registered / Cancelled (FR-035); on-site sign-in is handled on paper via the sign-in sheet (FR-036).
