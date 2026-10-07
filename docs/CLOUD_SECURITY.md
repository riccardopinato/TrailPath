# TrailPath Cloud Security Boundary

TrailPath Cloud Sync is optional and local-first. This document defines what the
application enforces and what remains a production-environment responsibility.

## Enforced in the application/repository

- Cloud Sync is disabled unless both `SUPABASE_URL` and
  `SUPABASE_PUBLISHABLE_KEY` are supplied at runtime.
- Only the Supabase publishable client credential is used in the app.
- No service-role or database secret is embedded in source or release artifacts.
- Google identity is exchanged for an authenticated Supabase user session.
- Sync rows are scoped by `user_id`.
- The reference schema enables Row Level Security and grants table access only
  to the authenticated role.
- RLS policies require `auth.uid() = user_id` for select/insert/update/delete.
- Network transport uses Supabase HTTPS/TLS.
- Planning, recording and navigation never require cloud availability.
- Sign-out never deletes local routes, activities, preferences or collections.

## Provider/deployment gate before production enablement

The selected production Supabase project must be reviewed for:

- provider-managed encryption at rest;
- database backup/encryption policy;
- retention and deletion policy;
- regional/data-residency requirements;
- log/observability retention;
- incident-response and credential-rotation procedure.

These are deployment controls, not properties that the mobile client can prove
or implement by itself.

## Explicit non-claims

TrailPath v1.5 does **not** claim client-side/end-to-end encryption of cloud
payloads. Route and activity payloads are protected in transit by TLS and at
rest according to the configured Supabase project/provider policy.

Production Cloud Sync remains disabled until the deployment review above is
accepted.
