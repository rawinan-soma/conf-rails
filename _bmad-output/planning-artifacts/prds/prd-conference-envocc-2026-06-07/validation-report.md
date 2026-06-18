# Validation Report — ENVOCC Conference Room Booking System

- **PRD:** `_bmad-output/planning-artifacts/prds/prd-conference-envocc-2026-06-07/prd.md`
- **Rubric:** `.claude/skills/bmad-prd/assets/prd-validation-checklist.md`
- **Run at:** 2026-06-18T21:25:55+0700
- **Grade:** Fair

## Overall verdict

A tight, internally consistent PRD that knows exactly what it is: a security-driven full replacement of a fragmented two-app booking + registration system for a single organization. Strongest in done-ness clarity and downstream usability — FRs are granular, ID-stable, and cross-referenced through a coherent role model that resolves the hard role edge cases (FR-094 RBAC, FR-063 cascade, F11 internal vs. external registration). On the rubric alone it is "Good": no broken dimension, one thin dimension (scope honesty), one high finding.

The grade is **Fair** because the adversarial pass materially shifts the picture: 6 critical and 9 high implementation-readiness gaps. The headline "100% / 0 double-bookings" claim (NFR-002) is currently both unimplementable and untestable — FR-011→FR-004 is a check-then-insert race with no atomic guarantee (C-1, C-2). Time-sensitive logic names no timezone or fire time (C-3); email-delivery failure is unhandled despite the confirmation email being the registrant's only artifact and cancellation path (C-4); duplicate registration by the same email is never prevented (C-6); and "Attended" is a dead enum no FR sets (H-6). These are under-specification gaps — the material the architecture and correct-course phases exist to resolve — but should be closed before downstream work leans on them. The frontmatter also still reads `project_name: conference-envocc` inside a project called `conf-rails` (M-2).

## Dimension verdicts
- Decision-readiness — adequate
- Substance over theater — strong
- Strategic coherence — strong
- Done-ness clarity — adequate
- Scope honesty — thin
- Downstream usability — strong
- Shape fit — strong

## Findings by severity

### Critical (6) — all from adversarial review
- **[Adversarial]** C-1 — Conflict detection has no concurrency/race-condition spec (FR-004, FR-011, NFR-002). Check-then-insert TOCTOU race; "100%" unimplementable and untestable as written.
  Fix: atomic DB-level overlap constraint + loser-of-race UX + concurrency test.
- **[Adversarial]** C-2 — "Overlapping time slots" never defined; interval/boundary semantics unspecified (FR-004).
  Fix: define half-open [start, end); adjacent bookings don't conflict; validate end > start + min duration.
- **[Adversarial]** C-3 — Timezone & date-boundary behavior unspecified across all time logic (FR-033, FR-034, FR-037, FR-093).
  Fix: declare Asia/Bangkok canonical; define "end of date" 23:59:59; define exact reminder fire time.
- **[Adversarial]** C-4 — Email delivery failure handling completely absent (FR-013, FR-016, FR-042, FR-080, FR-082).
  Fix: retry policy + failure visibility + queue/status; decouple registration commit from send; recovery path.
- **[Adversarial]** C-5 — Manual close/cancel of in-flight registrations undefined (FR-034b, FR-015, FR-063, FR-104).
  Fix: transactional close/cancel; reject registrations not committed before close timestamp.
- **[Adversarial]** C-6 — Duplicate registration by the same email never addressed (FR-041, FR-047, FR-101, FR-105).
  Fix: enforce uniqueness on (event, email); reconcile internal vs. external vs. organizer-self.

### High (10)
- **[Done-ness clarity]** "Normal organizational load" undefined (NFR-003). Fix: state the load envelope the 3s target holds under.
- **[Adversarial]** H-1 — Untestable/vague NFR thresholds, no verification method (NFR-001, NFR-003, NFR-004). Fix: quantify load, name scanner+CVSS cutoff, concrete security requirements.
- **[Adversarial]** H-2 — "100% / 0 incidents" is not a measurable success metric (Goal 4, NFR-002). Fix: convert to a concurrency verification criterion; keep "0" as a monitoring KPI only.
- **[Adversarial]** H-3 — Self-cancellation token security & lifetime unspecified (FR-043, FR-044, FR-092). Fix: ≥128-bit random, single-use, expiry tied to event, post-cancellation state.
- **[Adversarial]** H-4 — Resend anti-enumeration claimed but other surfaces leak (FR-047 vs FR-051, FR-072). Fix: also neutralize the submit path; constant-time-ish resend.
- **[Adversarial]** H-5 — Auto-close/reminder scheduling mechanism & reliability undefined (FR-033, FR-037). Fix: scheduling approach, missed-run recovery, idempotency.
- **[Adversarial]** H-6 — "Attended" status has no transition mechanism (FR-035, FR-036, FR-038). Fix: add a check-in FR or remove the status.
- **[Adversarial]** H-7 — Catering toggled off after registrations exist — meal-data fate undefined (FR-021, FR-022, FR-023). Fix: define meal-type lifecycle across toggle transitions.
- **[Adversarial]** H-8 — Profile contact propagation vs. read-only per-event contact: snapshot vs. live unstated (FR-040, FR-095). Fix: state snapshot-at-creation or resolved-live and the consequence.
- **[Adversarial]** H-9 — Organizer-as-registrant / admin-as-viewer intersections under-specified (FR-094, FR-100, FR-105). Fix: add a role-intersection resolution matrix incl. self-notification suppression.

### Medium (5)
- **[Decision-readiness]** Dangling "resolves OQ-3" with no Open Questions section (FR-095). Fix: add a Resolved Questions subsection or drop the reference.
- **[Done-ness clarity]** "Stored securely" is an adjective, not a bound (NFR-001). Fix: name the mechanism or defer to architecture by reference.
- **[Scope honesty]** No Assumptions Index / inline `[ASSUMPTION]` tags despite inferred defaults (FR-093, FR-095, NFR-003, NFR-005). Fix: tag inline + collect in an index.
- **[Adversarial — selected]** M-2 stale frontmatter (`conference-envocc` in `conf-rails`); M-3 edit-booking-with-registrants undefined (FR-015); M-5 audit log excludes registration/role-grant/SMTP-change events (FR-073); M-6 CSV scope/encoding/PII unspecified (FR-072); M-10 "Other" free-text has no length/sanitization spec (FR-041/041a, XSS/CSV-injection). *(Full 11 medium findings in `review-adversarial-general.md`.)*

### Low (8)
- **[Strategic coherence]** No counter-metrics named (§2). Fix: add one guardrail metric.
- **[Done-ness clarity]** No explicit acceptance section; relies on FR consequences (§4–§5).
- **[Decision-readiness]** Uncapped-registration vs. room-capacity tension not surfaced (FR-032, FR-061).
- **[Scope honesty]** No `[NON-GOAL for MVP]` inline callouts (FR-032, FR-014).
- **[Downstream usability]** No explicit Glossary (§3 carries it implicitly).
- **[Adversarial — selected]** L-4 indefinite PII retention incl. religious-adjacent meal data, no policy (NFR-005); L-5 30-min session timeout, no warning/draft preservation (FR-093); L-7 "equal priority" mobile/desktop is directional, not testable (NFR-004). *(Full 7 low findings in `review-adversarial-general.md`.)*

## Mechanical notes
- Stale identity: frontmatter `project_name: conference-envocc` / title "ENVOCC…" while host project is `conf-rails` — reconcile during Correct Course.
- Dangling ID reference: FR-095 "resolves OQ-3" but no OQ list exists — clearest mechanical defect.
- FR numbering gaps are intentional spacing; FR-034b / FR-041a unique and correct; no duplicates.
- No Assumptions Index and no Glossary; domain nouns nonetheless consistent.
- Missing relative to rubric scaffolding: Open Questions, Assumptions Index, `[NOTE FOR PM]` callouts, explicit Glossary.

## Reviewer files
- `review-rubric.md`
- `review-adversarial-general.md`
