# Deferred Work

## Deferred from: code review of story-1.1-project-initialization-platform-scaffold (2026-06-18)

- deploy.yml `DATABASE_URL` secret vs discrete `*_DATABASE_PASSWORD` ENV inconsistency [config/deploy.yml]: deploy.yml lists `DATABASE_URL` as a required secret while `config/database.yml` production blocks expect a discrete password ENV; the separate cache/queue/cable databases would be under-specified if only `DATABASE_URL` is provided. Also none of `OIDC_CLIENT_SECRET`/`SMTP_PASSWORD` are defined in `.kamal/secrets` yet. Deferred because production secret wiring (OIDC, SMTP, DB) is explicitly scoped to later stories (1.3 / 1.6) per the story Dev Notes; reconcile when those secrets are wired.

## Deferred from: code review of story-1.2-core-design-system-viewcomponent-ui-library (2026-06-19)

- FormFieldComponent hardcoded to `text_field` [app/components/form_field_component.html.erb]: the form-builder branch always calls `@form.text_field`, so the field cannot render email/password/number/textarea inputs. Acceptable MVP narrowing for this story; generalize (accept an `as:`/`type:` kwarg) when the first non-text field is needed.
- ModalComponent `variant:`/danger stored but unused [app/components/modal_component.rb]: the danger variant is accepted but the template never renders distinct danger styling. Wire it up alongside the destructive-confirm (room deactivation) use in Story 2.6.
- green-500 (#40916C) on white contrast ~3.7:1, below WCAG AA 4.5:1 for body text [app/assets/tailwind/daisyui-theme.mjs]: DESIGN.md §5 flagged this for verification. Reserve green-500 for large text / borders only, or darken toward green-700 in a dedicated theme/contrast pass.
- daisyUI radius tokens diverge from DESIGN.md scale [app/assets/tailwind/daisyui-theme.mjs]: `--radius-field`/`--radius-selector`/`--radius-box` do not cleanly map to the 6/10/16 sm/md/lg scale, so daisyUI `btn`/`badge`/`input` radii may not match Task 1 intent. Reconcile token-to-utility mapping in a design-token cleanup.
