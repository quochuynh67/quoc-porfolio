#!/usr/bin/env bash
set -euo pipefail

tracked_files=$(git ls-files -co --exclude-standard)

if printf '%s\n' "$tracked_files" | grep -E '(^|/)(\.env|supabase_keys\.json|google-services\.json|GoogleService-Info\.plist)$' >/dev/null; then
  echo 'Blocked sensitive configuration file is tracked or staged.' >&2
  exit 1
fi

if git grep -IEn '(SUPABASE_SERVICE_ROLE_KEY|ADMIN_DELETE_PASSWORD|OPENAI_API_KEY)[[:space:]]*=[[:space:]]*[^[:space:]#]+' -- ':!*.example' >/dev/null; then
  echo 'Possible privileged credential found in tracked source.' >&2
  exit 1
fi

if git grep -IEn -- '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----' >/dev/null; then
  echo 'Private key material found in tracked source.' >&2
  exit 1
fi

echo 'Secret guard passed.'
