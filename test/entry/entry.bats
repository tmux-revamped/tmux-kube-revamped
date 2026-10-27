#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../helpers.bash"

ENTRY="${BATS_TEST_DIRNAME}/../../kube-revamped.tmux"

setup() {
  setup_test_environment
}

teardown() {
  cleanup_test_environment
}

@test "entry - a placeholder becomes a dispatcher call" {
  # Arrange
  local dir="${TEST_TMPDIR}/plain"
  mkdir -p "${dir}/src"
  cp -f "${ENTRY}" "${dir}/kube-revamped.tmux"
  tmux set-option -gq "status-right" "[#{kube_context}]"

  # Act
  bash "${dir}/kube-revamped.tmux"

  # Assert
  [ "$(cat "$(_mock_opt_file status-right)")" = "[#(${TEST_TMPDIR}/plain/src/kube.sh context)]" ]
}

@test "entry - a plugin path with an ampersand and a space reaches the shell as one word" {
  # Arrange
  local dir="${TEST_TMPDIR}/a&b c"
  mkdir -p "${dir}/src"
  cp -f "${ENTRY}" "${dir}/kube-revamped.tmux"
  tmux set-option -gq "status-right" "[#{kube_context}|#{kube_namespace}]"

  # Act
  bash "${dir}/kube-revamped.tmux"

  # Assert
  [ "$(cat "$(_mock_opt_file status-right)")" = "[#(${TEST_TMPDIR}/a\\&b\\ c/src/kube.sh context)|#(${TEST_TMPDIR}/a\\&b\\ c/src/kube.sh namespace)]" ]
}
