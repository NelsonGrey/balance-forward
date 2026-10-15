#!/usr/bin/env bash
# Pushes each environment's Firebase web config into GitHub Actions secrets
# (read from the Firebase CLI, so nothing is hardcoded here). Safe to re-run.
# Allowlist secrets (VITE_ALLOWED_EMAILS_*) are not touched.
# Usage: scripts/set-github-firebase-secrets.sh [repo]   (default NelsonGrey/balance-forward)
set -euo pipefail
R="${1:-NelsonGrey/balance-forward}"

set_env() { # project  secret-prefix  secret-suffix
  local project=$1 pre=$2 suf=$3 app cfg
  app=$(firebase apps:list WEB --project "$project" --non-interactive | grep -o '1:[0-9]*:web:[0-9a-f]*' | head -1)
  cfg=$(firebase apps:sdkconfig WEB "$app" --project "$project" --non-interactive)
  g() { echo "$cfg" | grep "\"$1\"" | sed 's/.*: "\(.*\)".*/\1/'; }
  gh secret set "${pre}VITE_FIREBASE_API_KEY${suf}"             -R "$R" -b "$(g apiKey)"
  gh secret set "${pre}VITE_FIREBASE_APP_ID${suf}"              -R "$R" -b "$(g appId)"
  gh secret set "${pre}VITE_FIREBASE_AUTH_DOMAIN${suf}"         -R "$R" -b "$(g authDomain)"
  gh secret set "${pre}VITE_FIREBASE_MESSAGING_SENDER_ID${suf}" -R "$R" -b "$(g messagingSenderId)"
  gh secret set "${pre}VITE_FIREBASE_PROJECT_ID${suf}"          -R "$R" -b "$(g projectId)"
  gh secret set "${pre}VITE_FIREBASE_STORAGE_BUCKET${suf}"      -R "$R" -b "$(g storageBucket)"
}

set_env balance-forward-dev     DEV_ ""
set_env balance-forward-staging ""   _STAGING
gh secret set FIREBASE_PROJECT_DEV     -R "$R" -b balance-forward-dev
gh secret set FIREBASE_PROJECT_STAGING -R "$R" -b balance-forward-staging
gh secret set FIREBASE_PROJECT_PROD    -R "$R" -b balance-forward-prod
echo "Done. Production web secrets are not set yet (no prod web app/deploy secrets existed before either)."
