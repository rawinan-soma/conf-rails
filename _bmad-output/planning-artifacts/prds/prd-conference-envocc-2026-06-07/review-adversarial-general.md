# Adversarial Review — ENVOCC Conference Room Booking System PRD

**Reviewer stance:** Cynical, skeptical, hunting for gaps, contradictions, ambiguity, untestable acceptance criteria, hidden assumptions, and unhandled edge cases. Scope: PRD-internal quality only. Project-fit reconciliation (e.g., the `project_name: conference-envocc` frontmatter living in a project called `conf-rails`) is handled separately and is only flagged here where it bleeds into internal consistency.

**Document:** `prd.md` (status: final, finalized 2026-06-07, updated 2026-06-09)

---

## Severity Counts

| Severity | Count |
|----------|-------|
| Critical | 6 |
| High | 9 |
| Medium | 11 |
| Low | 7 |
| **Total** | **33** |

---

## CRITICAL

### C-1 — Conflict detection has no concurrency/race-condition specification (FR-004, FR-011, NFR-002, Goal 4)
> FR-004: "The system shall enforce conflict detection **at the point of booking submission**"
> NFR-002: "Conflict detection shall prevent double-bookings with **100% accuracy**."
> Goal 4 / Success Metric: "Double-booking incidents | 0 (conflict detection blocks 100%)"

The PRD asserts 100% accuracy as the headline reliability claim but never addresses the only scenario where double-booking actually occurs: **two organizers submitting overlapping bookings for the same room in the same instant.** "Check availability then insert" (FR-011 → FR-004) is a textbook time-of-check-to-time-of-use race. Without a specified locking strategy (DB unique/exclusion constraint, serializable transaction, `SELECT ... FOR UPDATE`, advisory lock), the 100% guarantee is unimplementable as written, and "100% accuracy" is **untestable** — there is no defined test for the concurrent case, no expected error behavior, and no defined user experience for the loser of the race.
**Fix:** Add an FR mandating an atomic conflict guarantee at the persistence layer (e.g., a database-level exclusion/overlap constraint), and specify the loser-of-race UX: error message shown, form data preserved, alternative slots suggested. Define the concurrency test that validates "100%."

### C-2 — "Overlapping time slots" is never defined; boundary semantics unspecified (FR-004)
> FR-004: "a room cannot be double-booked for **overlapping time slots**."

No definition of overlap. Is a booking 09:00–10:00 in conflict with one starting at 10:00–11:00? (Half-open `[start, end)` vs. closed `[start, end]` intervals produce different answers.) Are there buffer/turnaround times between bookings? Is zero-duration or end-before-start input rejected? An implementer must guess the interval algebra, and "100% accuracy" cannot be validated without it.
**Fix:** Define intervals as half-open `[start, end)`, state explicitly that adjacent bookings (one ends exactly when the next starts) do **not** conflict, and add validation FRs for end > start and minimum duration.

### C-3 — Timezone and date-boundary behavior unspecified across all time-sensitive logic (FR-033, FR-034, FR-037, FR-093, NFR-006)
> FR-034: "Registration shall close automatically **at the end of that date**."
> FR-037: "send a reminder email **1 day before the event**"

"End of that date" — in whose timezone? Server UTC? Organization-local (Thailand, UTC+7)? Registrant-local? With a Thai-only UI (NFR-006), "end of date" almost certainly means 23:59:59 Asia/Bangkok, but this is nowhere stated. "1 day before the event" — 24 hours before start time, or a fixed clock time on the prior calendar day? An event at 08:00 with a reminder "1 day before" sent at midnight is 8 hours' notice; sent at the same clock time is 24 hours. This is the kind of off-by-a-day bug that ships to production silently.
**Fix:** Declare a canonical timezone (Asia/Bangkok) for all business-time computations. Define "end of date" as 23:59:59 in that zone. Define the reminder fire time precisely (e.g., "09:00 Asia/Bangkok on the calendar day before the event date").

### C-4 — Email delivery failure handling is completely absent (FR-013, FR-016, FR-042, FR-080, FR-082, NFR-002)
> FR-042: "On submission, the system shall **immediately** send a confirmation email"
> FR-080: "All outbound email shall be sent through the organization's **dedicated SMTP server**."

SMTP-only with no third-party provider (Constraint) means no managed retry/deliverability layer — yet there is **zero** specification for what happens when the SMTP server is down, rejects, times out, or soft-bounces. For external registration (FR-042/FR-043), the confirmation email **is the only artifact** the registrant receives, and it carries the sole self-cancellation link (FR-043/FR-044). If that email silently fails, the registrant has no record, no cancellation path, and no way to know. The resend mechanism (FR-047) presupposes the registration succeeded, but says nothing about the case where the original send failed at submission time.
**Fix:** Add an FR for delivery failure handling: retry policy (count, backoff), failure visibility to the organizer/admin, decoupling registration success from email-send success (queue + status), and a dead-letter/alert path. Clarify that registration is committed even if email send fails, and how the registrant recovers.

### C-5 — Manual close / cancel of in-flight registrations is undefined; concurrency on close (FR-034b, FR-015, FR-063, FR-104)
> FR-034b: "Organizers shall be able to **manually close registration at any time**"
> FR-104: "a closed event accepts **no** internal registrations"

What happens to a registration submission that is in-flight at the exact moment the organizer closes registration or cancels the booking? Is a partially submitted external registration accepted or rejected? FR-046/FR-104 describe steady-state closed behavior but not the transition. Same problem for FR-015 (organizer cancels booking) and FR-063 (admin deactivates room → auto-cancel): a registrant could be mid-submission. Without a defined ordering rule, you get registrations attached to cancelled events, confirmation emails for events that no longer exist, and registrant counts that disagree with reality.
**Fix:** Specify that close/cancel is transactional and that any registration not fully committed before the close timestamp is rejected with the standard "registration closed" message. Define behavior for registrations committed milliseconds before cancel (they receive the cancellation email per FR-016).

### C-6 — Duplicate registration by the same email is never addressed (FR-041, FR-042, FR-047, FR-101, FR-105)
> FR-041: "collect five base fields: title ... and **email address**."
> FR-047: "**If a registration exists for that email on that event**, the system resends..."

FR-047 assumes at most one registration per email per event ("a registration exists for that email") — but nothing in F5 prevents the same external email from registering 2, 5, or 50 times for one event. Each duplicate inflates the registrant count (Success Metric, FR-051), the catering aggregation (FR-022), and the sign-in sheet (FR-036), and produces multiple confirmation emails with multiple self-cancellation links — making the resend logic in FR-047 ambiguous (which registration does it resend?). Compounding: an **internal user who is also the owning organizer** (FR-105) could register internally (FR-100) AND externally with the same email via the public link, double-counting themselves.
**Fix:** Decide and state the dedup rule: enforce uniqueness on (event, email) for external registrations, and reconcile internal vs. external registration by the same email/person. If duplicates are intentionally allowed, FR-047 must define which registration's link is resent.

---

## HIGH

### H-1 — Untestable / vague NFR thresholds with no verification method (NFR-001, NFR-003, NFR-004)
> NFR-003: "shall load within 3 seconds under **normal organizational load**."
> NFR-001: "credentials shall be stored **securely**."

"Normal organizational load" has no number — how many concurrent users, how many rooms, how many bookings/registrants in the dataset? Three seconds against an empty DB is trivial; against 10k bookings it's a real target. "Securely" is unverifiable as written (which algorithm? hashing for what? at-rest encryption?). NFR-001's "no known critical or high-severity vulnerabilities" needs a defined scanning tool/standard and a CVSS cutoff to be auditable.
**Fix:** Quantify load (e.g., "p95 ≤ 3s with N concurrent users and a dataset of M bookings"). Specify the security scanner/standard and CVSS threshold for NFR-001. Replace "stored securely" with concrete requirements (credentials hashed with bcrypt/argon2; tokens stored hashed; TLS in transit).

### H-2 — "100% accuracy" / "0 incidents" as a success metric is not measurable (Goal 4, Success Metrics, NFR-002)
> Success Metric: "Double-booking incidents | 0"

A target of zero observed incidents in production is a lagging, unfalsifiable metric — you can only ever fail it, never positively verify it, and a single unobserved race could pass undetected. There is no acceptance test defined that exercises the concurrent path (see C-1).
**Fix:** Convert to a verification criterion: "A defined concurrency test (K simultaneous overlapping booking submissions) results in exactly one success and K-1 rejections." Keep the production metric as a monitoring KPI, not an acceptance gate.

### H-3 — Self-cancellation token security and lifetime unspecified (FR-043, FR-044, FR-092, NFR-001)
> FR-043: "include a unique self-cancellation link."
> FR-092: "External registrant access shall be **token-based** via unique per-event links."

No specification of token entropy, expiry, single-use vs. reusable, or what happens after cancellation (is the link dead? can it re-register?). Same gap for the per-event registration link (FR-092) — is it guessable? does it expire when registration closes? A weak or non-expiring token lets anyone cancel anyone's registration or enumerate registrations. This directly undercuts NFR-001 yet is left to the implementer.
**Fix:** Specify token format (cryptographically random, ≥128-bit), single-use semantics for cancellation, expiry tied to event lifecycle, and the post-cancellation state.

### H-4 — Resend acknowledgement claims anti-enumeration but other surfaces leak (FR-047 vs. FR-051, FR-072, registrant count)
> FR-047: "To avoid disclosing whether an email is registered, the page shows the **same neutral acknowledgement** regardless of whether a match was found."

Good intent, but the threat model is inconsistent. The public registration page can still leak via timing (a real send takes longer than a no-op) and the registrant count is surfaced on the organizer dashboard (FR-051). More importantly, FR-047's privacy posture is undermined if duplicate registrations exist (C-6) or if the registration form itself returns a different response for an already-registered email (undefined — see C-6). The anti-enumeration requirement is stated for one endpoint while the actual disclosure risk is unaddressed elsewhere.
**Fix:** State that the registration submit path must also avoid distinguishing "already registered" from "newly registered" to an anonymous user, and require constant-time-ish response behavior for the resend path.

### H-5 — Auto-close scheduling mechanism and reliability undefined (FR-033, FR-037, FR-082)
> FR-033: "Registration shall **automatically** close..."
> FR-037: "send a reminder email **1 day before**..."

Both are time-triggered background jobs, but the PRD never says how they fire (cron? scheduler? on-read lazy evaluation?), what happens if the job server is down at the trigger moment (does a missed reminder get sent late or skipped?), or whether reminders are idempotent (no duplicate reminder if the job runs twice). For a system whose only notification channel is fragile SMTP (C-4), missed/duplicated time-triggered emails are a real risk left entirely to the implementer.
**Fix:** Specify the scheduling approach, missed-run recovery behavior (catch-up window vs. skip), and idempotency (a reminder is sent at most once per registrant per event).

### H-6 — "Attended" status has no defined transition mechanism (FR-035, FR-036)
> FR-035: "status per registrant: Registered, **Attended**, Cancelled."

The data model includes an "Attended" status but **nothing in the PRD sets it.** There is a sign-in sheet PDF (FR-036) and a QR code (FR-038), but no FR describes check-in: who marks a registrant attended, how, when, via what UI, and whether the QR code feeds it. As written, "Attended" is a dead enum value — an implementer cannot build the transition.
**Fix:** Add an FR for attendance marking (e.g., organizer marks attendance on the registrant list, or QR-based self check-in), or remove "Attended" from FR-035 if out of scope.

### H-7 — Catering toggled off after registrations exist — meal-data fate undefined (FR-021, FR-022, FR-023, FR-041a)
> FR-023: "Organizers shall be able to turn the catering toggle **on or off after booking creation**."

If catering is enabled, registrants pick meal types (FR-041a), then the organizer toggles catering **off** (FR-023): what happens to the already-collected meal selections and the aggregated counts (FR-022)? Are they hidden, deleted, or retained-but-dormant? If catering is toggled back **on**, do previously-registered attendees get re-prompted for a meal type they never supplied (they registered while it was off, per FR-101: "no fields to complete")? This creates registrants with null meal types inside an aggregation that assumes a value.
**Fix:** Define meal-type data lifecycle across toggle transitions, and specify the aggregation/display behavior for registrants who have no meal type because they registered while catering was off.

### H-8 — Organizer profile contact propagation conflicts with read-only per-event contact (FR-040, FR-080/FR-095 vs. live edits)
> FR-040: "The contact is **auto-populated** from the organizer's profile and **is not editable per event**."
> FR-095: "editable later by the user."

The registration-page contact (name + phone) is pulled live from the organizer's profile, which the user can edit at any time (FR-095). So if an organizer changes their phone number after creating a booking, does the published registration page contact change retroactively for an event that already has registrants? Is the contact snapshotted at booking time or resolved live? The PRD implies live ("auto-populated ... not editable per event") but never says, and the two FRs together create an ambiguity an implementer will resolve by guessing.
**Fix:** State explicitly whether the contact is snapshotted at booking creation or resolved live from the current profile, and the consequence for already-published registration pages.

### H-9 — Internal-user-as-both-organizer-and-registrant edge cases under-specified (FR-094, FR-100, FR-105, FR-035)
> FR-094: "Organizers can manage ... only the bookings they created."
> FR-105: "The owning organizer **may** also register to attend their own event."

When the owning organizer registers for their own event (FR-105), they now appear in their own registrant list (FR-035) which they manage. Can they cancel their own attendance via FR-103 AND see/manage it as the organizer simultaneously? When they cancel the booking (FR-015), do they — as a registered attendee of their own event — receive the FR-016 cancellation email they themselves triggered? Also: an internal user viewing another organizer's event for registration (FR-094 read-only) — if they are *also* an admin, do admin read-all rights override the "cannot see registrant list" restriction? The role-capacity matrix has unhandled intersections.
**Fix:** Add a short conflict-resolution matrix for the organizer-as-registrant and admin-as-registrant/viewer cases, including self-notification suppression.

---

## MEDIUM

### M-1 — "Prominently displayed" is untestable (FR-031)
> FR-031: "the unique registration link shall be **prominently displayed** on the organizer dashboard"
"Prominently" cannot be verified. **Fix:** Replace with a concrete placement/visibility requirement, or defer styling to the UX spec and drop the adjective from the FR.

### M-2 — Stale frontmatter / identity inconsistency (frontmatter, title)
> `project_name: conference-envocc` and `title: "ENVOCC Conference Room Booking System — PRD"`
The PRD self-identifies as ENVOCC/conference-envocc while residing in a project called `conf-rails`. Flagged here only as an internal-consistency smell that will confuse anyone tracing artifacts; full project-fit reconciliation is out of scope for this review. **Fix:** Reconcile frontmatter with the host project (handled separately).

### M-3 — Editing a booking with existing registrants is undefined (FR-015)
> FR-015: "Organizers shall be able to **edit** or cancel a booking they created."
What if an organizer edits the date/time/room of a booking that already has registrants? Are attendees notified of the change? Is re-conflict-detection (FR-004) re-run on the new slot? FR-016 only covers cancellation, not edits. **Fix:** Define which fields are editable post-registration, whether edits re-run conflict detection, and whether attendees are notified of material changes (date/time/room).

### M-4 — "1 day before" reminder for events created <1 day out (FR-037)
> FR-037: "send a reminder email **1 day before the event**"
If a booking is created less than 24 hours before the event, the reminder window has already passed. Is the reminder skipped, sent immediately, or never sent? Undefined. **Fix:** Specify behavior when the reminder fire time is in the past at creation.

### M-5 — Audit log scope excludes registration events (FR-073)
> FR-073: "an audit log of all **bookings, cancellations, and modifications**"
The audit log covers bookings but is silent on registration/cancellation by attendees, admin role grants/revokes (FR-091), room deactivations (FR-063), and SMTP setting changes (FR-081) — all security-relevant actions. **Fix:** Either broaden the audit scope explicitly or state these are deliberately excluded.

### M-6 — CSV export scope, format, and PII handling unspecified (FR-072)
> FR-072: "export booking and registrant data as CSV."
No column spec, no filtering (all events ever? date range?), no encoding (Thai text → UTF-8 BOM for Excel?), no statement on whether cancelled/duplicate registrants are included. Given NFR-006 (Thai), CSV encoding is a real foot-gun. **Fix:** Specify columns, scope/filters, encoding (UTF-8 with BOM), and inclusion rules for cancelled registrants.

### M-7 — Sign-in sheet contents and timing relative to close undefined (FR-036)
> FR-036: "downloadable sign-in sheet (PDF) ... listing **all registered attendees**."
Does "registered" include or exclude Cancelled-status registrants? Can it be generated before registration closes (and thus be stale)? Does it include meal type, organization, title? Undefined fields for a printed artifact. **Fix:** Specify columns and the registrant-status filter; clarify it reflects a point-in-time snapshot.

### M-8 — Room block vs. existing/future bookings interaction undefined (FR-062, FR-063)
> FR-062: "Admins shall be able to **block time slots** on any room"
FR-063 carefully handles deactivation (auto-cancel + notify), but FR-062 blocking says nothing about what happens if a block overlaps an existing booking. Does blocking cancel/notify like deactivation, or is it prevented? Inconsistent treatment of two similar admin actions. **Fix:** Define block-vs-existing-booking behavior with the same rigor as FR-063.

### M-9 — Heatmap "comprehension time ≤ 30 seconds" is not objectively testable (Success Metrics, FR-070)
> "Admin heatmap comprehension time | ≤ 30 seconds"
A subjective usability metric with no defined measurement protocol (task? sample size? what counts as "comprehended"?). **Fix:** Define the usability test protocol or reclassify as an aspirational UX goal, not an acceptance metric.

### M-10 — "Other" free-text fields have no validation/length/sanitization spec (FR-041, FR-041a)
> FR-041: "Selecting 'Other' ... shall reveal a **free-text field**"
Free-text from anonymous users, rendered later on dashboards, sign-in PDFs, and CSV exports — no max length, no sanitization requirement (XSS / CSV-injection via `=cmd`). **Fix:** Specify max length and require output encoding / CSV-injection neutralization (consistent with NFR-001).

### M-11 — Registration-disabled bookings: link/QR behavior undefined (FR-012, FR-030, FR-038)
> FR-012: "On successful submission, the system shall generate a unique registration link" (unconditional)
> FR-030: "Each booking shall have a registration toggle (enabled / disabled)"
FR-012 generates a link for every booking, but FR-030 allows registration to be disabled. What does the link/QR (FR-038) show when registration is disabled — the closed message (FR-046 only mentions closed, not disabled)? Is FR-046's "closed" the same as "disabled"? **Fix:** Clarify the disabled state and whether FR-046's message covers it.

---

## LOW

### L-1 — Title "Other" free-text vs. localization (FR-041, NFR-006)
The fixed titles (Mr, Mrs, Ms) are English in a Thai-only UI (NFR-006). Are these labels translated? **Fix:** Confirm the localized title set.

### L-2 — Internal registrant with no profile email conflict (FR-095, FR-101)
Email is read-only from OIDC (FR-095). If a registrant's internal OIDC email differs from one they'd use externally, the dedup question (C-6) is harder. Minor relative to C-6. **Fix:** Note as part of dedup resolution.

### L-3 — "Photo (optional)" room field — no size/format/storage spec (FR-061)
No constraints on upload type, size, or storage location. **Fix:** Add basic upload constraints.

### L-4 — Data retention "indefinitely" vs. privacy/PII (NFR-005)
> NFR-005: "retained **indefinitely** until explicitly deleted by an admin."
Indefinite retention of registrant PII (emails, dietary/religious meal info — "Muslim" meal type is special-category-adjacent) with no policy may conflict with data-protection norms. **Fix:** Confirm retention is intentional and policy-reviewed; consider a deletion/anonymization path.

### L-5 — Session timeout fixed at 30 min, non-configurable, no warning (FR-093)
No mention of a pre-timeout warning or in-flight form preservation (an organizer loses a half-filled booking form on timeout). **Fix:** Specify timeout-warning UX and draft preservation.

### L-6 — Duplicate booking (FR-014) copies registration link/dates blindly (FR-014, FR-012)
> FR-014: "duplicate a past booking to **pre-fill** a new booking form"
Does duplication copy the closing date (likely now in the past) and generate a fresh registration link, or reuse the old one? Pre-fill of a past date is a likely UX trap. **Fix:** Specify which fields are pre-filled vs. reset on duplicate.

### L-7 — "Equal priority" mobile/desktop is directional, not testable (NFR-004)
> NFR-004: "fully usable on both mobile and desktop browsers with **equal priority**"
"Equal priority" is intent, not a criterion; "fully usable" and "no horizontal scrolling or zoom" are the testable parts. **Fix:** Drop "equal priority" as a requirement phrase; keep the concrete breakpoints/no-scroll criteria.

---

## Summary of Highest-Leverage Fixes
1. **Specify atomic conflict detection** (DB-level overlap constraint) and the loser-of-race UX — without it, the flagship "100% / 0 incidents" claim is both unimplementable and untestable (C-1, C-2, H-2).
2. **Declare a canonical timezone (Asia/Bangkok)** and precise fire times for close/reminder logic (C-3).
3. **Specify email-failure handling** and decouple registration commit from SMTP send — the confirmation email is a single point of failure carrying the only cancellation link (C-4, H-3, H-5).
4. **Define the dedup rule** for (event, email) and reconcile internal vs. external vs. organizer-self registration (C-6, H-9).
5. **Resolve the "Attended" dead enum** — add a check-in FR or remove the status (H-6).
