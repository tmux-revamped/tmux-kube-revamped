#!/usr/bin/env bash

[[ -n "${_KUBE_REVAMPED_CLUSTER_LOADED:-}" ]] && return 0
_KUBE_REVAMPED_CLUSTER_LOADED=1

_KUBE_CLUSTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_KUBE_CLUSTER_DIR}/../tmux/tmux-ops.sh"
# shellcheck source=/dev/null
source "${_KUBE_CLUSTER_DIR}/../utils/cache.sh"

_kubectl() {
  kubectl "$@"
}

KUBE_PROBE_TIMEOUT="${KUBE_PROBE_TIMEOUT:-5}"

_kube_with_timeout() {
  local limit="${1}"
  shift
  (
    set -m
    "$@" &
    local pid=$!
    ( sleep "${limit}"; kill -TERM -- "-${pid}" ) >/dev/null 2>&1 &
    local watcher=$!
    local status=0
    wait "${pid}" || status=$?
    kill -TERM -- "-${watcher}" 2>/dev/null
    exit "${status}"
  ) 2>/dev/null
}

kube_reach_ok() {
  _kube_with_timeout "${KUBE_PROBE_TIMEOUT}" _kubectl cluster-info --request-timeout=2 >/dev/null 2>&1
}

kube_parse_nodes() {
  printf '%s\n' "${1}" | awk 'NF{t++; if($2=="Ready")r++} END{print r+0"/"t+0}'
}

kube_nodes_state() {
  local out
  out="$(_kube_with_timeout "${KUBE_PROBE_TIMEOUT}" _kubectl get nodes --no-headers --request-timeout=2 2>/dev/null)" || return 0
  [[ -z "${out}" ]] && return 0
  kube_parse_nodes "${out}"
}

kube_parse_pods() {
  printf '%s\n' "${1}" | awk 'NF{ if($3!="Running" && $3!="Completed") b++ } END{print b+0}'
}

kube_pods_state() {
  local out
  out="$(_kube_with_timeout "${KUBE_PROBE_TIMEOUT}" _kubectl get pods --no-headers --request-timeout=2 2>/dev/null)" || return 0
  [[ -z "${out}" ]] && return 0
  kube_parse_pods "${out}"
}

kube_list_namespaces() {
  _kubectl get namespaces -o name --request-timeout=2 2>/dev/null | sed 's#^namespace/##'
}

kube_apply_context() {
  [[ -z "${1}" ]] && return 1
  _kubectl config use-context "${1}" >/dev/null 2>&1
}

kube_apply_namespace() {
  [[ -z "${1}" ]] && return 1
  _kubectl config set-context --current --namespace "${1}" >/dev/null 2>&1
}

kube_probe_all() {
  if [[ "$(get_tmux_option "@kube_revamped_probe_reach" "0")" == "1" ]]; then
    if kube_reach_ok; then
      cache_set reach "up"
    else
      cache_set reach "down"
    fi
  fi
  if [[ "$(get_tmux_option "@kube_revamped_probe_nodes" "0")" == "1" ]]; then
    cache_set nodes "$(kube_nodes_state)"
  fi
  if [[ "$(get_tmux_option "@kube_revamped_probe_pods" "0")" == "1" ]]; then
    cache_set pods "$(kube_pods_state)"
  fi
}

kube_health_segment() {
  local out="" reach nodes pods warn ndr ndt
  warn="$(get_tmux_option "@kube_revamped_warn_color" "#[fg=yellow]")"

  if [[ "$(get_tmux_option "@kube_revamped_probe_reach" "0")" == "1" ]]; then
    reach="$(cache_get reach)"
    if [[ "${reach}" == "up" ]]; then
      out="${out} #[fg=green]o#[default]"
    elif [[ "${reach}" == "down" ]]; then
      out="${out} #[fg=red]x#[default]"
    fi
  fi

  if [[ "$(get_tmux_option "@kube_revamped_probe_nodes" "0")" == "1" ]]; then
    nodes="$(cache_get nodes)"
    if [[ -n "${nodes}" ]]; then
      ndr="${nodes%%/*}"
      ndt="${nodes#*/}"
      if [[ "${ndr}" == "${ndt}" ]]; then
        out="${out} #[fg=green]${nodes}#[default]"
      else
        out="${out} ${warn}${nodes}#[default]"
      fi
    fi
  fi

  if [[ "$(get_tmux_option "@kube_revamped_probe_pods" "0")" == "1" ]]; then
    pods="$(cache_get pods)"
    if [[ -n "${pods}" && "${pods}" != "0" ]]; then
      out="${out} ${warn}!${pods}#[default]"
    fi
  fi

  printf '%s' "${out}"
}

export -f _kubectl
export -f _kube_with_timeout
export -f kube_reach_ok
export -f kube_parse_nodes
export -f kube_nodes_state
export -f kube_parse_pods
export -f kube_pods_state
export -f kube_list_namespaces
export -f kube_apply_context
export -f kube_apply_namespace
export -f kube_probe_all
export -f kube_health_segment
