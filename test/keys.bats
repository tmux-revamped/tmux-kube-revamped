#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/server_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/server_helpers.bash"

bats_require_minimum_version 1.5.0

loaded_with_status() {
  tmux set-option -g status-right '#{kube} end'
  load_plugin
  wait_for host_shows "prod-east:payments end"
}

@test "keys - prefix M-k opens the context menu, and choosing a context switches to it" {
  # Arrange
  loaded_with_status
  press C-b M-k
  wait_for host_shows "Context"
  wait_for host_shows "staging"

  # Act
  press Down Enter

  # Assert
  wait_for asked "config use-context staging"
  wait_for holds value "staging|default"
  wait_for host_shows "staging:default end"
}

@test "keys - a context whose name holds a hash is listed, chosen and shown as it is written" {
  # Arrange
  loaded_with_status
  press C-b M-k
  wait_for host_shows "dev#S"

  # Act
  press Down Down Enter

  # Assert
  wait_for asked "config use-context dev#S"
  wait_for holds value "dev#S|default"
  wait_for host_shows "dev#S:default end"
}

@test "keys - Escape closes the context menu and switches nothing" {
  # Arrange
  loaded_with_status
  press C-b M-k
  wait_for host_shows "Context"

  # Act
  press Escape

  # Assert
  wait_for host_lacks "Context"
  [[ ! -e "${BATS_TEST_TMPDIR}/kubectl.calls" ]]
  holds value "prod-east|payments"
}

@test "keys - prefix M-k says so when the kubeconfig holds no context" {
  # Arrange
  printf 'current-context: ghost\n' >"${KUBECONFIG}"
  load_plugin

  # Act
  press C-b M-k

  # Assert
  wait_for said "the kubeconfig holds no context"
}

@test "keys - the namespace key opens the namespace menu, and choosing one sets it" {
  # Arrange
  setting menu_namespace_key N
  loaded_with_status
  press C-b N
  wait_for host_shows "Namespace"
  wait_for host_shows "team-a"

  # Act
  press Down Enter

  # Assert
  wait_for asked "config set-context --current --namespace team-a"
}

@test "keys - the namespace key says so when kubectl lists no namespace" {
  # Arrange
  : >"${BATS_TEST_TMPDIR}/no-namespaces"
  setting menu_namespace_key N
  load_plugin

  # Act
  press C-b N

  # Assert
  wait_for said "kubectl listed no namespace"
}

@test "keys - the popup key runs the popup program on the current context and namespace, and it stays open" {
  # Arrange
  setting popup_key P
  loaded_with_status

  # Act
  press C-b P

  # Assert
  wait_for host_shows "k9s stand-in running --context prod-east --namespace payments"
  press Enter
  wait_for host_lacks "k9s stand-in running"
}

@test "keys - Ctrl-C ends the popup program and leaves no error over the pane" {
  # Arrange
  setting popup_key P
  loaded_with_status
  press C-b P
  wait_for host_shows "k9s stand-in running"

  # Act
  press C-c

  # Assert
  wait_for host_lacks "k9s stand-in running"
  host_lacks "returned"
  run tmux display-message -p -t test '#{pane_in_mode}'
  [[ "${output}" == "0" ]]
}

@test "keys - the popup key names a program that is not installed" {
  # Arrange
  setting popup_key P
  setting popup_command "no-such-viewer --all"
  loaded_with_status

  # Act
  press C-b P

  # Assert
  wait_for said "no-such-viewer is not installed"
}

@test "keys - the popup key says so before any context was read" {
  # Arrange
  setting popup_key P
  load_plugin

  # Act
  press C-b P

  # Assert
  wait_for said "no current context to open"
}
