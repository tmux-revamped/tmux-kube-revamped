#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/server_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/server_helpers.bash"

bats_require_minimum_version 1.5.0

everything() {
  local options
  options=$(tmux show-options -g)
  grep -vE '@kube_revamped_(value|reach|nodes|pods|dangling|cluster|user)' <<<"${options}"
  tmux list-keys
}

@test "entrypoint - git tracks the entry point and the tool as executable" {
  # Arrange
  local modes

  # Act
  modes=$(git -C "${ROOT}" ls-files --stage -- kube-revamped.tmux bin/kube-revamped)

  # Assert
  run awk '$1 != "100755" { bad++ } END { print NR ":" bad + 0 }' <<<"${modes}"
  [[ "${output}" == "2:0" ]]
}

@test "entrypoint - loading binds the context menu on M-k and turns each placeholder into its job" {
  # Arrange
  local keys
  tmux set-option -g status-right '#{kube} | #{kube_context} | #{kube_namespace} end'

  # Act
  load_plugin

  # Assert
  keys=$(prefix_keys)
  run grep -c -x 'M-k' <<<"${keys}"
  [[ "${output}" == "1" ]]
  run tmux show-option -gqv status-right
  [[ "${output}" == "#('${ROOT}/bin/kube-revamped' status kube) | #('${ROOT}/bin/kube-revamped' status context) | #('${ROOT}/bin/kube-revamped' status namespace) end" ]]
  wait_for host_shows "prod-east:payments | prod-east | payments end"
}

@test "entrypoint - loading twice changes nothing" {
  # Arrange
  local before after
  tmux set-option -g status-right '#{kube} end'
  load_plugin
  before=$(everything)

  # Act
  load_plugin

  # Assert
  after=$(everything)
  [[ "${before}" == "${after}" ]]
}

@test "entrypoint - a checkout whose path holds a space, a quote and a hash loads, shows the context and takes its key" {
  # Arrange
  local copy="${BATS_TEST_TMPDIR}/it's #1 plug in"
  mkdir -p "${copy}"
  cp -R "${ROOT}/bin" "${ROOT}/lib" "${ROOT}/kube-revamped.tmux" "${copy}/"
  tmux set-option -g status-right '#{kube} end'
  load_plugin "${copy}"
  wait_for host_shows "prod-east:payments end"
  press C-b M-k
  wait_for host_shows "Context"

  # Act
  press Down Enter

  # Assert
  wait_for holds value "staging|default"
  wait_for host_shows "staging:default end"
}

@test "entrypoint - a default key someone else holds is left alone, and one the person names is bound" {
  # Arrange
  local table
  tmux bind-key -T prefix M-k display-message taken
  tmux bind-key -T prefix x display-message taken-too
  setting popup_key x

  # Act
  load_plugin

  # Assert
  table=$(tmux list-keys -T prefix)
  run grep -c 'M-k  *display-message taken' <<<"${table}"
  [[ "${output}" == "1" ]]
  run grep -c 'kube-revamped. popup' <<<"${table}"
  [[ "${output}" == "1" ]]
}

@test "entrypoint - a key set to off binds nothing" {
  # Arrange
  local table
  setting menu_context_key off

  # Act
  load_plugin

  # Assert
  table=$(tmux list-keys -T prefix)
  run grep -c 'kube-revamped' <<<"${table}"
  [[ "${output}" == "0" ]]
}
