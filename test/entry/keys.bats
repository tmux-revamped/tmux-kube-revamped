#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031,SC2154

# shellcheck source=test/tmux_helpers.bash
source "${BATS_TEST_DIRNAME}/../tmux_helpers.bash"

wait_for() {
  local delay
  for delay in 0.01 0.02 0.05 0.1 0.1 0.2 0.2 0.5 0.5 1 1 1 2 2; do
    "$@" && return 0
    sleep "${delay}"
  done
  "$@" && return 0
  command tmux -S "${HOST}" capture-pane -p -t host || :
  return 1
}

attached() {
  local clients
  clients=$(tmux list-clients -F x 2>/dev/null)
  [[ -n "${clients}" ]]
}

host_shows() {
  local screen
  screen=$(command tmux -S "${HOST}" capture-pane -p -t host)
  [[ "${screen}" == *"$1"* ]]
}

said() {
  local messages
  messages=$(tmux show-messages)
  [[ "${messages}" == *"$1"* ]]
}

asked() {
  grep -qxF -- "$1" "${BATS_TEST_TMPDIR}/kubectl.calls" 2>/dev/null
}

cached() {
  local value
  value=$(tmux show-option -gqv @kube_revamped_value)
  [[ "${value}" == "$1" ]]
}

kubeconfig() {
  mkdir -p "${HOME}/.kube"
  cat >"${HOME}/.kube/config" <<'KUBE'
apiVersion: v1
kind: Config
current-context: dev
contexts:
- name: dev
  context:
    cluster: dev-cluster
    namespace: web
    user: dev-user
- name: prod
  context:
    cluster: prod-cluster
    namespace: api
    user: prod-user
KUBE
}

setup() {
  unset BASH_ENV
  ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  STUBS="${BATS_TEST_TMPDIR}/stubs"
  export HOME="${BATS_TEST_TMPDIR}/home"
  unset KUBECONFIG
  mkdir -p "${HOME}" "${STUBS}"
  : >"${BATS_TEST_TMPDIR}/namespaces"
  printf '#!/bin/sh\nprintf "%%s\\n" "$*" >>"%s"\ncase "$*" in\n"get namespaces"*) cat "%s" ;;\n*) : ;;\nesac\n' "${BATS_TEST_TMPDIR}/kubectl.calls" "${BATS_TEST_TMPDIR}/namespaces" >"${STUBS}/kubectl"
  printf '#!/bin/sh\nprintf "%%s\\n" "k9s stand-in $*"\nread -r stand_in_wait\n' >"${STUBS}/k9s"
  chmod +x "${STUBS}/kubectl" "${STUBS}/k9s"
  PATH="${STUBS}:${PATH}"
  HOST="${TMUX_SOCKET}-host"
  setup_tmux_server
  tmux set-option -g default-command "env PS1='$ ' sh"
  tmux set-option -g @kube_revamped_menu_namespace_key F2
  tmux set-option -g @kube_revamped_popup_key F3
  command tmux -S "${HOST}" -f /dev/null new-session -d -s host -x 120 -y 40 \
    "env -u TMUX TERM=xterm-256color tmux -S '${TMUX_SOCKET}' attach-session -t test"
  wait_for attached
  tmux run-shell "'${ROOT}/kube-revamped.tmux'"
}

teardown() {
  command tmux -S "${HOST}" kill-server 2>/dev/null || :
  rm -f "${HOST}"
  teardown_tmux_server
}

press() {
  local key
  for key in "$@"; do
    command tmux -S "${HOST}" send-keys -t host "${key}"
  done
}

@test "keys - prefix M-k opens the context menu, and picking a context switches to it" {
  # Arrange
  kubeconfig
  press C-b M-k
  wait_for host_shows "Context"
  wait_for host_shows "prod"

  # Act
  press Down Enter

  # Assert
  wait_for asked "config use-context prod"
}

@test "keys - prefix M-k without any context says so" {
  # Arrange
  local expected="kube-revamped: the kubeconfig holds no context"

  # Act
  press C-b M-k

  # Assert
  wait_for said "${expected}"
}

@test "keys - the namespace key lists what kubectl answers, and picking one sets it" {
  # Arrange
  kubeconfig
  printf 'namespace/web\nnamespace/api\n' >"${BATS_TEST_TMPDIR}/namespaces"
  press C-b F2
  wait_for host_shows "Namespace"
  wait_for host_shows "api"

  # Act
  press Down Enter

  # Assert
  wait_for asked "config set-context --current --namespace api"
}

@test "keys - the namespace key says so when kubectl lists nothing" {
  # Arrange
  kubeconfig

  # Act
  press C-b F2

  # Assert
  wait_for said "kube-revamped: kubectl listed no namespace"
}

@test "keys - the popup key opens k9s on the current context and namespace" {
  # Arrange
  kubeconfig
  tmux run-shell "'${ROOT}/src/kube.sh' refresh"
  wait_for cached "dev|web"

  # Act
  press C-b F3

  # Assert
  wait_for host_shows "k9s stand-in --context dev --namespace web"
}

@test "keys - the popup key names a command that is not installed" {
  # Arrange
  kubeconfig
  tmux set-option -g @kube_revamped_popup_command "no-such-kube-tool -A"
  tmux run-shell "'${ROOT}/src/kube.sh' refresh"
  wait_for cached "dev|web"

  # Act
  press C-b F3

  # Assert
  wait_for said "kube-revamped: no-such-kube-tool is not installed"
}

@test "keys - the popup key says so before any context is known" {
  # Arrange
  local expected="kube-revamped: no current context to open"

  # Act
  press C-b F3

  # Assert
  wait_for said "${expected}"
}
