#!/usr/bin/env bash

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_KUBE_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/kube.sh"

export CACHE_PREFIX="kube_revamped"

# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/tmux/tmux-ops.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/utils/cache.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/kube/kube.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/kube/cluster.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/kube/render.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/kube/ops.sh"

kube_max_age() {
  local s
  s=$(get_tmux_option "@kube_revamped_interval" "10")
  [[ "${s}" =~ ^[0-9]+$ ]] || s=10
  echo "${s}"
}

kube_refresh() {
  local yaml ctx ns dangling cluster user
  yaml="$(_kube_config_text)"
  ctx="$(kube_current_context "${yaml}")"
  if [[ -z "${ctx}" ]]; then
    cache_set value ""
    cache_set dangling ""
    cache_set cluster ""
    cache_set user ""
    return 0
  fi
  if kube_context_exists "${yaml}" "${ctx}"; then
    dangling=""
    ns="$(kube_namespace_for "${yaml}" "${ctx}")"
    cluster="$(kube_cluster_for "${yaml}" "${ctx}")"
    user="$(kube_user_for "${yaml}" "${ctx}")"
  else
    dangling="1"
    ns=""
    cluster=""
    user=""
  fi
  cache_set value "${ctx}|${ns}"
  cache_set dangling "${dangling}"
  cache_set cluster "${cluster}"
  cache_set user "${user}"
  kube_probe_all
}

kube_render() {
  local cached="${1}" ctx ns seg health
  [[ -z "${cached}" ]] && return 0
  ctx="${cached%%|*}"
  ns=""
  [[ "${cached}" == *"|"* ]] && ns="${cached#*|}"
  seg="$(kube_render_segment "${ctx}" "${ns}" "$(cache_get dangling)" "$(cache_get cluster)" "$(cache_get user)")"
  [[ -z "${seg}" ]] && return 0
  health="$(kube_health_segment)"
  printf '%s%s\n' "${seg}" "${health}"
}

kube_use_context() {
  kube_apply_context "${1}" || return 0
  kube_refresh
}

kube_use_namespace() {
  kube_apply_namespace "${1}" || return 0
  kube_refresh
}

main() {
  local cmd="${1:-}"

  case "${cmd}" in
    refresh)        kube_refresh; return 0 ;;
    doctor)         kube_doctor; return 0 ;;
    bind-keys)      kube_apply_keys "${_KUBE_SELF}"; return 0 ;;
    use-context)    kube_use_context "${2:-}"; return 0 ;;
    use-namespace)  kube_use_namespace "${2:-}"; return 0 ;;
    menu-context)   kube_menu_context "${_KUBE_SELF}"; return 0 ;;
    menu-namespace) kube_menu_namespace "${_KUBE_SELF}"; return 0 ;;
    popup)          kube_popup; return 0 ;;
  esac

  cache_refresh_if_stale value "$(kube_max_age)" kube_refresh

  local cached
  cached="$(cache_get value)"
  case "${cmd}" in
    kube)      kube_render "${cached}" ;;
    context)   echo "${cached%%|*}" ;;
    namespace) [[ "${cached}" == *"|"* ]] && echo "${cached#*|}" ;;
    *)         return 0 ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
