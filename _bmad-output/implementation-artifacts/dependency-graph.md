# Story Dependency Graph
_Last updated: 2026-06-19T09:45:00+07:00_

## Stories

| Story | Epic | Title | Sprint Status | Issue | PR | PR Status | Dependencies | Ready to Work |
|-------|------|-------|--------------|-------|----|-----------|--------------|---------------|
| 1.1   | 1    | Project initialization & platform scaffold | done | #1 | #28 | merged | none | ✅ Yes (done) |
| 1.2   | 1    | Core design system & ViewComponent UI library | backlog | #2 | — | — | 1.1 | ✅ Yes |
| 1.3   | 1    | OIDC authentication & sessions | backlog | #3 | — | — | 1.1 | ✅ Yes |
| 1.4   | 1    | Capacities, admin role & Pundit authorization baseline | backlog | #4 | — | — | 1.3 | ❌ No (1.3 not merged) |
| 1.5   | 1    | First-login profile completion | backlog | #5 | — | — | 1.3, 1.4 | ❌ No (1.3, 1.4 not merged) |
| 1.6   | 1    | Email & background-job infrastructure | backlog | #6 | — | — | 1.1 | ✅ Yes |
| 2.1   | 2    | Room inventory management (admin) | backlog | #7 | — | — | epic 1 complete | ❌ No (epic 1 not complete) |
| 2.2   | 2    | Room time-slot blocking (admin) | backlog | #8 | — | — | 2.1 | ❌ No (epic 1 not complete) |
| 2.3   | 2    | Room calendar — week scheduler | backlog | #9 | — | — | 2.1 | ❌ No (epic 1 not complete) |
| 2.4   | 2    | Create a booking with atomic conflict detection | backlog | #10 | — | — | 2.3, 1.6 | ❌ No (epic 1 not complete) |
| 2.5   | 2    | Edit, duplicate & cancel a booking | backlog | #11 | — | — | 2.4 | ❌ No (epic 1 not complete) |
| 2.6   | 2    | Room deactivation cascade | backlog | #12 | — | — | 2.1, 1.6 | ❌ No (epic 1 not complete) |
| 3.1   | 3    | Registration settings & close lifecycle | backlog | #13 | — | — | epic 2 complete | ❌ No (epic 2 not complete) |
| 3.2   | 3    | External registration (public token page) | backlog | #14 | — | — | 3.1 | ❌ No (epic 2 not complete) |
| 3.3   | 3    | External self-cancel & confirmation resend | backlog | #15 | — | — | 3.2 | ❌ No (epic 2 not complete) |
| 3.4   | 3    | Internal in-app registration | backlog | #16 | — | — | 3.1, 1.5 | ❌ No (epic 2 not complete) |
| 3.5   | 3    | Meal-type aggregation | backlog | #17 | — | — | 3.2, 3.4 | ❌ No (epic 2 not complete) |
| 3.6   | 3    | Registrant list & status | backlog | #18 | — | — | 3.2, 3.4 | ❌ No (epic 2 not complete) |
| 3.7   | 3    | Sign-in sheet PDF & event QR code | backlog | #19 | — | — | 3.6 | ❌ No (epic 2 not complete) |
| 3.8   | 3    | One-day-before reminder | backlog | #20 | — | — | 3.1, 1.6 | ❌ No (epic 2 not complete) |
| 3.9   | 3    | Organizer dashboard | backlog | #21 | — | — | 3.6, 3.7 | ❌ No (epic 2 not complete) |
| 4.1   | 4    | Utilization heatmap | backlog | #22 | — | — | epic 3 complete | ❌ No (epic 3 not complete) |
| 4.2   | 4    | Bulk calendar (all rooms) | backlog | #23 | — | — | epic 3 complete | ❌ No (epic 3 not complete) |
| 4.3   | 4    | CSV export of booking & registrant data | backlog | #24 | — | — | epic 3 complete | ❌ No (epic 3 not complete) |
| 4.4   | 4    | Audit log | backlog | #25 | — | — | epic 3 complete | ❌ No (epic 3 not complete) |
| 4.5   | 4    | SMTP settings configuration | backlog | #26 | — | — | epic 3 complete | ❌ No (epic 3 not complete) |
| 4.6   | 4    | Admin role assignment | backlog | #27 | — | — | 4.4 | ❌ No (epic 3 not complete) |

## Dependency Chains

- **1.2** depends on: 1.1
- **1.3** depends on: 1.1
- **1.4** depends on: 1.3
- **1.5** depends on: 1.3, 1.4
- **1.6** depends on: 1.1
- **2.1** depends on: epic 1 fully merged
- **2.2** depends on: 2.1
- **2.3** depends on: 2.1
- **2.4** depends on: 2.3, 1.6
- **2.5** depends on: 2.4
- **2.6** depends on: 2.1, 1.6
- **3.1** depends on: epic 2 fully merged
- **3.2** depends on: 3.1
- **3.3** depends on: 3.2
- **3.4** depends on: 3.1, 1.5
- **3.5** depends on: 3.2, 3.4
- **3.6** depends on: 3.2, 3.4
- **3.7** depends on: 3.6
- **3.8** depends on: 3.1, 1.6
- **3.9** depends on: 3.6, 3.7
- **4.1** depends on: epic 3 fully merged
- **4.2** depends on: epic 3 fully merged
- **4.3** depends on: epic 3 fully merged
- **4.4** depends on: epic 3 fully merged
- **4.5** depends on: epic 3 fully merged
- **4.6** depends on: 4.4

## Notes

**Parallelization opportunities within each epic:**

- **Epic 1:** After 1.1 merges, stories 1.2, 1.3, and 1.6 can run in parallel. Story 1.4 unblocks after 1.3; story 1.5 unblocks after both 1.3 and 1.4.
- **Epic 2:** After 2.1 merges, stories 2.2, 2.3, and 2.6 can run in parallel. Story 2.4 needs 2.3 (and 1.6 from E1). Story 2.5 follows 2.4.
- **Epic 3:** After 3.1 merges, stories 3.2, 3.4, and 3.8 can run in parallel. Stories 3.5 and 3.6 unblock after both 3.2 and 3.4. Story 3.3 follows 3.2. Story 3.7 follows 3.6. Story 3.9 follows 3.6 and 3.7.
- **Epic 4:** After epic 3 fully merges, stories 4.1–4.5 can run in parallel. Story 4.6 needs 4.4.

**Bottlenecks:** Story 1.1 is the single serial gate for the entire project. Story 2.1 gates all of Epic 2. Story 3.1 gates all of Epic 3. Epic sequencing is strict: E1 → E2 → E3 → E4.

**Current status:** PR #28 (story 1.1) merged 2026-06-19. Stories 1.2, 1.3, and 1.6 are now immediately available to work in parallel. Story 1.4 unblocks once 1.3 merges; story 1.5 unblocks once both 1.3 and 1.4 merge.
