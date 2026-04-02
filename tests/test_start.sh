#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
START_SCRIPT="${REPO_ROOT}/start.sh"
STOP_SCRIPT="${REPO_ROOT}/stop.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

fail() {
  echo "TEST FAILED: $1" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"

  if [[ "${haystack}" != *"${needle}"* ]]; then
    fail "Expected output to contain: ${needle}"
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"

  if [[ "${haystack}" == *"${needle}"* ]]; then
    fail "Did not expect output to contain: ${needle}"
  fi
}

assert_exit_code() {
  local actual="$1"
  local expected="$2"

  if [[ "${actual}" -ne "${expected}" ]]; then
    fail "Expected exit code ${expected}, got ${actual}"
  fi
}

run_script() {
  local script_path="$1"
  local docker_behavior="$2"
  local input_value="$3"
  local stdout_file="${TMP_DIR}/stdout.txt"
  local stderr_file="${TMP_DIR}/stderr.txt"
  local status_file="${TMP_DIR}/status.txt"
  local mock_bin="${TMP_DIR}/bin"

  rm -f \
    "${stdout_file}" \
    "${stderr_file}" \
    "${status_file}" \
    "${TMP_DIR}/docker-compose-args.txt" \
    "${TMP_DIR}/docker-compose-stop-args.txt"

  mkdir -p "${mock_bin}"

  cat > "${mock_bin}/docker" <<EOF
#!/usr/bin/env bash
set -euo pipefail
if [[ "\${1:-}" == "info" ]]; then
  if [[ "${docker_behavior}" == "deny" ]]; then
    exit 1
  fi
  exit 0
fi

if [[ "\${1:-}" == "compose" && "\${2:-}" == "up" && "\${3:-}" == "-d" ]]; then
  printf '%s\n' "\$@" > "${TMP_DIR}/docker-compose-args.txt"
  exit 0
fi

if [[ "\${1:-}" == "compose" && "\${2:-}" == "stop" ]]; then
  printf '%s\n' "\$@" > "${TMP_DIR}/docker-compose-stop-args.txt"
  exit 0
fi

echo "Unexpected docker invocation: \$*" >&2
exit 1
EOF

  chmod +x "${mock_bin}/docker"

  (
    cd "${REPO_ROOT}"
    printf '%s\n' "${input_value}" | PATH="${mock_bin}:$PATH" bash "${script_path}"
  ) >"${stdout_file}" 2>"${stderr_file}" || echo "$?" > "${status_file}"

  if [[ ! -f "${status_file}" ]]; then
    echo "0" > "${status_file}"
  fi

  RUN_STDOUT="$(cat "${stdout_file}")"
  RUN_STDERR="$(cat "${stderr_file}")"
  RUN_STATUS="$(cat "${status_file}")"
}

test_docker_access_error() {
  run_script "${START_SCRIPT}" "deny" "1"
  assert_exit_code "${RUN_STATUS}" 1
  assert_contains "${RUN_STDERR}" "Docker is not accessible."
  assert_contains "${RUN_STDERR}" "Run: sudo usermod -aG docker \$USER && newgrp docker"
}

test_empty_input() {
  run_script "${START_SCRIPT}" "allow" ""
  assert_exit_code "${RUN_STATUS}" 1
  assert_contains "${RUN_STDERR}" "No services selected. Please provide one or more numbers, such as: 1,2"
}

test_invalid_only_input() {
  run_script "${START_SCRIPT}" "allow" "9,10"
  assert_exit_code "${RUN_STATUS}" 1
  assert_contains "${RUN_STDERR}" "Ignoring invalid selection: 9"
  assert_contains "${RUN_STDERR}" "Ignoring invalid selection: 10"
  assert_contains "${RUN_STDERR}" "No valid services selected. Choose from: 1, 2, 3, 4"
}

test_mixed_valid_invalid_and_duplicate_input() {
  run_script "${START_SCRIPT}" "allow" "1, 3, 9, 3, 4"
  assert_exit_code "${RUN_STATUS}" 0
  assert_contains "${RUN_STDOUT}" "Starting services: mongo redis neo4j"
  assert_contains "${RUN_STDOUT}" "mongo: mongodb://localhost:27017"
  assert_contains "${RUN_STDOUT}" "redis: redis://localhost:6379"
  assert_contains "${RUN_STDOUT}" "neo4j: neo4j://localhost:7687"
  assert_contains "${RUN_STDERR}" "Ignoring invalid selection: 9"

  local docker_args
  docker_args="$(cat "${TMP_DIR}/docker-compose-args.txt")"
  assert_contains "${docker_args}" "compose"
  assert_contains "${docker_args}" "mongo"
  assert_contains "${docker_args}" "redis"
  assert_contains "${docker_args}" "neo4j"
  assert_not_contains "${docker_args}" "9"
}

test_stop_script_mixed_valid_invalid_and_duplicate_input() {
  run_script "${STOP_SCRIPT}" "allow" "2, 4, 99, 4"
  assert_exit_code "${RUN_STATUS}" 0
  assert_contains "${RUN_STDOUT}" "Stopping services: postgres neo4j"
  assert_contains "${RUN_STDOUT}" "Stopped services:"
  assert_contains "${RUN_STDOUT}" "- postgres"
  assert_contains "${RUN_STDOUT}" "- neo4j"
  assert_contains "${RUN_STDERR}" "Ignoring invalid selection: 99"

  local docker_args
  docker_args="$(cat "${TMP_DIR}/docker-compose-stop-args.txt")"
  assert_contains "${docker_args}" "compose"
  assert_contains "${docker_args}" "stop"
  assert_contains "${docker_args}" "postgres"
  assert_contains "${docker_args}" "neo4j"
  assert_not_contains "${docker_args}" "99"
}

main() {
  test_docker_access_error
  test_empty_input
  test_invalid_only_input
  test_mixed_valid_invalid_and_duplicate_input
  test_stop_script_mixed_valid_invalid_and_duplicate_input
  echo "All tests passed."
}

main "$@"
