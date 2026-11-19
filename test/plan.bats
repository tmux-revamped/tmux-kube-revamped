#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/kube_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/kube_helpers.bash"

logged() {
  grep -qF -- "$1" "${FAKE}/log"
}

@test "plan - a fresh install binds the context menu to M-k and nothing else" {
  # Arrange
  local tool
  tool=$(tool_path)

  # Act
  planned

  # Assert
  [[ "${output}" == "bind-key -N Kubernetes contexts M-k run-shell ${tool} menu-context" ]]
}

@test "plan - the namespace menu and the popup are bound when their keys are set" {
  # Arrange
  local tool
  tool=$(tool_path)
  option menu_context_key C
  option menu_namespace_key N
  option popup_key P

  # Act
  planned

  # Assert
  [[ "${lines[0]}" == "bind-key -N Kubernetes contexts C run-shell ${tool} menu-context" ]]
  [[ "${lines[1]}" == "bind-key -N Kubernetes namespaces N run-shell ${tool} menu-namespace" ]]
  [[ "${lines[2]}" == "bind-key -N Kubernetes popup P run-shell ${tool} popup" ]]
}

@test "plan - a tmux older than 3.1 gets its keys without notes" {
  # Arrange
  local tool
  tool=$(tool_path)
  tmux_is 3.0

  # Act
  planned

  # Assert
  [[ "${output}" == "bind-key M-k run-shell ${tool} menu-context" ]]
}

@test "plan - off leaves the context menu without a key" {
  # Arrange
  option menu_context_key off

  # Act
  planned

  # Assert
  [[ -z "${output}" ]]
}

@test "plan - the default key is left alone when something else holds it, and named as skipped" {
  # Arrange
  printf 'bind-key    -T prefix M-k     display-menu -T mine\nbind-key -r -T prefix \\; last-pane\n' >"${FAKE}/keys"

  # Act
  planned 'kube_revamped_plan; printf "[%s]\n" "${KUBE_REVAMPED_SKIPPED}"; '

  # Assert
  [[ "${output}" == "[M-k]" ]]
}

@test "plan - the default key is bound again when the binding on it is the plugin's own" {
  # Arrange
  local tool
  tool=$(tool_path)
  printf 'bind-key    -T prefix M-k     run-shell "/old/bin/kube-revamped menu-context"\n' >"${FAKE}/keys"

  # Act
  planned

  # Assert
  [[ "${output}" == "bind-key -N Kubernetes contexts M-k run-shell ${tool} menu-context" ]]
}

@test "plan - a key the person set is bound even when something else holds it" {
  # Arrange
  printf 'bind-key    -T prefix C     new-window\n' >"${FAKE}/keys"
  option menu_context_key C

  # Act
  planned

  # Assert
  [[ "${output}" == "bind-key -N Kubernetes contexts C run-shell "*" menu-context" ]]
}

@test "plan - one key given to two actions goes to the first, and the clash is named" {
  # Arrange
  option menu_namespace_key M-k
  option popup_key P

  # Act
  planned 'kube_revamped_plan; printf "[%s]\n" "${KUBE_REVAMPED_SKIPPED}"; '

  # Assert
  [[ "${lines[0]}" == "[M-k]" ]]
  [[ "${lines[1]}" == *" M-k run-shell "*" menu-context" ]]
  [[ "${lines[2]}" == *" P run-shell "*" popup" ]]
  [[ "${#lines[@]}" -eq 3 ]]
}

@test "plan - each placeholder in the status line becomes a job that prints it" {
  # Arrange
  local tool
  tool=$(tool_path)
  option menu_context_key off
  var status-right 'A #{kube} B #{kube_context} C #{kube_namespace} #{kube}'
  var status-left '#S plain'

  # Act
  planned

  # Assert
  [[ "${output}" == "set-option -gq status-right A #(${tool} status kube) B #(${tool} status context) C #(${tool} status namespace) #(${tool} status kube)" ]]
}

@test "plan - a setting given in the environment rides on every key and every job" {
  # Arrange
  local tool
  tool=$(tool_path)
  var status-left '#{kube_context}'

  # Act
  planned 'export KUBE_REVAMPED_INTERVAL=30 KUBE_REVAMPED_PROD_PATTERN="it'"'"'s #1"; '

  # Assert
  [[ "${lines[0]}" == "bind-key -N Kubernetes contexts M-k run-shell ${tool} --interval '30' --prod-pattern 'it'\\''s '\"\$(printf '%b' '\\0043')\"'1' menu-context" ]]
  [[ "${lines[1]}" == "set-option -gq status-left #(${tool} --interval '30' --prod-pattern 'it'\\''s ##1' status context)" ]]
}

@test "plan - apply sends every binding and status line in one tmux call" {
  # Arrange
  option popup_key P
  var status-right '#{kube}'

  # Act
  lib_run kube 'kube_revamped_apply'

  # Assert
  [[ "${status}" -eq 0 ]]
  run sends
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "${output}" == "bind-key -N Kubernetes contexts M-k run-shell "*" ; bind-key -N Kubernetes popup P run-shell "*" popup ; set-option -gq status-right #("*" status kube)" ]]
}

@test "plan - when tmux refuses the batch each binding is sent alone, and the bad one fails the run" {
  # Arrange
  local tool
  tool=$(tool_path)
  option popup_key F99
  printf '%s\n' "bind-key -N Kubernetes popup F99 run-shell ${tool} popup" >"${FAKE}/refused"

  # Act
  lib_run kube 'kube_revamped_apply'

  # Assert
  [[ "${status}" -eq 1 ]]
  run grep -cxF -- "bind-key -N Kubernetes contexts M-k run-shell ${tool} menu-context" "${FAKE}/log"
  [[ "${output}" == "1" ]]
}

@test "plan - the context menu lists every context, each switching to itself" {
  # Arrange
  local tool
  tool=$(tool_path)
  two_contexts

  # Act
  lib_run kube 'kube_revamped_menu_context'

  # Assert
  [[ "${status}" -eq 0 ]]
  logged "display-menu -T Context prod-east  run-shell \"${tool} use-context 'prod-east'\" staging  run-shell \"${tool} use-context 'staging'\""
}

@test "plan - a quote or a hash in a context name reaches the menu's label doubled and its command hash-free" {
  # Arrange
  kubeconfig 'contexts:' "- name: it's#1"

  # Act
  lib_run kube 'kube_revamped_menu_context'

  # Assert
  logged "display-menu -T Context it's##1  run-shell \""
  logged "use-context 'it'\\\\''s'\\\"\\\$(printf '%b' '\\\\0043')\\\"'1'\""
}

@test "plan - a setting given in the environment rides on each menu item" {
  # Arrange
  two_contexts

  # Act
  lib_run kube 'export KUBE_REVAMPED_PROBE_REACH=1; kube_revamped_menu_context'

  # Assert
  logged "--probe-reach '1' use-context 'staging'"
}

@test "plan - a kubeconfig without a context says so and opens no menu" {
  # Arrange
  kubeconfig 'current-context: ghost'

  # Act
  lib_run kube 'kube_revamped_menu_context'

  # Assert
  [[ "${status}" -eq 0 ]]
  said "the kubeconfig holds no context"
  run sent '^display-menu'
  [[ "${output}" == "0" ]]
}

@test "plan - the namespace menu lists what kubectl names, each setting itself" {
  # Arrange
  local tool
  tool=$(tool_path)
  printf 'namespace/default\n\nnamespace/team-a\n' >"${FAKE}/namespaces"

  # Act
  lib_run kube 'kube_revamped_menu_namespace'

  # Assert
  logged "display-menu -T Namespace default  run-shell \"${tool} use-namespace 'default'\" team-a  run-shell \"${tool} use-namespace 'team-a'\""
  run asked
  [[ "${output}" == "get namespaces -o name --request-timeout=2" ]]
}

@test "plan - when kubectl lists no namespace the key says so and opens no menu" {
  # Arrange
  : >"${FAKE}/kubectl-fails"

  # Act
  lib_run kube 'kube_revamped_menu_namespace'

  # Assert
  [[ "${status}" -eq 0 ]]
  said "kubectl listed no namespace"
  run sent '^display-menu'
  [[ "${output}" == "0" ]]
}

@test "plan - the popup runs its program on the stored context and namespace" {
  # Arrange
  quiet k9s ':'
  cached "prod|pay"

  # Act
  lib_run kube 'kube_revamped_popup'

  # Assert
  [[ "${status}" -eq 0 ]]
  logged "display-popup -E -w 80% -h 80% k9s --context 'prod' --namespace 'pay'"
}

@test "plan - the popup's program, size and a context with a hash come through, without a namespace when none is stored" {
  # Arrange
  quiet lens ':'
  cached "a#S"
  option popup_command "lens --readonly"
  option popup_width 50%
  option popup_height 40

  # Act
  lib_run kube 'kube_revamped_popup'

  # Assert
  run grep -xF -- "display-popup -E -w 50% -h 40 lens --readonly --context 'a'\"\$(printf '%b' '\\0043')\"'S'" "${FAKE}/log"
  [[ "${status}" -eq 0 ]]
}

@test "plan - the popup says so on a tmux older than 3.2" {
  # Arrange
  quiet k9s ':'
  cached "prod|pay"
  tmux_is 3.1

  # Act
  lib_run kube 'kube_revamped_popup'

  # Assert
  [[ "${status}" -eq 0 ]]
  said "the popup needs tmux 3.2 or later"
  run sent '^display-popup'
  [[ "${output}" == "0" ]]
}

@test "plan - the popup says so when no context is stored" {
  # Arrange
  quiet k9s ':'

  # Act
  lib_run kube 'kube_revamped_popup'

  # Assert
  [[ "${status}" -eq 0 ]]
  said "no current context to open"
}

@test "plan - the popup names a program that is not installed, where it would close at once" {
  # Arrange
  cached "prod|pay"
  option popup_command "no-such-viewer#1 --flag"

  # Act
  lib_run kube 'kube_revamped_popup'

  # Assert
  [[ "${status}" -eq 0 ]]
  said "no-such-viewer##1 is not installed"
  run sent '^display-popup'
  [[ "${output}" == "0" ]]
}

@test "plan - a path is quoted for a job with each hash and each percent sign doubled, and for a popup with none left" {
  # Arrange
  local script='kube_revamped_job_quote "/a b/it'"'"'s#1 50%"; kube_revamped_literal "/a b/it'"'"'s#1 50%"'

  # Act
  lib_run kube "${script}"

  # Assert
  [[ "${lines[0]}" == "'/a b/it'\\''s##1 50%%'" ]]
  [[ "${lines[1]}" == "'/a b/it'\\''s'\"\$(printf '%b' '\\0043')\"'1 50%'" ]]
}
