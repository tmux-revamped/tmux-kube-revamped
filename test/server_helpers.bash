#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/tmux_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/tmux_helpers.bash"

screens() {
  printf 'host screen:\n'
  command tmux -S "${HOST}" capture-pane -p -t host || :
  printf 'options:\n'
  tmux show-options -g | grep kube || :
  printf 'messages:\n'
  tmux show-messages | tail -n 5 || :
}

wait_for() {
  local delay
  for delay in 0.01 0.02 0.05 0.1 0.1 0.2 0.2 0.5 0.5 1 1 1 2 2; do
    "$@" && return 0
    sleep "${delay}"
  done
  "$@" && return 0
  screens
  return 1
}

attached() {
  local clients
  clients=$(tmux list-clients -F x 2>/dev/null)
  [[ -n "${clients}" ]]
}

holds() {
  local now
  now=$(tmux show-option -gqv "@kube_revamped_$1")
  [[ "${now}" == "$2" ]]
}

host_shows() {
  local screen
  screen=$(command tmux -S "${HOST}" capture-pane -p -t host)
  [[ "${screen}" == *"$1"* ]]
}

host_lacks() {
  ! host_shows "$1"
}

said() {
  local messages
  messages=$(tmux show-messages)
  [[ "${messages}" == *"kube-revamped: $1"* ]]
}

asked() {
  grep -qxF -- "$1" "${BATS_TEST_TMPDIR}/kubectl.calls" 2>/dev/null
}

stand_ins() {
  cat >"${STUBS}/kubectl" <<STUB
#!/bin/sh
printf '%s\n' "\$*" >>'${BATS_TEST_TMPDIR}/kubectl.calls'
case "\$*" in
"config use-context "*)
  awk -v name="\$3" '/^current-context:/ { print "current-context: \"" name "\""; next } { print }' '${KUBECONFIG}' >'${KUBECONFIG}.new'
  mv -f '${KUBECONFIG}.new' '${KUBECONFIG}'
  ;;
"get namespaces"*) [ -f '${BATS_TEST_TMPDIR}/no-namespaces' ] || printf 'namespace/default\nnamespace/team-a\n' ;;
*) : ;;
esac
STUB
  printf '#!/bin/sh\nprintf "k9s stand-in running %%s\\n" "$*"\nread -r stand_in_wait\n' >"${STUBS}/k9s"
  chmod +x "${STUBS}/kubectl" "${STUBS}/k9s"
}

setup() {
  unset BASH_ENV
  ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  STUBS="${BATS_TEST_TMPDIR}/stubs"
  export HOME="${BATS_TEST_TMPDIR}/home" KUBECONFIG="${BATS_TEST_TMPDIR}/config"
  mkdir -p "${HOME}" "${STUBS}"
  printf '%s\n' 'current-context: prod-east' 'contexts:' '- name: prod-east' '  context:' '    cluster: c1' '    namespace: payments' '- name: staging' '  context:' '    cluster: c2' "- name: 'dev#S'" '  context:' '    cluster: c3' >"${KUBECONFIG}"
  stand_ins
  PATH="${STUBS}:${PATH}"
  setup_tmux_server
  HOST="${TMUX_SOCKET}-host"
  tmux set-option -g default-command "env PS1='$ ' sh"
  tmux respawn-pane -k -t test:0.0 "env PS1='$ ' sh"
  tmux set-option -g status-interval 1
  tmux set-option -g status-left ''
  tmux set-option -g status-right-length 120
  command tmux -S "${HOST}" -f /dev/null new-session -d -s host -x 120 -y 30 \
    "env -u TMUX TERM=xterm-256color tmux -S '${TMUX_SOCKET}' attach-session -t test"
  wait_for attached
}

teardown() {
  command tmux -S "${HOST}" kill-server 2>/dev/null || :
  rm -f "${HOST}"
  teardown_tmux_server
}

load_plugin() {
  local quoted
  quoted=$(printf '%s' "${1:-${ROOT}}" | sed "s/'/'\\\\''/g")
  tmux run-shell "'${quoted}/kube-revamped.tmux'"
}

setting() {
  set_option "@kube_revamped_$1" "$2"
}

press() {
  local key
  for key in "$@"; do
    command tmux -S "${HOST}" send-keys -t host "${key}"
  done
}

prefix_keys() {
  local table
  table=$(tmux list-keys -T prefix)
  awk '{ for (i = 1; i < NF; i++) { if ($i == "-T") { print $(i + 2); break } } }' <<<"${table}"
}
