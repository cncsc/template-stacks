#!/usr/bin/env bash

function check_path() {
  local -r path="$1"
  local -r max_depth="$2"
  local i="$3"
  local -r test_path="$path/.remote-state-config.yaml"

  if [ -f "$test_path" ]; then
    collapsed_path="$(readlink -f "$test_path")"
    echo "- Remote state config found at $collapsed_path" 1>&2
    echo "" 1>&2
    echo "$collapsed_path"
    exit 0
  else
    if ((i > max_depth)); then
      exit 1
    fi
    ((i += 1))
    check_path "$path/.." "$max_depth" "$i"
  fi
}

function main() {
  local -r path="$1"
  local -r separators="${path//[!\/]/}"
  local -r depth="${#separators}"

  echo "" 1>&2
  echo -e '\033[1mLocating Terraform remote state config...\033[0m' 1>&2

  check_path "$PWD" "$depth" 0
}

main "$@"
