#!/usr/bin/env bash

set -euo pipefail

declare -A SERVICE_MAP=(
  [1]="mongo"
  [2]="postgres"
  [3]="redis"
  [4]="neo4j"
)

print_services() {
  echo "Select services to stop:"
  echo "1. mongo"
  echo "2. postgres"
  echo "3. redis"
  echo "4. neo4j"
}

print_error() {
  echo "$1" >&2
}

ensure_docker_access() {
  if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not accessible."
    print_error "Run: sudo usermod -aG docker \$USER && newgrp docker"
    exit 1
  fi
}

trim_whitespace() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

parse_selection() {
  local raw_input="$1"
  local -n selected_ref="$2"
  local -A seen=()
  local token
  local service

  IFS=',' read -r -a tokens <<< "$raw_input"

  for token in "${tokens[@]}"; do
    token="$(trim_whitespace "$token")"

    if [[ -z "$token" ]]; then
      continue
    fi

    service="${SERVICE_MAP[$token]:-}"
    if [[ -z "$service" ]]; then
      print_error "Ignoring invalid selection: $token"
      continue
    fi

    if [[ -z "${seen[$service]:-}" ]]; then
      selected_ref+=("$service")
      seen[$service]=1
    fi
  done
}

stop_services() {
  local services=("$@")

  if ! docker compose stop "${services[@]}"; then
    print_error "Failed to stop the selected services."
    exit 1
  fi
}

print_stop_summary() {
  local services=("$@")
  local service

  echo
  echo "Stopped services:"
  for service in "${services[@]}"; do
    echo "- $service"
  done
}

main() {
  local input
  local -a selected_services=()

  ensure_docker_access
  print_services
  read -r -p "Enter service numbers (comma-separated): " input

  if [[ -z "$(trim_whitespace "$input")" ]]; then
    print_error "No services selected. Please provide one or more numbers, such as: 1,2"
    exit 1
  fi

  parse_selection "$input" selected_services

  if [[ "${#selected_services[@]}" -eq 0 ]]; then
    print_error "No valid services selected. Choose from: 1, 2, 3, 4"
    exit 1
  fi

  echo "Stopping services: ${selected_services[*]}"
  stop_services "${selected_services[@]}"
  print_stop_summary "${selected_services[@]}"
}

main "$@"
