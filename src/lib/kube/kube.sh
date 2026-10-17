#!/usr/bin/env bash
#
# kube.sh: read the current Kubernetes context and namespace from the kubeconfig.
#
# Parsing is pure. The file read sits behind a seam the tests override, so no real
# kubeconfig is touched under test. Reading the config directly means the plugin
# works without kubectl installed and never forks a kubectl process on refresh.

[[ -n "${_KUBE_REVAMPED_LOADED:-}" ]] && return 0
_KUBE_REVAMPED_LOADED=1

# kube_current_context YAML -> the value of the top-level current-context key,
# empty when absent. Quotes around the value are stripped. When the merged text
# holds several current-context lines (one per KUBECONFIG file), the last
# non-empty value wins, matching how a colon-separated KUBECONFIG is resolved.
kube_current_context() {
  printf '%s\n' "${1}" | awk -v q="'" '
    /^current-context:/ {
      v = $0
      sub(/^current-context:[[:space:]]*/, "", v)
      sub(/[[:space:]]+$/, "", v)
      f = substr(v, 1, 1)
      if (length(v) >= 2 && (f == "\"" || f == q) && substr(v, length(v), 1) == f) v = substr(v, 2, length(v) - 2)
      if (v != "") { print v; exit }
    }'
}

# kube_namespace_for YAML CONTEXT -> the namespace of CONTEXT, "default" when the
# context has none, empty when the context is not found. Reads the kubectl layout
# where each contexts entry has a context block (with namespace) then a name.
kube_namespace_for() {
  _kube_context_field "${1}" "${2}" namespace
}

# kube_cluster_for YAML CONTEXT -> the cluster name bound to CONTEXT, empty when
# the context is not found or declares no cluster.
kube_cluster_for() {
  _kube_context_field "${1}" "${2}" cluster
}

# kube_user_for YAML CONTEXT -> the user name bound to CONTEXT, empty when the
# context is not found or declares no user.
kube_user_for() {
  _kube_context_field "${1}" "${2}" user
}

# kube_list_contexts YAML -> every context name, one per line, in file order.
kube_list_contexts() {
  local sep=$'\x1f' name rest
  while IFS="${sep}" read -r name rest; do
    [[ -n "${name}" ]] && printf '%s\n' "${name}"
  done < <(_kube_context_records "${1}")
  return 0
}

_kube_context_field() {
  local sep=$'\x1f' name cluster namespace user
  while IFS="${sep}" read -r name cluster namespace user; do
    [[ "${name}" == "${2}" ]] || continue
    case "${3}" in
      cluster) printf '%s\n' "${cluster}" ;;
      namespace) printf '%s\n' "${namespace:-default}" ;;
      user) printf '%s\n' "${user}" ;;
    esac
    return 0
  done < <(_kube_context_records "${1}")
  return 0
}

_kube_context_records() {
  printf '%s\n' "${1}" | awk -v sep=$'\x1f' -v q="'" '
    function unq(v, f) {
      sub(/^[[:space:]]+/, "", v); sub(/[[:space:]]+$/, "", v)
      f = substr(v, 1, 1)
      if (length(v) >= 2 && (f == "\"" || f == q) && substr(v, length(v), 1) == f) v = substr(v, 2, length(v) - 2)
      return v
    }
    function flush() {
      if (ent) print name sep cl sep ns sep us
      ent = 0; name = ""; cl = ""; ns = ""; us = ""; inctx = 0; eind = -1; cind = -1
    }
    /^contexts:/ { flush(); inc = 1; dash = -1; next }
    inc && /^[^[:space:]#-]/ { flush(); inc = 0 }
    !inc { next }
    {
      line = $0; ind = match(line, /[^ ]/) - 1
      if (ind < 0) next
      nx = substr(line, ind + 2, 1)
      if (substr(line, ind + 1, 1) == "-" && (nx == " " || nx == "")) {
        if (dash < 0) dash = ind
        if (ind == dash) { flush(); ent = 1; line = substr(line, 1, ind) " " substr(line, ind + 2); ind = match(line, /[^ ]/) - 1 }
      }
      if (!ent || ind < 0 || !match(substr(line, ind + 1), /^[A-Za-z_-]+:/)) next
      key = substr(line, ind + 1, RLENGTH - 1); rest = substr(line, ind + RLENGTH + 1)
      if (eind < 0) eind = ind
      if (ind == eind) { inctx = (key == "context"); cind = -1; if (key == "name") name = unq(rest); next }
      if (!inctx || ind < eind) next
      if (cind < 0) cind = ind
      if (ind != cind) next
      if (key == "cluster") cl = unq(rest); else if (key == "namespace") ns = unq(rest); else if (key == "user") us = unq(rest)
    }
    END { flush() }'
}

# kube_context_exists YAML NAME -> 0 when NAME is one of the kubeconfig contexts.
# A current-context that fails this check is dangling: it points at a context the
# merged kubeconfig no longer defines, the classic stale-context-after-VPN case.
kube_context_exists() {
  [[ -z "${2}" ]] && return 1
  kube_list_contexts "${1}" | grep -qxF -- "${2}"
}

# _kube_config_files -> one kubeconfig path per line. Honors the full KUBECONFIG
# colon-separated list, falling back to ~/.kube/config when it is unset. This is
# a seam: tests point it at fixture files instead of a real kubeconfig.
_kube_config_files() {
  local list="${KUBECONFIG:-${HOME}/.kube/config}"
  local f
  local IFS=':'
  for f in ${list}; do
    [[ -n "${f}" ]] && printf '%s\n' "${f}"
  done
}

# _kube_config_text -> the merged text of every kubeconfig file, newline-joined so
# a context block in one file never runs into the next. Host-probe seam: tests
# override it. Reading every file means a context defined only in a later
# KUBECONFIG entry is still seen, instead of silently showing the first file.
_kube_config_text() {
  local f
  while IFS= read -r f; do
    cat "${f}" 2>/dev/null
    printf '\n'
  done < <(_kube_config_files)
}

export -f kube_current_context
export -f kube_namespace_for
export -f kube_cluster_for
export -f kube_user_for
export -f kube_list_contexts
export -f _kube_context_field
export -f _kube_context_records
export -f kube_context_exists
export -f _kube_config_files
export -f _kube_config_text
