#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/kube_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/kube_helpers.bash"

summary() {
  lib_run kube "${1:-}"'kube_revamped_read summary | tr "\n" "|"'
}

segment() {
  lib_run kube "$1"'; kube_revamped_segment; printf "[%s]\n" "${KUBE_REVAMPED_SEGMENT}"'
}

health() {
  lib_run kube "$1"'; kube_revamped_health; printf "[%s]\n" "${KUBE_REVAMPED_HEALTH}"'
}

@test "kube - every hash in a name is doubled, and a name without one is left alone" {
  # Arrange
  local script='for given in "a#b##c" plain "" "#"; do kube_revamped_doubled "${given}"; printf "[%s]" "${KUBE_REVAMPED_DOUBLED}"; done'

  # Act
  lib_run kube "${script}"

  # Assert
  [[ "${output}" == "[a##b####c][plain][][##]" ]]
}

@test "kube - the reader answers the current context with its namespace, cluster and user" {
  # Arrange
  two_contexts

  # Act
  summary

  # Assert
  [[ "${output}" == "prod-east|1|payments|c1|alice|" ]]
}

@test "kube - a context without a namespace is in the namespace default" {
  # Arrange
  kubeconfig 'current-context: staging' 'contexts:' '- name: staging' '  context:' '    cluster: c2'

  # Act
  summary

  # Assert
  [[ "${output}" == "staging|1|default|c2||" ]]
}

@test "kube - a current context the kubeconfig does not list is reported as not found" {
  # Arrange
  kubeconfig 'current-context: ghost' 'contexts:' '- name: staging' '  context:' '    cluster: c2'

  # Act
  summary

  # Assert
  [[ "${output}" == "ghost|0||||" ]]
}

@test "kube - quotes are dropped, and neither a nested list nor a remark starts a context" {
  # Arrange
  kubeconfig 'apiVersion: v1' 'current-context: "dev#S"' 'contexts:' '- context:' '    cluster: "c 1"' '    namespace: pay' '  name: prod-east' "- name: 'dev#S'" '  context:' '    cluster: c2' '    user: "bob"' '# a remark' '  - name: nested' '- context:' '    cluster: c3' '    extensions:' '    - name: inner' '      extension:' '        cluster: wrong' '  name: staging' 'kind: Config' 'users:' '- name: alice'

  # Act
  lib_run kube 'kube_revamped_read summary | tr "\n" "|"; printf "\n"; kube_revamped_read list | tr "\n" "|"'

  # Assert
  [[ "${lines[0]}" == "dev#S|1|default|c2|bob|" ]]
  [[ "${lines[1]}" == "prod-east|dev#S|staging|" ]]
}

@test "kube - with several files the first current context wins and every file's contexts are read" {
  # Arrange
  mkdir -p "${BATS_TEST_TMPDIR}/more"
  printf 'current-context:   \ncontexts: []\n' >"${BATS_TEST_TMPDIR}/more/empty"
  printf 'current-context: other\ncontexts:\n  - name: other\n    context:\n      cluster: cb\n      namespace: nsb' >"${BATS_TEST_TMPDIR}/more/second"
  two_contexts
  local script='cd "'"${BATS_TEST_TMPDIR}"'/more" || exit 1; KUBECONFIG="/nowhere/absent:empty::second:'"${KUBECONFIG}"':'"${BATS_TEST_TMPDIR}"'/more"; kube_revamped_read summary | tr "\n" "|"; printf "\n"; kube_revamped_read list | tr "\n" "|"'

  # Act
  lib_run kube "${script}"

  # Assert
  [[ "${lines[0]}" == "other|1|nsb|cb||" ]]
  [[ "${lines[1]}" == "other|prod-east|staging|" ]]
}

@test "kube - with no file to read the reader answers an empty context" {
  # Arrange
  local script='KUBECONFIG="'"${BATS_TEST_TMPDIR}"'/absent"; kube_revamped_read summary | tr "\n" "|"; printf "\n[%s]\n" "$(kube_revamped_read list)"'

  # Act
  lib_run kube "${script}"

  # Assert
  [[ "${lines[0]}" == "|0||||" ]]
  [[ "${lines[1]}" == "[]" ]]
}

@test "kube - without KUBECONFIG the reader takes the config under the home folder" {
  # Arrange
  mkdir -p "${HOME}/.kube"
  printf 'current-context: home\ncontexts:\n- name: home\n' >"${HOME}/.kube/config"

  # Act
  summary 'unset KUBECONFIG; '

  # Assert
  [[ "${output}" == "home|1|default|||" ]]
}

@test "kube - inspect keeps the reading in the globals the refresh writes" {
  # Arrange
  two_contexts
  local script='kube_revamped_inspect; printf "%s|%s|%s|%s|%s\n" "${KUBE_REVAMPED_CONTEXT}" "${KUBE_REVAMPED_FOUND}" "${KUBE_REVAMPED_NAMESPACE}" "${KUBE_REVAMPED_CLUSTER}" "${KUBE_REVAMPED_USER}"'

  # Act
  lib_run kube "${script}"

  # Assert
  [[ "${output}" == "prod-east|1|payments|c1|alice" ]]
}

@test "kube - the segment is the context and its namespace in the segment's colour" {
  # Arrange
  local given='KUBE_REVAMPED_CONTEXT=prod KUBE_REVAMPED_NAMESPACE=pay'

  # Act
  segment "${given}"

  # Assert
  [[ "${output}" == "[#[fg=blue]prod:pay#[default]]" ]]
}

@test "kube - the icon, the cluster and the user join the segment when they are on" {
  # Arrange
  local given='KUBE_REVAMPED_CONTEXT=prod KUBE_REVAMPED_NAMESPACE=pay KUBE_REVAMPED_S_cluster=c1 KUBE_REVAMPED_S_user=alice KUBE_REVAMPED_S_show_cluster=1 KUBE_REVAMPED_S_show_user=1 KUBE_REVAMPED_S_icon=K'

  # Act
  segment "${given}"

  # Assert
  [[ "${output}" == "[#[fg=blue]K prod@c1:pay (alice)#[default]]" ]]
}

@test "kube - a part that is off or empty stays out of the segment" {
  # Arrange
  local given='KUBE_REVAMPED_CONTEXT=prod KUBE_REVAMPED_NAMESPACE=pay KUBE_REVAMPED_S_show_namespace=0 KUBE_REVAMPED_S_show_cluster=1 KUBE_REVAMPED_S_show_user=1'

  # Act
  segment "${given}"

  # Assert
  [[ "${output}" == "[#[fg=blue]prod#[default]]" ]]
}

@test "kube - a context the kubeconfig lacks takes the warning colour and mark" {
  # Arrange
  local given='KUBE_REVAMPED_CONTEXT=ghost KUBE_REVAMPED_NAMESPACE="" KUBE_REVAMPED_S_dangling=1 KUBE_REVAMPED_S_warn_icon="!!"'

  # Act
  segment "${given}"

  # Assert
  [[ "${output}" == "[#[fg=yellow]ghost !!#[default]]" ]]
}

@test "kube - a context holding the production text takes the production colour, and no other does" {
  # Arrange
  local script='KUBE_REVAMPED_S_prod_pattern=prod KUBE_REVAMPED_NAMESPACE=pay; for KUBE_REVAMPED_CONTEXT in eu-prod-1 staging; do kube_revamped_segment; printf "[%s]\n" "${KUBE_REVAMPED_SEGMENT}"; done'

  # Act
  lib_run kube "${script}"

  # Assert
  [[ "${lines[0]}" == "[#[fg=red]eu-prod-1:pay#[default]]" ]]
  [[ "${lines[1]}" == "[#[fg=blue]staging:pay#[default]]" ]]
}

@test "kube - hide_default hides only the context named default, and no context gives no segment" {
  # Arrange
  local script='KUBE_REVAMPED_S_hide_default=1 KUBE_REVAMPED_NAMESPACE=""; for KUBE_REVAMPED_CONTEXT in default other ""; do kube_revamped_segment; printf "[%s]\n" "${KUBE_REVAMPED_SEGMENT}"; done'

  # Act
  lib_run kube "${script}"

  # Assert
  [[ "${lines[0]}" == "[]" ]]
  [[ "${lines[1]}" == "[#[fg=blue]other#[default]]" ]]
  [[ "${lines[2]}" == "[]" ]]
}

@test "kube - a hash in any name is doubled in the segment, since tmux expands a job's output" {
  # Arrange
  local given='KUBE_REVAMPED_CONTEXT="a#S" KUBE_REVAMPED_NAMESPACE="n#1" KUBE_REVAMPED_S_cluster="c#" KUBE_REVAMPED_S_user="u#" KUBE_REVAMPED_S_show_cluster=1 KUBE_REVAMPED_S_show_user=1'

  # Act
  segment "${given}"

  # Assert
  [[ "${output}" == "[#[fg=blue]a##S@c##:n##1 (u##)#[default]]" ]]
}

@test "kube - the reach probe shows o when the cluster answers, x when it does not and nothing before it ran" {
  # Arrange
  local script='KUBE_REVAMPED_S_probe_reach=1; for KUBE_REVAMPED_S_reach in up down ""; do kube_revamped_health; printf "[%s]\n" "${KUBE_REVAMPED_HEALTH}"; done'

  # Act
  lib_run kube "${script}"

  # Assert
  [[ "${lines[0]}" == "[ #[fg=green]o#[default]]" ]]
  [[ "${lines[1]}" == "[ #[fg=red]x#[default]]" ]]
  [[ "${lines[2]}" == "[]" ]]
}

@test "kube - the node count is green when every node is ready and in the warning colour otherwise" {
  # Arrange
  local script='KUBE_REVAMPED_S_probe_nodes=1; for KUBE_REVAMPED_S_nodes in 3/3 2/3 ""; do kube_revamped_health; printf "[%s]\n" "${KUBE_REVAMPED_HEALTH}"; done'

  # Act
  lib_run kube "${script}"

  # Assert
  [[ "${lines[0]}" == "[ #[fg=green]3/3#[default]]" ]]
  [[ "${lines[1]}" == "[ #[fg=yellow]2/3#[default]]" ]]
  [[ "${lines[2]}" == "[]" ]]
}

@test "kube - failing pods are counted in the warning colour, and none shows nothing" {
  # Arrange
  local script='KUBE_REVAMPED_S_probe_pods=1; for KUBE_REVAMPED_S_pods in 4 0 ""; do kube_revamped_health; printf "[%s]\n" "${KUBE_REVAMPED_HEALTH}"; done'

  # Act
  lib_run kube "${script}"

  # Assert
  [[ "${lines[0]}" == "[ #[fg=yellow]!4#[default]]" ]]
  [[ "${lines[1]}" == "[]" ]]
  [[ "${lines[2]}" == "[]" ]]
}

@test "kube - a probe that is off shows nothing, whatever its last reading was" {
  # Arrange
  local given='KUBE_REVAMPED_S_reach=up KUBE_REVAMPED_S_nodes=1/2 KUBE_REVAMPED_S_pods=3'

  # Act
  health "${given}"

  # Assert
  [[ "${output}" == "[]" ]]
}

@test "kube - each placeholder prints its part of the stored reading" {
  # Arrange
  local script='KUBE_REVAMPED_S_value="a#1|pay" KUBE_REVAMPED_S_probe_pods=1 KUBE_REVAMPED_S_pods=2; kube_revamped_show context; kube_revamped_show namespace; kube_revamped_show kube'

  # Act
  lib_run kube "${script}"

  # Assert
  [[ "${lines[0]}" == "a##1" ]]
  [[ "${lines[1]}" == "pay" ]]
  [[ "${lines[2]}" == "#[fg=blue]a##1:pay#[default] #[fg=yellow]!2#[default]" ]]
}

@test "kube - with no stored reading every placeholder prints nothing" {
  # Arrange
  local script='KUBE_REVAMPED_S_value=""; kube_revamped_show context; kube_revamped_show namespace; kube_revamped_show kube; printf "end\n"'

  # Act
  lib_run kube "${script}"

  # Assert
  [[ "${output}" == "end" ]]
}

@test "kube - a tmux version is read out of its banner and compared part by part" {
  # Arrange
  local script='for banner in "tmux 3.6a" "tmux next-3.7" "nonsense"; do printf "[%s]" "$(kube_revamped_parse_version "${banner}")"; done; for pair in "3.6 3.2" "3.2 3.2" "3.1 3.2" "4.0 3.2" "2.9 3.2" " 3.2" "x 3.2"; do if kube_revamped_version_ge ${pair}; then printf y; else printf n; fi; done'

  # Act
  lib_run kube "${script}"

  # Assert
  [[ "${output}" == "[3.6][3.7][]yynynnn" ]]
}
