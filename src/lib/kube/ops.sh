#!/usr/bin/env bash

[[ -n "${_KUBE_REVAMPED_OPS_LOADED:-}" ]] && return 0
_KUBE_REVAMPED_OPS_LOADED=1

_KUBE_OPS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_KUBE_OPS_DIR}/../tmux/tmux-ops.sh"
# shellcheck source=/dev/null
source "${_KUBE_OPS_DIR}/../utils/cache.sh"
# shellcheck source=/dev/null
source "${_KUBE_OPS_DIR}/../utils/has-command.sh"
# shellcheck source=/dev/null
source "${_KUBE_OPS_DIR}/kube.sh"
# shellcheck source=/dev/null
source "${_KUBE_OPS_DIR}/cluster.sh"

_tmux() {
  tmux "$@"
}

kube_parse_version() {
  printf '%s\n' "${1}" | sed -En 's/^tmux[ -]([a-z]+-)?([0-9]+\.[0-9]+).*/\2/p'
}

kube_version_ge() {
  [[ -n "${1}" && -n "${2}" ]] || return 1
  [ "$(printf '%s\n%s\n' "${2}" "${1}" | sort -V | head -n1)" = "${2}" ]
}

_kube_tmux_version_string() {
  tmux -V 2>/dev/null
}

kube_tmux_version() {
  kube_parse_version "$(_kube_tmux_version_string)"
}

_kube_hash_escape() {
  local hash="#"
  printf '%s' "${1//"${hash}"/${hash}${hash}}"
}

_kube_shell_words() {
  local out="" word
  for word in "$@"; do
    out="${out:+${out} }$(printf '%q' "${word}")"
  done
  printf '%s' "${out}"
}

_kube_tmux_quote() {
  local quote="'" escaped="'\\''"
  printf "'%s'" "${1//"${quote}"/${escaped}}"
}

_kube_run_shell_command() {
  _kube_hash_escape "run-shell $(_kube_tmux_quote "$(_kube_hash_escape "$(_kube_shell_words "$@")")")"
}

kube_menu_context() {
  local self="${1}" yaml name
  yaml="$(_kube_config_text)"
  local args=(display-menu -T "Context")
  while IFS= read -r name; do
    args+=("$(_kube_hash_escape "${name}")" "" "$(_kube_run_shell_command "${self}" use-context "${name}")")
  done < <(kube_list_contexts "${yaml}")
  [[ ${#args[@]} -le 3 ]] && return 0
  _tmux "${args[@]}"
}

kube_menu_namespace() {
  local self="${1}" name
  local args=(display-menu -T "Namespace")
  while IFS= read -r name; do
    [[ -z "${name}" ]] && continue
    args+=("$(_kube_hash_escape "${name}")" "" "$(_kube_run_shell_command "${self}" use-namespace "${name}")")
  done < <(kube_list_namespaces)
  [[ ${#args[@]} -le 3 ]] && return 0
  _tmux "${args[@]}"
}

kube_popup() {
  local cached ctx ns width height cmd full
  kube_version_ge "$(kube_tmux_version)" 3.2 || return 0
  cached="$(cache_get value)"
  ns=""
  [[ "${cached}" == *"|"* ]] && ns="${cached#*|}"
  ctx="${cached%%|*}"
  [[ -z "${ctx}" ]] && return 0
  width="$(get_tmux_option "@kube_revamped_popup_width" "80%")"
  height="$(get_tmux_option "@kube_revamped_popup_height" "80%")"
  cmd="$(get_tmux_option "@kube_revamped_popup_command" "k9s")"
  full="${cmd} --context $(printf '%q' "${ctx}")"
  [[ -n "${ns}" ]] && full="${full} --namespace $(printf '%q' "${ns}")"
  _tmux display-popup -E -w "${width}" -h "${height}" "${full}"
}

kube_apply_keys() {
  local self="${1}" k_ctx k_ns k_pop
  k_ctx="$(get_tmux_option "@kube_revamped_menu_context_key" "M-k")"
  [[ "${k_ctx}" == "off" ]] && k_ctx=""
  k_ns="$(get_tmux_option "@kube_revamped_menu_namespace_key" "")"
  k_pop="$(get_tmux_option "@kube_revamped_popup_key" "")"
  [[ -n "${k_ctx}" ]] && _tmux bind-key "${k_ctx}" run-shell "$(_kube_hash_escape "$(_kube_shell_words "${self}" menu-context)")"
  [[ -n "${k_ns}" ]] && _tmux bind-key "${k_ns}" run-shell "$(_kube_hash_escape "$(_kube_shell_words "${self}" menu-namespace)")"
  [[ -n "${k_pop}" ]] && _tmux bind-key "${k_pop}" run-shell "$(_kube_hash_escape "$(_kube_shell_words "${self}" popup)")"
  return 0
}

kube_doctor() {
  local yaml ctx f
  echo "tmux-kube-revamped doctor"
  if has_command kubectl; then
    echo "kubectl: found"
  else
    echo "kubectl: not found (not required for context/namespace)"
  fi
  if has_command k9s; then
    echo "k9s: found"
  else
    echo "k9s: not found (popup disabled)"
  fi
  echo "kubeconfig files:"
  while IFS= read -r f; do
    if [[ -r "${f}" ]]; then
      echo "  ${f} (readable)"
    else
      echo "  ${f} (missing)"
    fi
  done < <(_kube_config_files)
  yaml="$(_kube_config_text)"
  ctx="$(kube_current_context "${yaml}")"
  if [[ -z "${ctx}" ]]; then
    echo "current-context: (none)"
  elif kube_context_exists "${yaml}" "${ctx}"; then
    echo "current-context: ${ctx}"
  else
    echo "current-context: ${ctx} (DANGLING: not in kubeconfig)"
  fi
}

export -f _tmux
export -f _kube_hash_escape
export -f _kube_shell_words
export -f _kube_tmux_quote
export -f _kube_run_shell_command
export -f kube_parse_version
export -f kube_version_ge
export -f _kube_tmux_version_string
export -f kube_tmux_version
export -f kube_menu_context
export -f kube_menu_namespace
export -f kube_popup
export -f kube_apply_keys
export -f kube_doctor
