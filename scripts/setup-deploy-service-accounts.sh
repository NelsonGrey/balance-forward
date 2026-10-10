#!/usr/bin/env bash
# One-time IAM setup for the Firebase backend deploy in
# .github/workflows/firebase-deploy-local.yml.
#
# Creates a github-actions-deploy service account in each project and lets
# GitHub Actions impersonate it through the EXISTING Workload Identity pool
# (hosted in nelsongrey-sprout-dev, shared with the github-actions-hosting
# accounts). No keys are created -- the org blocks SA key creation.
#
# Each account is only impersonable from one branch:
#   dev -> develop, staging -> staging, prod -> main
#
# Usage (needs Owner / IAM admin on the three projects):
#   scripts/setup-deploy-service-accounts.sh [dev|staging|prod ...]
# With no arguments, all three are configured. Safe to re-run.
#
# Set WITH_FUNCTIONS=1 to also grant the roles needed to deploy Cloud
# Functions (only needed once FUNCTIONS_REPO_PAT is configured).
set -euo pipefail

POOL_PROJECT_NUMBER=968230602171
POOL="projects/${POOL_PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-actions"
SA_NAME=github-actions-deploy

project_for() { case "$1" in dev) echo nelsongrey-sprout-dev;; staging) echo nelsongrey-sprout-staging;; prod) echo nelsongrey-sprout-prod;; *) echo "unknown env: $1" >&2; exit 1;; esac; }
branch_for()  { case "$1" in dev) echo develop;; staging) echo staging;; prod) echo main;; esac; }

RULES_ROLES=(
  roles/firebaserules.admin   # deploy firestore.rules
  roles/datastore.indexAdmin  # deploy firestore.indexes.json
  roles/firebase.viewer       # firebase-tools project lookups
  roles/serviceusage.serviceUsageConsumer
)
FUNCTIONS_ROLES=(
  roles/cloudfunctions.admin
  roles/run.admin
  roles/artifactregistry.writer
  roles/cloudbuild.builds.editor
  roles/iam.serviceAccountUser
)

envs=("$@"); [ ${#envs[@]} -eq 0 ] && envs=(dev staging prod)

for env in "${envs[@]}"; do
  project=$(project_for "$env"); branch=$(branch_for "$env")
  sa="${SA_NAME}@${project}.iam.gserviceaccount.com"
  echo "== ${env}: ${project} (branch ${branch})"

  gcloud iam service-accounts describe "$sa" --project "$project" >/dev/null 2>&1 \
    || gcloud iam service-accounts create "$SA_NAME" --project "$project" \
         --display-name "GitHub Actions backend deploy"

  roles=("${RULES_ROLES[@]}")
  [ "${WITH_FUNCTIONS:-0}" = "1" ] && roles+=("${FUNCTIONS_ROLES[@]}")
  for role in "${roles[@]}"; do
    gcloud projects add-iam-policy-binding "$project" \
      --member "serviceAccount:${sa}" --role "${role%% *}" --condition=None >/dev/null
  done

  gcloud iam service-accounts add-iam-policy-binding "$sa" --project "$project" \
    --role roles/iam.workloadIdentityUser \
    --member "principalSet://iam.googleapis.com/${POOL}/attribute.ref/refs/heads/${branch}" >/dev/null
  echo "   ok: ${sa}"
done
