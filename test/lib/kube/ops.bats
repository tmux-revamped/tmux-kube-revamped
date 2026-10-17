#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _KUBE_REVAMPED_OPS_LOADED _KUBE_REVAMPED_LOADED _KUBE_REVAMPED_CLUSTER_LOADED
  export CACHE_PREFIX="kube_revamped"
  source "${BATS_TEST_DIRNAME}/../../../src/lib/kube/ops.sh"
  SELF="/plugin/src/kube.sh"
  _kube_config_text() {
    cat <<'YAML'
contexts:
- context:
    namespace: web
  name: prod-ctx
- context:
    namespace: dev
  name: dev-ctx
current-context: prod-ctx
YAML
  }
  _kube_tmux_version_string() { echo "tmux 3.3"; }
}

teardown() {
  cleanup_test_environment
}

run_menu_command() {
  local command="${1}" hash="#" hashes="##" inner
  command="${command//"${hashes}"/${hash}}"
  eval "inner=${command#run-shell }"
  inner="${inner//"${hashes}"/${hash}}"
  /bin/sh -c "${inner}"
}

make_arg_printer() {
  mkdir -p "$(dirname "${1}")"
  printf '#!/bin/sh\nfor a in "$@"; do printf "[%%s]\\n" "$a"; done\n' > "${1}"
  chmod +x "${1}"
}

@test "ops.sh - functions are defined" {
  function_exists kube_menu_context
  function_exists kube_menu_namespace
  function_exists kube_popup
  function_exists kube_apply_keys
  function_exists kube_doctor
}

@test "ops.sh - kube_parse_version handles plain, suffixed, and next builds" {
  [[ "$(kube_parse_version 'tmux 3.3')" == "3.3" ]]
  [[ "$(kube_parse_version 'tmux 3.4a')" == "3.4" ]]
  [[ "$(kube_parse_version 'tmux next-3.6')" == "3.6" ]]
}

@test "ops.sh - kube_version_ge accepts a newer version" {
  # Arrange
  local have="3.3" want="3.2"

  # Act
  run kube_version_ge "${have}" "${want}"

  # Assert
  [ "${status}" -eq 0 ]
}

@test "ops.sh - kube_version_ge accepts an equal version" {
  # Arrange
  local have="3.2" want="3.2"

  # Act
  run kube_version_ge "${have}" "${want}"

  # Assert
  [ "${status}" -eq 0 ]
}

@test "ops.sh - kube_version_ge rejects an older version" {
  # Arrange
  local have="3.1" want="3.2"

  # Act
  run kube_version_ge "${have}" "${want}"

  # Assert
  [ "${status}" -ne 0 ]
}

@test "ops.sh - kube_version_ge rejects an empty version" {
  # Arrange
  local have="" want="3.2"

  # Act
  run kube_version_ge "${have}" "${want}"

  # Assert
  [ "${status}" -ne 0 ]
}

@test "ops.sh - kube_tmux_version uses the seam" {
  [[ "$(kube_tmux_version)" == "3.3" ]]
}

@test "ops.sh - version-string seam is callable" {
  run _kube_tmux_version_string
  true
}

@test "ops.sh - _tmux seam dispatches to tmux" {
  set_tmux_option "@probe" "x"
  run _tmux show-option -gqv "@probe"
  [[ "${output}" == "x" ]]
}

@test "ops.sh - kube_menu_context builds a context menu" {
  # Arrange
  _tmux() { printf '%s\n' "$*"; }

  # Act
  run kube_menu_context "${SELF}"

  # Assert
  [[ "${output}" == *"display-menu -T Context"* ]] || false
  [[ "${output}" == *"prod-ctx"* ]] || false
  [[ "${output}" == *"run-shell '${SELF} use-context prod-ctx'"* ]] || false
  [[ "${output}" == *"run-shell '${SELF} use-context dev-ctx'"* ]]
}

@test "ops.sh - kube_menu_context emits nothing with no contexts" {
  _kube_config_text() { echo "apiVersion: v1"; }
  _tmux() { printf '%s\n' "$*"; }
  run kube_menu_context "${SELF}"
  [[ -z "${output}" ]]
}

@test "ops.sh - kube_menu_namespace builds a namespace menu" {
  # Arrange
  _kubectl() { printf 'namespace/default\nnamespace/web\n\n'; }
  _tmux() { printf '%s\n' "$*"; }

  # Act
  run kube_menu_namespace "${SELF}"

  # Assert
  [[ "${output}" == *"display-menu -T Namespace"* ]] || false
  [[ "${output}" == *"run-shell '${SELF} use-namespace default'"* ]] || false
  [[ "${output}" == *"run-shell '${SELF} use-namespace web'"* ]]
}

@test "ops.sh - kube_menu_namespace emits nothing with no namespaces" {
  _kubectl() { printf ''; }
  _tmux() { printf '%s\n' "$*"; }
  run kube_menu_namespace "${SELF}"
  [[ -z "${output}" ]]
}

@test "ops.sh - kube_popup opens k9s pinned to context and namespace" {
  set_tmux_option "@kube_revamped_value" "prod-ctx|web"
  _tmux() { printf '%s\n' "$*"; }
  run kube_popup
  [[ "${output}" == *"display-popup -E -w 80% -h 80%"* ]]
  [[ "${output}" == *"k9s --context prod-ctx --namespace web"* ]]
}

@test "ops.sh - kube_popup omits the namespace when there is none" {
  set_tmux_option "@kube_revamped_value" "prod-ctx"
  _tmux() { printf '%s\n' "$*"; }
  run kube_popup
  [[ "${output}" == *"k9s --context prod-ctx"* ]]
  [[ "${output}" != *"--namespace"* ]]
}

@test "ops.sh - kube_popup is a no-op below tmux 3.2" {
  _kube_tmux_version_string() { echo "tmux 3.1"; }
  set_tmux_option "@kube_revamped_value" "prod-ctx|web"
  _tmux() { printf '%s\n' "$*"; }
  run kube_popup
  [[ -z "${output}" ]]
}

@test "ops.sh - kube_popup is a no-op with no context" {
  _tmux() { printf '%s\n' "$*"; }
  run kube_popup
  [[ -z "${output}" ]]
}

@test "ops.sh - kube_popup honors a custom command and size" {
  set_tmux_option "@kube_revamped_value" "prod-ctx|web"
  set_tmux_option "@kube_revamped_popup_command" "k9s -A"
  set_tmux_option "@kube_revamped_popup_width" "90%"
  set_tmux_option "@kube_revamped_popup_height" "70%"
  _tmux() { printf '%s\n' "$*"; }
  run kube_popup
  [[ "${output}" == *"display-popup -E -w 90% -h 70%"* ]]
  [[ "${output}" == *"k9s -A --context prod-ctx --namespace web"* ]]
}

@test "ops.sh - kube_apply_keys binds nothing by default" {
  _tmux() { printf '%s\n' "$*"; }
  run kube_apply_keys "${SELF}"
  [[ -z "${output}" ]]
}

@test "ops.sh - kube_apply_keys binds every configured key" {
  set_tmux_option "@kube_revamped_menu_context_key" "C-k"
  set_tmux_option "@kube_revamped_menu_namespace_key" "C-n"
  set_tmux_option "@kube_revamped_popup_key" "K"
  _tmux() { printf '%s\n' "$*"; }
  run kube_apply_keys "${SELF}"
  [[ "${output}" == *"bind-key C-k run-shell ${SELF} menu-context"* ]]
  [[ "${output}" == *"bind-key C-n run-shell ${SELF} menu-namespace"* ]]
  [[ "${output}" == *"bind-key K run-shell ${SELF} popup"* ]]
}

@test "ops.sh - kube_apply_keys binds only the keys that are set" {
  set_tmux_option "@kube_revamped_popup_key" "K"
  _tmux() { printf '%s\n' "$*"; }
  run kube_apply_keys "${SELF}"
  [[ "${output}" == *"bind-key K run-shell ${SELF} popup"* ]]
  [[ "${output}" != *"menu-context"* ]]
}

@test "ops.sh - kube_doctor reports missing tools and the current context" {
  has_command() { return 1; }
  local cfg="${TEST_TMPDIR}/cfg.yaml"
  printf 'contexts:\n- context:\n    namespace: web\n  name: prod-ctx\ncurrent-context: prod-ctx\n' > "${cfg}"
  _kube_config_files() { printf '%s\n' "${cfg}"; }
  run kube_doctor
  [[ "${output}" == *"kubectl: not found"* ]]
  [[ "${output}" == *"k9s: not found"* ]]
  [[ "${output}" == *"${cfg} (readable)"* ]]
  [[ "${output}" == *"current-context: prod-ctx"* ]]
}

@test "ops.sh - kube_doctor finds present tools and flags a dangling context" {
  has_command() { return 0; }
  _kube_config_files() { printf '%s\n' "/does/not/exist.yaml"; }
  _kube_config_text() { printf 'current-context: ghost\n'; }
  run kube_doctor
  [[ "${output}" == *"kubectl: found"* ]]
  [[ "${output}" == *"k9s: found"* ]]
  [[ "${output}" == *"(missing)"* ]]
  [[ "${output}" == *"DANGLING"* ]]
}

@test "ops.sh - kube_doctor reports no current context" {
  has_command() { return 1; }
  _kube_config_files() { printf '%s\n' "/x.yaml"; }
  _kube_config_text() { printf 'apiVersion: v1\n'; }
  run kube_doctor
  [[ "${output}" == *"current-context: (none)"* ]]
}

@test "ops.sh - kube_menu_context passes a hostile context name as one argument" {
  # Arrange
  local self="${TEST_TMPDIR}/plug in's #dir/kube.sh"
  make_arg_printer "${self}"
  _kube_config_text() {
    printf 'contexts:\n- context:\n    namespace: web\n  name: "it'"'"'s #1; $(touch x) q"\n'
  }
  _tmux() { printf '%s\n' "${@:4:1}" "${@:6:1}"; }

  # Act
  run kube_menu_context "${self}"

  # Assert
  [[ "${lines[0]}" == "it's ##1; \$(touch x) q" ]] || false
  run run_menu_command "${lines[1]}"
  [[ "${lines[0]}" == "[use-context]" ]] || false
  [[ "${lines[1]}" == "[it's #1; \$(touch x) q]" ]]
}

@test "ops.sh - kube_menu_namespace passes a namespace with a quote as one argument" {
  # Arrange
  local self="${TEST_TMPDIR}/plug in/kube.sh"
  make_arg_printer "${self}"
  _kubectl() { printf "namespace/team's #ns\n"; }
  _tmux() { printf '%s\n' "${@:4:1}" "${@:6:1}"; }

  # Act
  run kube_menu_namespace "${self}"

  # Assert
  [[ "${lines[0]}" == "team's ##ns" ]] || false
  run run_menu_command "${lines[1]}"
  [[ "${lines[0]}" == "[use-namespace]" ]] || false
  [[ "${lines[1]}" == "[team's #ns]" ]]
}

@test "ops.sh - kube_popup quotes the context and namespace for the shell" {
  # Arrange
  set_tmux_option "@kube_revamped_value" "my ctx;id|team ns"
  _tmux() { printf '%s\n' "${@: -1}"; }

  # Act
  run kube_popup

  # Assert
  [[ "${output}" == 'k9s --context my\ ctx\;id --namespace team\ ns' ]]
}

@test "ops.sh - kube_apply_keys quotes a plugin path with a space and a quote" {
  # Arrange
  set_tmux_option "@kube_revamped_popup_key" "K"
  _tmux() { printf '%s\n' "${@: -1}"; }

  # Act
  run kube_apply_keys "/plug in's/kube.sh"

  # Assert
  [[ "${output}" == "/plug\\ in\\'s/kube.sh popup" ]]
}
