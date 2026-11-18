#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/kube_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/kube_helpers.bash"

status_of() {
  lib_run kube 'kube_revamped_status '"$1"
}

@test "refresh - a fresh reading is printed with one tmux read and no write" {
  # Arrange
  two_contexts
  cached "prod|pay" 999995

  # Act
  status_of kube

  # Assert
  [[ "${output}" == "#[fg=blue]prod:pay#[default]" ]]
  run sends
  [[ -z "${output}" ]]
  run sent '^display-message -p'
  [[ "${output}" == "1" ]]
}

@test "refresh - a reading older than the interval is printed at once while a new one is read behind it" {
  # Arrange
  two_contexts
  cached "old|ns" 999989

  # Act
  status_of kube

  # Assert
  [[ "${output}" == "#[fg=blue]old:ns#[default]" ]]
  eventually holds value "prod-east|payments"
  eventually holds value_lock 0
  holds cluster c1
  holds user alice
  holds value_ts 1000000
}

@test "refresh - with nothing stored yet the placeholder is empty and the first reading starts" {
  # Arrange
  two_contexts

  # Act
  status_of context

  # Assert
  [[ -z "${output}" ]]
  eventually holds value "prod-east|payments"
}

@test "refresh - a reading already under way is left to finish" {
  # Arrange
  two_contexts
  cached "old|ns" 999980
  option value_lock 1
  option value_lock_ts 999995

  # Act
  status_of namespace

  # Assert
  [[ "${output}" == "ns" ]]
  run sends
  [[ -z "${output}" ]]
}

@test "refresh - a reading that never finished is started again once its lock is old" {
  # Arrange
  two_contexts
  cached "old|ns" 999900
  option value_lock 1
  option value_lock_ts 999975

  # Act
  status_of kube

  # Assert
  eventually holds value "prod-east|payments"
}

@test "refresh - a lock with no time on it holds nothing back" {
  # Arrange
  two_contexts
  cached "old|ns" 999900
  option value_lock 1

  # Act
  status_of kube

  # Assert
  eventually holds value "prod-east|payments"
}

@test "refresh - the interval comes from its setting, and junk there means ten seconds" {
  # Arrange
  two_contexts
  cached "old|ns" 999950
  option interval 60
  status_of kube
  run sends
  [[ -z "${output}" ]]
  option interval abc

  # Act
  status_of kube

  # Assert
  eventually holds value "prod-east|payments"
}

@test "refresh - a limited command hands back its output and its status" {
  # Arrange
  local script='code=0; kube_revamped_limited sh -c "printf out; exit 3" || code=$?; printf "[%s]" "${code}"'

  # Act
  lib_run kube "${script}"

  # Assert
  [[ "${output}" == "out[3]" ]]
}

@test "refresh - a command that outlives the limit is stopped" {
  # Arrange
  quiet sleep ':'
  local script='code=0; kube_revamped_limited /bin/sleep 30 || code=$?; printf "[%s]" "${code}"'

  # Act
  lib_run kube "${script}"

  # Assert
  [[ "${output}" == "[143]" ]]
}

@test "refresh - nodes are counted as ready over all, and pods that neither run nor completed as failing" {
  # Arrange
  printf 'n1 Ready x\nn2 NotReady x\n\nn3 Ready x\n' >"${FAKE}/nodes"
  printf 'p1 1/1 Running\np2 0/1 CrashLoopBackOff\np3 0/1 Completed\np4 0/1 Pending\n' >"${FAKE}/pods"

  # Act
  lib_run kube 'kube_revamped_nodes; kube_revamped_pods'

  # Assert
  [[ "${lines[0]}" == "2/3" ]]
  [[ "${lines[1]}" == "2" ]]
  run asked
  [[ "${lines[0]}" == "get nodes --no-headers --request-timeout=2" ]]
  [[ "${lines[1]}" == "get pods --no-headers --request-timeout=2" ]]
}

@test "refresh - a probe with no rows, or a kubectl that fails, answers nothing" {
  # Arrange
  lib_run kube 'kube_revamped_nodes; kube_revamped_pods; printf "end\n"'
  [[ "${output}" == "end" ]]
  : >"${FAKE}/kubectl-fails"

  # Act
  lib_run kube 'kube_revamped_nodes; kube_revamped_pods; printf "end\n"'

  # Assert
  [[ "${output}" == "end" ]]
}

@test "refresh - every probe that is on is written in one tmux call" {
  # Arrange
  printf 'n1 Ready x\n' >"${FAKE}/nodes"
  printf 'p1 0/1 Pending\n' >"${FAKE}/pods"
  local script='KUBE_REVAMPED_S_probe_reach=1 KUBE_REVAMPED_S_probe_nodes=1 KUBE_REVAMPED_S_probe_pods=1; kube_revamped_probe_all'

  # Act
  lib_run kube "${script}"

  # Assert
  run sends
  [[ "${output}" == "set-option -gq @kube_revamped_reach up ; set-option -gq @kube_revamped_nodes 1/1 ; set-option -gq @kube_revamped_pods 1" ]]
  run asked
  [[ "${lines[0]}" == "cluster-info --request-timeout=2" ]]
}

@test "refresh - a cluster that does not answer is written as down" {
  # Arrange
  : >"${FAKE}/kubectl-fails"

  # Act
  lib_run kube 'KUBE_REVAMPED_S_probe_reach=1; kube_revamped_probe_all'

  # Assert
  holds reach down
}

@test "refresh - with every probe off kubectl is never called and nothing is written" {
  # Arrange
  local script='kube_revamped_probe_all'

  # Act
  lib_run kube "${script}"

  # Assert
  run sends
  [[ -z "${output}" ]]
  run asked
  [[ -z "${output}" ]]
}

@test "refresh - the reading is written in one tmux call, without kubectl" {
  # Arrange
  two_contexts

  # Act
  lib_run kube 'kube_revamped_refresh; printf "[%s]" "${KUBE_REVAMPED_STORED}"'

  # Assert
  [[ "${output}" == "[1]" ]]
  run sends
  [[ "${output}" == "set-option -gq @kube_revamped_value prod-east|payments ; set-option -gq @kube_revamped_value_ts 1000000 ; set-option -gq @kube_revamped_dangling  ; set-option -gq @kube_revamped_cluster c1 ; set-option -gq @kube_revamped_user alice" ]]
  run asked
  [[ -z "${output}" ]]
}

@test "refresh - a name that ends in a semicolon is sent whole, where tmux would end the command at it" {
  # Arrange
  kubeconfig 'current-context: staging' 'contexts:' '- name: staging' '  context:' '    cluster: "c2;"' '    user: "bob;"'

  # Act
  lib_run kube 'kube_revamped_refresh'

  # Assert
  run sends
  [[ "${output}" == *"set-option -gq @kube_revamped_cluster c2\\; ; set-option -gq @kube_revamped_user bob\\;" ]]
}

@test "refresh - a context the kubeconfig lacks is stored as dangling, and still probed" {
  # Arrange
  kubeconfig 'current-context: ghost' 'contexts:' '- name: staging'

  # Act
  lib_run kube 'KUBE_REVAMPED_S_probe_reach=1; kube_revamped_refresh'

  # Assert
  holds value "ghost|"
  holds dangling 1
  holds reach up
}

@test "refresh - with no current context the reading is cleared and no probe runs" {
  # Arrange
  kubeconfig 'contexts:' '- name: staging'
  cached "old|ns"
  option dangling 1

  # Act
  lib_run kube 'KUBE_REVAMPED_S_probe_reach=1; kube_revamped_refresh'

  # Assert
  holds value ""
  holds dangling ""
  run asked
  [[ -z "${output}" ]]
}

@test "refresh - when tmux takes no write the reading is reported as not stored and no probe runs" {
  # Arrange
  two_contexts
  : >"${FAKE}/refused"

  # Act
  lib_run kube 'KUBE_REVAMPED_S_probe_reach=1; kube_revamped_refresh; printf "[%s]" "${KUBE_REVAMPED_STORED}"'

  # Assert
  [[ "${output}" == "[0]" ]]
  run asked
  [[ -z "${output}" ]]
}

@test "refresh - use-context switches kubectl and reads the kubeconfig again" {
  # Arrange
  two_contexts

  # Act
  lib_run kube 'kube_revamped_use_context staging'

  # Assert
  run asked
  [[ "${output}" == "config use-context staging" ]]
  holds value "prod-east|payments"
}

@test "refresh - use-namespace sets the namespace of the current context" {
  # Arrange
  two_contexts

  # Act
  lib_run kube 'kube_revamped_use_namespace team-a'

  # Assert
  run asked
  [[ "${output}" == "config set-context --current --namespace team-a" ]]
  holds value "prod-east|payments"
}

@test "refresh - a switch kubectl refuses says so, with each hash doubled, and reads nothing" {
  # Arrange
  two_contexts
  : >"${FAKE}/kubectl-fails"

  # Act
  lib_run kube 'kube_revamped_use_context "a#S"; kube_revamped_use_namespace team-a'

  # Assert
  [[ "${status}" -eq 0 ]]
  said "kubectl could not switch to the context a##S"
  said "kubectl could not switch to the namespace team-a"
  holds value ""
}

@test "refresh - a switch without kubectl says it is not installed" {
  # Arrange
  rm -f "${BATS_TEST_TMPDIR}/stubs/kubectl"
  harness_hide kubectl

  # Act
  lib_run kube 'kube_revamped_use_context staging'

  # Assert
  [[ "${status}" -eq 0 ]]
  said "kubectl is not installed"
}
