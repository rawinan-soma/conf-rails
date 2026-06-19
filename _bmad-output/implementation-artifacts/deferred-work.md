# Deferred Work

## Deferred from: code review of story-1.1-project-initialization-platform-scaffold (2026-06-18)

- deploy.yml `DATABASE_URL` secret vs discrete `*_DATABASE_PASSWORD` ENV inconsistency [config/deploy.yml]: deploy.yml lists `DATABASE_URL` as a required secret while `config/database.yml` production blocks expect a discrete password ENV; the separate cache/queue/cable databases would be under-specified if only `DATABASE_URL` is provided. Also none of `OIDC_CLIENT_SECRET`/`SMTP_PASSWORD` are defined in `.kamal/secrets` yet. Deferred because production secret wiring (OIDC, SMTP, DB) is explicitly scoped to later stories (1.3 / 1.6) per the story Dev Notes; reconcile when those secrets are wired.
