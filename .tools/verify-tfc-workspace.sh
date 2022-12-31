#!/usr/bin/env bash

# By convention, we only use Terraform Cloud for remote state storage with execution handled by GitHub actions.
# This allows us to utilize the monorepo pattern with Terragrunt facilitating modularity.
# This script handles the dynamic Terraform Cloud workspace management for use with Terragrunt.

function get_workspace_execution_mode() {
  local -r tfc_api_token="$1"
  local -r organization="$2"
  local -r workspace="$3"

  # When calling GET on a specific workspace, if it doesn't already exist, it will be automatically created.
  # By default it will be created with the `remote` execution mode.
  # We will the change it to `local` execution mode the same as if it was already existing and misconfigured.

  curl -sSL -X GET \
    -H "authorization: Bearer $tfc_api_token" \
    -H "content-type: application/vnd.api+json" \
    "https://app.terraform.io/api/v2/organizations/$organization/workspaces/$workspace" |
    jq -r '.data.attributes["execution-mode"]'
}

function set_execution_mode_local() {
  local -r tfc_api_token="$1"
  local -r organization="$2"
  local -r workspace="$3"
  local -r execution_mode="$4"

  curl -sSL -X PATCH \
    -H "authorization: Bearer $tfc_api_token" \
    -H "content-type: application/vnd.api+json" \
    "https://app.terraform.io/api/v2/organizations/$organization/workspaces/$workspace" \
    --data '{"data":{"type":"workspaces","attributes":{"execution-mode":"local"}}}' >/dev/null
}

function validate_workspace() {
  local -r organization="$1"
  local -r workspace="$2"
  echo "- Current organization is $organization"
  echo "- Current workspace is $workspace"

  if test -f "$HOME/.terraform.d/credentials.tfrc.json"; then
    tfc_api_token=$(jq -r '.credentials["app.terraform.io"].token' <"$HOME/.terraform.d/credentials.tfrc.json")
  elif [ -z "$TFC_API_TOKEN" ]; then
    tfc_api_token="$TFC_API_TOKEN"
  else
    echo ""
    echo -e "\033[31mCould not find a Terraform Cloud API token to use.\033[39m" >&2

    # shfmt removes the unnecessary escapes that shellcheck requires explicitly – disabling these checks.
    # shellcheck disable=SC2016
    echo 'Run `terraform login` to generate and store your user token; or'
    # shellcheck disable=SC2016
    echo 'Set the token on your environment as $TFC_API_TOKEN'

    echo ""
    exit 1
  fi

  execution_mode=$(get_workspace_execution_mode "$tfc_api_token" "$organization" "$workspace")

  echo "- Current execution mode is $execution_mode"

  if [ "$execution_mode" != "local" ]; then
    echo "- Updating workspace execution mode to local..."
    set_execution_mode_local "$tfc_api_token" "$organization" "$workspace"
    echo "- Workspace execution mode updated to to local."
  fi

  echo ""
}

function main() {
  echo ""
  echo -e '\033[1mValidating Terraform Cloud workspace execution mode...\033[0m'
  validate_workspace "$@"
}

main "$@"
