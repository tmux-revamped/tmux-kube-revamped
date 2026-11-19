#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/kube_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/kube_helpers.bash"

logged() {
  grep -qF -- "$1" "${FAKE}/log"
}

@test "commands - status prints one placeholder from the stored reading" {
  # Arrange
  cached "prod|pay"
  tool status context
  [[ "${output}" == "prod" ]]
  tool status namespace
  [[ "${output}" == "pay" ]]

  # Act
  tool status kube

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "#[fg=blue]prod:pay#[default]" ]]
}

@test "commands - status without a name is a usage error, and an unknown name a bad value" {
  # Arrange
  tool status
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "kube-revamped: no placeholder given. run 'kube-revamped help' for usage." ]]

  # Act
  tool status cluster

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "kube-revamped: status must be kube, context or namespace, got: cluster" ]]
}

@test "commands - refresh reads the kubeconfig now and says what it found" {
  # Arrange
  two_contexts

  # Act
  tool refresh

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "Refreshed. The context is prod-east in the namespace payments." ]]
  holds value "prod-east|payments"
}

@test "commands - refresh names a context the kubeconfig lacks" {
  # Arrange
  kubeconfig 'current-context: ghost' 'contexts:' '- name: staging'

  # Act
  tool refresh

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "Refreshed. The context ghost is not in the kubeconfig." ]]
}

@test "commands - refresh says when no context is set" {
  # Arrange
  kubeconfig 'contexts:' '- name: staging'

  # Act
  tool refresh

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "Refreshed. No current context is set." ]]
}

@test "commands - refresh fails when no tmux server takes the reading" {
  # Arrange
  two_contexts
  : >"${FAKE}/refused"

  # Act
  tool refresh

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "kube-revamped: no tmux server is running, so the reading has nowhere to go" ]]
}

@test "commands - use-context and use-namespace need a name" {
  # Arrange
  tool use-context
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "kube-revamped: no context given. run 'kube-revamped help' for usage." ]]

  # Act
  tool use-namespace

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "kube-revamped: no namespace given. run 'kube-revamped help' for usage." ]]
}

@test "commands - use-context and use-namespace switch through kubectl and print nothing" {
  # Arrange
  two_contexts
  tool use-context staging
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]

  # Act
  tool use-namespace team-a

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
  run asked
  [[ "${lines[0]}" == "config use-context staging" ]]
  [[ "${lines[1]}" == "config set-context --current --namespace team-a" ]]
}

@test "commands - the two menus and the popup are commands a key or a script can run" {
  # Arrange
  two_contexts
  quiet k9s ':'
  cached "prod|pay"
  printf 'namespace/default\n' >"${FAKE}/namespaces"
  tool menu-context
  [[ "${status}" -eq 0 ]]
  tool menu-namespace
  [[ "${status}" -eq 0 ]]

  # Act
  tool popup

  # Assert
  [[ "${status}" -eq 0 ]]
  logged "display-menu -T Context prod-east"
  logged "display-menu -T Namespace default"
  logged "display-popup -E -w 80% -h 80% k9s --context 'prod' --namespace 'pay'"
}

@test "commands - apply binds the keys in one tmux call and prints nothing" {
  # Arrange
  option menu_namespace_key N

  # Act
  tool apply

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
  run sends
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "${output}" == "bind-key -N Kubernetes contexts M-k run-shell "*" ; bind-key -N Kubernetes namespaces N run-shell "*" menu-namespace" ]]
}

@test "commands - list prints what apply would send, one tmux command a line" {
  # Arrange
  local path
  path=$(bin_path)
  var status-right '#{kube_namespace}'

  # Act
  tool list

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == "bind-key -N Kubernetes contexts M-k run-shell ${path} menu-context" ]]
  [[ "${lines[1]}" == "set-option -gq status-right #(${path} status namespace)" ]]
  run sends
  [[ -z "${output}" ]]
}

@test "commands - list --json prints the same plan as one object" {
  # Arrange
  option menu_context_key 'C-"'

  # Act
  tool list --json

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == '{"bindings":[["bind-key","-N","Kubernetes contexts","C-\"","run-shell","'*' menu-context"]]}' ]]
}

@test "commands - with nothing to bind list --json is an empty plan" {
  # Arrange
  option menu_context_key off

  # Act
  tool list --json

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == '{"bindings":[]}' ]]
}

@test "commands - --json with any command but list is a usage error" {
  # Arrange
  two_contexts

  # Act
  tool --json refresh

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "kube-revamped: option '--json' works only with list. run 'kube-revamped help' for usage." ]]
}

@test "commands - a setting is taken as --name value and as --name=value" {
  # Arrange
  local path
  path=$(bin_path)
  tool --popup-key P list
  [[ "${lines[1]}" == "bind-key -N Kubernetes popup P run-shell ${path} popup" ]]

  # Act
  tool --interval=30 list

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "bind-key -N Kubernetes contexts M-k run-shell "*" --interval '30' menu-context" ]]
}

@test "commands - the command line wins over the environment, and the environment over the tmux option" {
  # Arrange
  cached "prod|pay"
  option icon T
  export KUBE_REVAMPED_ICON=E
  tool status kube
  [[ "${output}" == "#[fg=blue]E prod:pay#[default]" ]]

  # Act
  tool --icon C status kube

  # Assert
  [[ "${output}" == "#[fg=blue]C prod:pay#[default]" ]]
}

@test "commands - an unknown option is a usage error in each of its forms" {
  # Arrange
  tool --bogus list
  [[ "${output}" == "kube-revamped: unknown option '--bogus'. run 'kube-revamped help' for usage." ]]
  tool --bogus=1 list
  [[ "${output}" == "kube-revamped: unknown option '--bogus'. run 'kube-revamped help' for usage." ]]

  # Act
  tool -x list

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "kube-revamped: unknown option '-x'. run 'kube-revamped help' for usage." ]]
}

@test "commands - an option at the end without its value is a usage error" {
  # Arrange
  cached "prod|pay"

  # Act
  tool status --interval

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "kube-revamped: option '--interval' needs a value. run 'kube-revamped help' for usage." ]]
}

@test "commands - a double dash ends the options" {
  # Arrange
  cached "prod|pay"

  # Act
  tool -- --weird

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "kube-revamped: unknown command '--weird'. run 'kube-revamped help' for usage." ]]
}

@test "commands - an interval that is not a whole number is refused" {
  # Arrange
  cached "prod|pay"

  # Act
  tool --interval 1.5 status kube

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "kube-revamped: --interval must be a whole number of seconds, got: 1.5" ]]
}

@test "commands - a switch takes 0 or 1 only, from the command line and from the environment" {
  # Arrange
  cached "prod|pay"
  export KUBE_REVAMPED_HIDE_DEFAULT=yes
  tool status kube
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "kube-revamped: --hide-default must be 0 or 1, got: yes" ]]
  unset KUBE_REVAMPED_HIDE_DEFAULT

  # Act
  tool --probe-pods 2 status kube

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "kube-revamped: --probe-pods must be 0 or 1, got: 2" ]]
}

@test "commands - doctor names a default key someone else holds, and says so when every key is free" {
  # Arrange
  local free='keys +ok +every key it binds is free or its own' held='keys +warn +already bound and left alone: M-k'
  two_contexts
  tool doctor
  [[ "${output}" =~ ${free} ]]
  printf 'bind-key    -T prefix M-k     display-menu -T mine\n' >"${FAKE}/keys"

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ ${held} ]]
}

@test "commands - doctor names a tmux option whose value it does not know" {
  # Arrange
  option show_user yes

  # Act
  tool doctor

  # Assert
  run grep '^settings' <<<"${output}"
  [[ "${output}" == "settings           warn     unknown values: show_user=yes" ]]
}
