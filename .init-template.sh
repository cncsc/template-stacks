#!/usr/bin/env bash

# This script initializes a repository deployed from this template.
# Skip prompts by setting environment variables SHORT_DESCRIPTION and/or LONG_DESCRIPTION
# If LONG_DESCRIPTION is not set then it will default to the value in SHORT_DESCRIPTION

set -e

SED_COMMAND="sed -i"
if [[ $OSTYPE == "darwin"* ]]; then
  # macOS doesn't use GNU sed and has a slightly different syntax
  SED_COMMAND="sed -i '' -E"
fi

function update_package_json() {
  local -r github_org="$1"
  local -r repository_name="$2"
  local -r description="$3"

  eval "$SED_COMMAND 's|cncsc/template-stacks|$github_org/$repository_name|g' package.json"
  eval "$SED_COMMAND 's/{{module_description}}/$description/g' package.json"
  rm package-lock.json
  npm install
}

function update_github_env_file() {
  local -r github_org="$1"
  eval "$SED_COMMAND 's/cncsc/$github_org/g' ./github/env.yaml"
}

function update_remote_state_config() {
  local tfc_org
  echo 'Enter the name of the Terraform Cloud org (e.g. "cncsc-dev"):'
  read -r tfc_org
  eval "$SED_COMMAND 's/cncsc/$tfc_org/g' .remote-state-config.yaml"
}

function main() {
  local -r repository_name=$(git remote -v | grep push | sed -e 's|.*/||' | sed -e 's/\.git.*//')
  local description

  echo "Initializing repository from template..."
  echo "Using repository name as the module name ($repository_name)..."

  until test -n "${description:=${SHORT_DESCRIPTION}}"; do
    echo "Enter a short description for the repository (package.json):"
    echo '  (e.g. "Monorepo for declaratively managing the infrastructure and configuration of <group>.")'
    read -r description
  done

  repo="$(git config --get remote.origin.url | sed 's/.*://')"
  github_org="$(dirname "$repo")"

  update_package_json "$github_org" "$repository_name" "$description"
  update_github_env_file "$github_org"
  update_remote_state_config

  rm -rf .init-template.sh

  echo ""
  echo "Initialization complete. Committing to source control..."
  pre-commit install
  git add -A
  git commit -m "Initialize repository from template"
  git push -u origin main
}

main "$@"
