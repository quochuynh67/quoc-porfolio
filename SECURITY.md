# Security policy

Flutter Web bundles are public. Only public configuration such as a Supabase
URL and anon/publishable key may be passed with `--dart-define`.

Never place service-role keys, admin passwords, database credentials, provider
API keys, signing keys, or unrestricted tokens in Dart, `web/`, assets, env
files committed to Git, or Flutter build arguments.

Privileged operations belong in an authenticated backend or Edge Function.
Every public Supabase table must use reviewed row-level security policies and
least-privilege grants.

Copy `.env.example` to an ignored local file for development. Production
secrets must come from the deployment platform's secret manager.

If a secret is committed, rotate it immediately. Removing it in a later commit
does not remove it from Git history.
