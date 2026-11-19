#!/bin/sh

[ -n "${KUBE_REVAMPED_KUBE_LOADED:-}" ] && return 0
KUBE_REVAMPED_KUBE_LOADED=1

# shellcheck source=SCRIPTDIR/state.sh
. "${REVAMPED_LIB:?}/state.sh"
# shellcheck source=SCRIPTDIR/command.sh
. "${REVAMPED_LIB}/command.sh"
# shellcheck source=SCRIPTDIR/cache.sh
. "${REVAMPED_LIB}/cache.sh"

kube_revamped_format() {
  printf '%s\n' "${KUBE_REVAMPED_SETTINGS}" | awk -F '\t' -v live="${KUBE_REVAMPED_LIVE}" '{ printf "%s#{@kube_revamped_%s}", (NR > 1 ? "\t" : ""), $1 } END { count = split(live, name, " "); for (i = 1; i <= count; i++) { printf "\t#{@kube_revamped_%s}", name[i] } }'
}

kube_revamped_resolve() {
  env | KUBE_REVAMPED_ROWS="${KUBE_REVAMPED_SETTINGS}" KUBE_REVAMPED_VALUES="$1" awk -v live="${KUBE_REVAMPED_LIVE}" '
    BEGIN {
      count = split(ENVIRON["KUBE_REVAMPED_ROWS"], rows, "\n")
      split(ENVIRON["KUBE_REVAMPED_VALUES"], given, "\t")
      for (i = 1; i <= count; i++) {
        at = index(rows[i], "\t")
        if (at == 0) { at = length(rows[i]) + 1 }
        name[i] = substr(rows[i], 1, at - 1)
        value[i] = (given[i] != "") ? given[i] : substr(rows[i], at + 1)
        want["KUBE_REVAMPED_" toupper(name[i])] = i
      }
    }
    {
      at = index($0, "=")
      key = substr($0, 1, at - 1)
      if (key in want) { value[want[key]] = substr($0, at + 1) }
    }
    END {
      for (i = 1; i <= count; i++) { print name[i] "\t" value[i] }
      extra = split(live, state, " ")
      for (i = 1; i <= extra; i++) { print state[i] "\t" given[count + i] }
    }
  '
}

kube_revamped_load() {
  kube_revamped_load_format=$(kube_revamped_format)
  kube_revamped_load_live=$(tmux display-message -p "${kube_revamped_load_format}" 2>/dev/null) || kube_revamped_load_live=""
  kube_revamped_load_values=$(kube_revamped_resolve "${kube_revamped_load_live}")
  while IFS='	' read -r kube_revamped_load_name kube_revamped_load_value; do
    IFS= read -r "KUBE_REVAMPED_S_${kube_revamped_load_name}" <<EOF
${kube_revamped_load_value}
EOF
  done <<EOF
${kube_revamped_load_values}
EOF
}

kube_revamped_parse_version() {
  printf '%s\n' "$1" | sed -En 's/^tmux[ -]([a-z]+-)?([0-9]+\.[0-9]+).*/\2/p'
}

kube_revamped_version_ge() {
  case "$1:$2" in
  *[!0-9.:]* | :* | *:) return 1 ;;
  *) ;;
  esac
  kube_revamped_version_ge_have="${1%%.*}"
  kube_revamped_version_ge_want="${2%%.*}"
  [ "${kube_revamped_version_ge_have}" -gt "${kube_revamped_version_ge_want}" ] && return 0
  [ "${kube_revamped_version_ge_have}" -eq "${kube_revamped_version_ge_want}" ] || return 1
  kube_revamped_version_ge_have="${1#*.}"
  kube_revamped_version_ge_want="${2#*.}"
  [ "${kube_revamped_version_ge_have%%.*}" -ge "${kube_revamped_version_ge_want%%.*}" ]
}

kube_revamped_emit() {
  for kube_revamped_emit_arg in "$@"; do
    case "${kube_revamped_emit_arg}" in
    *\;) kube_revamped_emit_arg="${kube_revamped_emit_arg%;}\\;" ;;
    *) ;;
    esac
    KUBE_REVAMPED_PLAN="${KUBE_REVAMPED_PLAN}${kube_revamped_emit_arg:-${KUBE_REVAMPED_EMPTY}}
"
  done
  KUBE_REVAMPED_PLAN="${KUBE_REVAMPED_PLAN}
"
}

kube_revamped_literal() {
  printf '%s\n' "$1" | sed -e "s/'/'\\\\''/g" -e "s/#/'\"\$(printf '%b' '\\\\0043')\"'/g" -e "1s/^/'/" -e "\$s/\$/'/"
}

kube_revamped_tmux_string() {
  printf '%s\n' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\$/\\$/g'
}

kube_revamped_send() {
  set --
  kube_revamped_send_sep=""
  while IFS= read -r kube_revamped_send_line; do
    if [ -z "${kube_revamped_send_line}" ]; then
      [ "$#" -eq 0 ] || kube_revamped_send_sep=";"
      continue
    fi
    [ -z "${kube_revamped_send_sep}" ] || set -- "$@" "${kube_revamped_send_sep}"
    kube_revamped_send_sep=""
    [ "${kube_revamped_send_line}" != "${KUBE_REVAMPED_EMPTY}" ] || kube_revamped_send_line=""
    set -- "$@" "${kube_revamped_send_line}"
  done <<PLAN
${KUBE_REVAMPED_PLAN}
PLAN
  [ "$#" -gt 0 ] || return 0
  tmux "$@" 2>/dev/null
}

kube_revamped_send_each() {
  kube_revamped_send_each_status=0
  set --
  while IFS= read -r kube_revamped_send_each_line; do
    if [ -n "${kube_revamped_send_each_line}" ]; then
      [ "${kube_revamped_send_each_line}" != "${KUBE_REVAMPED_EMPTY}" ] || kube_revamped_send_each_line=""
      set -- "$@" "${kube_revamped_send_each_line}"
      continue
    fi
    [ "$#" -gt 0 ] || continue
    tmux "$@" || kube_revamped_send_each_status=1
    set --
  done <<PLAN
${KUBE_REVAMPED_PLAN}
PLAN
  return "${kube_revamped_send_each_status}"
}

kube_revamped_deliver() {
  ! kube_revamped_send || return 0
  kube_revamped_send_each
}

kube_revamped_lines() {
  printf '%s' "${KUBE_REVAMPED_PLAN}" | awk -v empty="${KUBE_REVAMPED_EMPTY}" '$0 == empty { $0 = "\"\"" } $0 == "" && line != "" { print line; line = ""; next } $0 == "" { next } { line = (line == "" ? $0 : line " " $0) } END { if (line != "") { print line } }'
}

kube_revamped_json() {
  printf '%s' "${KUBE_REVAMPED_PLAN}" | awk -v empty="${KUBE_REVAMPED_EMPTY}" '
    function quote(s,    out, i, c) {
      out = ""
      for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (c == "\\") { out = out "\\\\" } else if (c == "\"") { out = out "\\\"" } else { out = out c }
      }
      return "\"" out "\""
    }
    /^$/ { if (args != "") { rows = rows (rows == "" ? "" : ",") "[" args "]" } args = ""; next }
    $0 == empty { $0 = "" }
    { args = args (args == "" ? "" : ",") quote($0) }
    END {
      if (args != "") { rows = rows (rows == "" ? "" : ",") "[" args "]" }
      print "{\"bindings\":[" rows "]}"
    }
  '
}

kube_revamped_bindings() {
  printf '%s' "${KUBE_REVAMPED_PLAN}" | awk 'previous == "" && $0 == "bind-key" { count++ } { previous = $0 } END { print count + 0 }'
}

kube_revamped_setting_name() {
  kube_revamped_setting_name_raw=$(printf '%s\n' "${1#--}" | tr '-' '_')
  case " ${KUBE_REVAMPED_NAMES} " in
  *" ${kube_revamped_setting_name_raw} "*) printf '%s\n' "${kube_revamped_setting_name_raw}" ;;
  *) printf '\n' ;;
  esac
}

kube_revamped_bind() {
  case "$1" in
  "" | off) return 0 ;;
  *) ;;
  esac
  case " ${KUBE_REVAMPED_BOUND} " in
  *" $1 "*)
    KUBE_REVAMPED_SKIPPED="${KUBE_REVAMPED_SKIPPED}${KUBE_REVAMPED_SKIPPED:+ }$1"
    return 0
    ;;
  *) ;;
  esac
  KUBE_REVAMPED_BOUND="${KUBE_REVAMPED_BOUND} $1"
  kube_revamped_bind_key="$1" kube_revamped_bind_note="$2"
  shift 2
  set -- "${kube_revamped_bind_key}" "$@"
  [ "${KUBE_REVAMPED_NOTES}" != 1 ] || set -- -N "${kube_revamped_bind_note}" "$@"
  kube_revamped_emit bind-key "$@"
}

kube_revamped_job_quote() {
  printf '%s\n' "$1" | sed -e "s/'/'\\\\''/g" -e 's/#/##/g' -e 's/%/%%/g' -e "1s/^/'/" -e "\$s/\$/'/"
}

kube_revamped_carried() {
  kube_revamped_carried_set=$(env | sed -n 's/^KUBE_REVAMPED_\([A-Z_]*\)=\(.*\)$/\1 \2/p')
  [ -n "${kube_revamped_carried_set}" ] || return 0
  printf '%s\n' "${kube_revamped_carried_set}" | KUBE_REVAMPED_WANTED="${KUBE_REVAMPED_CARRIED}" awk '
    BEGIN { count = split(ENVIRON["KUBE_REVAMPED_WANTED"], name, " "); for (i = 1; i <= count; i++) { wanted[toupper(name[i])] = i } }
    {
      key = $1
      if (!(key in wanted)) { next }
      given[wanted[key]] = 1
      value[wanted[key]] = substr($0, length(key) + 2)
    }
    END {
      for (i = 1; i <= count; i++) {
        if (!given[i]) { continue }
        flag = name[i]
        gsub(/_/, "-", flag)
        print flag "\t" value[i]
      }
    }
  '
}

kube_revamped_tools() {
  kube_revamped_tools_path="${REVAMPED_LIB%/lib}/bin/kube-revamped"
  KUBE_REVAMPED_TOOL=$(kube_revamped_literal "${kube_revamped_tools_path}")
  KUBE_REVAMPED_JOB=$(kube_revamped_job_quote "${kube_revamped_tools_path}")
  kube_revamped_tools_rows=$(kube_revamped_carried)
  while IFS='	' read -r kube_revamped_tools_flag kube_revamped_tools_value; do
    [ -n "${kube_revamped_tools_flag}" ] || continue
    KUBE_REVAMPED_TOOL="${KUBE_REVAMPED_TOOL} --${kube_revamped_tools_flag} $(kube_revamped_literal "${kube_revamped_tools_value}")"
    KUBE_REVAMPED_JOB="${KUBE_REVAMPED_JOB} --${kube_revamped_tools_flag} $(kube_revamped_job_quote "${kube_revamped_tools_value}")"
  done <<EOF
${kube_revamped_tools_rows}
EOF
}

kube_revamped_held() {
  tmux list-keys -T prefix 2>/dev/null | awk '
    {
      at = 2
      if ($at == "-r") { at++ }
      if ($at == "-T") { at += 2 }
      key = $at
      if (key ~ /^\\./) { key = substr(key, 2) }
      rest = ""
      for (i = at + 1; i <= NF; i++) { rest = rest " " $i }
      if (index(rest, "kube-revamped") == 0) { printf "%s ", key }
    }
  '
}

kube_revamped_doubled() {
  kube_revamped_doubled_rest="$1" kube_revamped_doubled_hash='#' KUBE_REVAMPED_DOUBLED=""
  while [ "${kube_revamped_doubled_rest}" != "${kube_revamped_doubled_rest#*"${kube_revamped_doubled_hash}"}" ]; do
    KUBE_REVAMPED_DOUBLED="${KUBE_REVAMPED_DOUBLED}${kube_revamped_doubled_rest%%"${kube_revamped_doubled_hash}"*}${kube_revamped_doubled_hash}${kube_revamped_doubled_hash}"
    kube_revamped_doubled_rest="${kube_revamped_doubled_rest#*"${kube_revamped_doubled_hash}"}"
  done
  KUBE_REVAMPED_DOUBLED="${KUBE_REVAMPED_DOUBLED}${kube_revamped_doubled_rest}"
}

kube_revamped_say() {
  kube_revamped_doubled "$1"
  tmux display-message "kube-revamped: ${KUBE_REVAMPED_DOUBLED}" 2>/dev/null || :
}

kube_revamped_now() {
  KUBE_REVAMPED_NOW=$(date +%s 2>/dev/null) || KUBE_REVAMPED_NOW=0
}

kube_revamped_read() {
  kube_revamped_read_mode="$1"
  kube_revamped_read_rest="${KUBECONFIG:-${HOME}/.kube/config}:"
  set --
  while [ -n "${kube_revamped_read_rest}" ]; do
    kube_revamped_read_file="${kube_revamped_read_rest%%:*}"
    kube_revamped_read_rest="${kube_revamped_read_rest#*:}"
    [ -f "${kube_revamped_read_file}" ] || continue
    [ -r "${kube_revamped_read_file}" ] || continue
    case "${kube_revamped_read_file}" in
    /*) set -- "$@" "${kube_revamped_read_file}" ;;
    *) set -- "$@" "./${kube_revamped_read_file}" ;;
    esac
  done
  if [ "$#" -eq 0 ]; then
    awk -v mode="${kube_revamped_read_mode}" -f "${REVAMPED_LIB}/kubeconfig.awk" </dev/null
    return 0
  fi
  awk -v mode="${kube_revamped_read_mode}" -f "${REVAMPED_LIB}/kubeconfig.awk" "$@"
}

kube_revamped_take() {
  IFS= read -r KUBE_REVAMPED_CONTEXT || KUBE_REVAMPED_CONTEXT=""
  IFS= read -r KUBE_REVAMPED_FOUND || KUBE_REVAMPED_FOUND=0
  IFS= read -r KUBE_REVAMPED_NAMESPACE || KUBE_REVAMPED_NAMESPACE=""
  IFS= read -r KUBE_REVAMPED_CLUSTER || KUBE_REVAMPED_CLUSTER=""
  IFS= read -r KUBE_REVAMPED_USER || KUBE_REVAMPED_USER=""
}

kube_revamped_inspect() {
  kube_revamped_inspect_summary=$(kube_revamped_read summary 2>/dev/null) || kube_revamped_inspect_summary=""
  kube_revamped_take <<EOF
${kube_revamped_inspect_summary}
EOF
}

kube_revamped_watch() {
  sleep "${KUBE_REVAMPED_PROBE_LIMIT}" &
  kube_revamped_watch_sleep=$!
  trap 'kill "${kube_revamped_watch_sleep}" 2>/dev/null' TERM
  wait "${kube_revamped_watch_sleep}" || return 0
  kill "$1" 2>/dev/null || :
}

kube_revamped_limited_run() {
  "$@" &
  kube_revamped_limited_run_pid=$!
  kube_revamped_watch "${kube_revamped_limited_run_pid}" >/dev/null 2>&1 &
  kube_revamped_limited_run_watcher=$!
  kube_revamped_limited_run_status=0
  wait "${kube_revamped_limited_run_pid}" || kube_revamped_limited_run_status=$?
  kill "${kube_revamped_limited_run_watcher}" 2>/dev/null || :
  return "${kube_revamped_limited_run_status}"
}

kube_revamped_limited() {
  (kube_revamped_limited_run "$@") 2>/dev/null
}

kube_revamped_reach() {
  kube_revamped_limited kubectl cluster-info --request-timeout=2 >/dev/null
}

kube_revamped_nodes() {
  kube_revamped_nodes_rows=$(kube_revamped_limited kubectl get nodes --no-headers --request-timeout=2) || return 0
  [ -n "${kube_revamped_nodes_rows}" ] || return 0
  printf '%s\n' "${kube_revamped_nodes_rows}" | awk 'NF { total++; if ($2 == "Ready") { ready++ } } END { printf "%d/%d\n", ready, total }'
}

kube_revamped_pods() {
  kube_revamped_pods_rows=$(kube_revamped_limited kubectl get pods --no-headers --request-timeout=2) || return 0
  [ -n "${kube_revamped_pods_rows}" ] || return 0
  printf '%s\n' "${kube_revamped_pods_rows}" | awk 'NF && $3 != "Running" && $3 != "Completed" { bad++ } END { printf "%d\n", bad }'
}

kube_revamped_probe_all() {
  KUBE_REVAMPED_PLAN=""
  if [ "${KUBE_REVAMPED_S_probe_reach}" = 1 ]; then
    kube_revamped_probe_all_reach=down
    ! kube_revamped_reach || kube_revamped_probe_all_reach=up
    kube_revamped_emit set-option -gq @kube_revamped_reach "${kube_revamped_probe_all_reach}"
  fi
  if [ "${KUBE_REVAMPED_S_probe_nodes}" = 1 ]; then
    kube_revamped_probe_all_nodes=$(kube_revamped_nodes)
    kube_revamped_emit set-option -gq @kube_revamped_nodes "${kube_revamped_probe_all_nodes}"
  fi
  if [ "${KUBE_REVAMPED_S_probe_pods}" = 1 ]; then
    kube_revamped_probe_all_pods=$(kube_revamped_pods)
    kube_revamped_emit set-option -gq @kube_revamped_pods "${kube_revamped_probe_all_pods}"
  fi
  kube_revamped_send || :
}

kube_revamped_refresh() {
  kube_revamped_inspect
  kube_revamped_refresh_value="" kube_revamped_refresh_dangling=""
  if [ -n "${KUBE_REVAMPED_CONTEXT}" ]; then
    kube_revamped_refresh_value="${KUBE_REVAMPED_CONTEXT}|${KUBE_REVAMPED_NAMESPACE}"
    [ "${KUBE_REVAMPED_FOUND}" = 1 ] || kube_revamped_refresh_dangling=1
  fi
  kube_revamped_now
  KUBE_REVAMPED_PLAN=""
  kube_revamped_emit set-option -gq @kube_revamped_value "${kube_revamped_refresh_value}"
  kube_revamped_emit set-option -gq @kube_revamped_value_ts "${KUBE_REVAMPED_NOW}"
  kube_revamped_emit set-option -gq @kube_revamped_dangling "${kube_revamped_refresh_dangling}"
  kube_revamped_emit set-option -gq @kube_revamped_cluster "${KUBE_REVAMPED_CLUSTER}"
  kube_revamped_emit set-option -gq @kube_revamped_user "${KUBE_REVAMPED_USER}"
  KUBE_REVAMPED_STORED=1
  kube_revamped_send || KUBE_REVAMPED_STORED=0
  [ "${KUBE_REVAMPED_STORED}" = 1 ] || return 0
  [ -n "${KUBE_REVAMPED_CONTEXT}" ] || return 0
  kube_revamped_probe_all
}

kube_revamped_limit() {
  KUBE_REVAMPED_LIMIT="${KUBE_REVAMPED_S_interval}"
  revamped_cache_is_number "${KUBE_REVAMPED_LIMIT}" || KUBE_REVAMPED_LIMIT="${KUBE_REVAMPED_DEFAULT_INTERVAL}"
}

kube_revamped_stale() {
  revamped_cache_is_number "${KUBE_REVAMPED_S_value_ts}" || return 0
  [ "$((KUBE_REVAMPED_NOW - KUBE_REVAMPED_S_value_ts))" -gt "${KUBE_REVAMPED_LIMIT}" ]
}

kube_revamped_locked() {
  [ "${KUBE_REVAMPED_S_value_lock}" = 1 ] || return 1
  revamped_cache_is_number "${KUBE_REVAMPED_S_value_lock_ts}" || return 1
  [ "$((KUBE_REVAMPED_NOW - KUBE_REVAMPED_S_value_lock_ts))" -lt "${REVAMPED_CACHE_MAX_RUN_DEFAULT}" ]
}

kube_revamped_split() {
  KUBE_REVAMPED_CONTEXT="${KUBE_REVAMPED_S_value%%|*}"
  KUBE_REVAMPED_NAMESPACE=""
  [ "${KUBE_REVAMPED_S_value}" = "${KUBE_REVAMPED_CONTEXT}" ] || KUBE_REVAMPED_NAMESPACE="${KUBE_REVAMPED_S_value#*|}"
}

kube_revamped_colour() {
  KUBE_REVAMPED_COLOUR="${KUBE_REVAMPED_S_color}"
  [ -n "${KUBE_REVAMPED_S_prod_pattern}" ] || return 0
  case "${KUBE_REVAMPED_CONTEXT}" in
  *"${KUBE_REVAMPED_S_prod_pattern}"*) KUBE_REVAMPED_COLOUR="${KUBE_REVAMPED_S_prod_color}" ;;
  *) return 0 ;;
  esac
}

kube_revamped_segment() {
  KUBE_REVAMPED_SEGMENT=""
  [ -n "${KUBE_REVAMPED_CONTEXT}" ] || return 0
  if [ "${KUBE_REVAMPED_S_hide_default}" = 1 ] && [ "${KUBE_REVAMPED_CONTEXT}" = default ]; then
    return 0
  fi
  kube_revamped_colour
  kube_revamped_doubled "${KUBE_REVAMPED_CONTEXT}"
  kube_revamped_segment_text="${KUBE_REVAMPED_DOUBLED}"
  if [ "${KUBE_REVAMPED_S_show_cluster}" = 1 ] && [ -n "${KUBE_REVAMPED_S_cluster}" ]; then
    kube_revamped_doubled "${KUBE_REVAMPED_S_cluster}"
    kube_revamped_segment_text="${kube_revamped_segment_text}@${KUBE_REVAMPED_DOUBLED}"
  fi
  if [ "${KUBE_REVAMPED_S_show_namespace}" = 1 ] && [ -n "${KUBE_REVAMPED_NAMESPACE}" ]; then
    kube_revamped_doubled "${KUBE_REVAMPED_NAMESPACE}"
    kube_revamped_segment_text="${kube_revamped_segment_text}:${KUBE_REVAMPED_DOUBLED}"
  fi
  if [ "${KUBE_REVAMPED_S_show_user}" = 1 ] && [ -n "${KUBE_REVAMPED_S_user}" ]; then
    kube_revamped_doubled "${KUBE_REVAMPED_S_user}"
    kube_revamped_segment_text="${kube_revamped_segment_text} (${KUBE_REVAMPED_DOUBLED})"
  fi
  if [ "${KUBE_REVAMPED_S_dangling}" = 1 ]; then
    KUBE_REVAMPED_COLOUR="${KUBE_REVAMPED_S_warn_color}"
    kube_revamped_segment_text="${kube_revamped_segment_text} ${KUBE_REVAMPED_S_warn_icon}"
  fi
  [ -z "${KUBE_REVAMPED_S_icon}" ] || kube_revamped_segment_text="${KUBE_REVAMPED_S_icon} ${kube_revamped_segment_text}"
  KUBE_REVAMPED_SEGMENT="${KUBE_REVAMPED_COLOUR}${kube_revamped_segment_text}${KUBE_REVAMPED_RESET}"
}

kube_revamped_health_reach() {
  case "${KUBE_REVAMPED_S_probe_reach}:${KUBE_REVAMPED_S_reach}" in
  1:up) KUBE_REVAMPED_HEALTH="${KUBE_REVAMPED_HEALTH} ${KUBE_REVAMPED_UP}o${KUBE_REVAMPED_RESET}" ;;
  1:down) KUBE_REVAMPED_HEALTH="${KUBE_REVAMPED_HEALTH} ${KUBE_REVAMPED_DOWN}x${KUBE_REVAMPED_RESET}" ;;
  *) return 0 ;;
  esac
}

kube_revamped_health_nodes() {
  [ "${KUBE_REVAMPED_S_probe_nodes}" = 1 ] || return 0
  [ -n "${KUBE_REVAMPED_S_nodes}" ] || return 0
  kube_revamped_health_nodes_colour="${KUBE_REVAMPED_S_warn_color}"
  [ "${KUBE_REVAMPED_S_nodes%%/*}" != "${KUBE_REVAMPED_S_nodes#*/}" ] || kube_revamped_health_nodes_colour="${KUBE_REVAMPED_UP}"
  KUBE_REVAMPED_HEALTH="${KUBE_REVAMPED_HEALTH} ${kube_revamped_health_nodes_colour}${KUBE_REVAMPED_S_nodes}${KUBE_REVAMPED_RESET}"
}

kube_revamped_health_pods() {
  [ "${KUBE_REVAMPED_S_probe_pods}" = 1 ] || return 0
  case "${KUBE_REVAMPED_S_pods}" in
  "" | 0) return 0 ;;
  *) KUBE_REVAMPED_HEALTH="${KUBE_REVAMPED_HEALTH} ${KUBE_REVAMPED_S_warn_color}!${KUBE_REVAMPED_S_pods}${KUBE_REVAMPED_RESET}" ;;
  esac
}

kube_revamped_health() {
  KUBE_REVAMPED_HEALTH=""
  kube_revamped_health_reach
  kube_revamped_health_nodes
  kube_revamped_health_pods
}

kube_revamped_print() {
  [ -z "$1" ] || printf '%s\n' "$1"
}

kube_revamped_show() {
  kube_revamped_split
  case "$1" in
  context)
    kube_revamped_doubled "${KUBE_REVAMPED_CONTEXT}"
    kube_revamped_print "${KUBE_REVAMPED_DOUBLED}"
    ;;
  namespace)
    kube_revamped_doubled "${KUBE_REVAMPED_NAMESPACE}"
    kube_revamped_print "${KUBE_REVAMPED_DOUBLED}"
    ;;
  *)
    kube_revamped_segment
    [ -n "${KUBE_REVAMPED_SEGMENT}" ] || return 0
    kube_revamped_health
    kube_revamped_print "${KUBE_REVAMPED_SEGMENT}${KUBE_REVAMPED_HEALTH}"
    ;;
  esac
}

kube_revamped_status() {
  kube_revamped_load
  kube_revamped_now
  kube_revamped_limit
  if kube_revamped_stale && ! kube_revamped_locked; then
    revamped_cache_refresh_if_stale value "${KUBE_REVAMPED_LIMIT}" kube_revamped_refresh || :
  fi
  kube_revamped_show "$1"
}

kube_revamped_switch() {
  if ! revamped_has_command kubectl; then
    kube_revamped_say "kubectl is not installed"
    return 0
  fi
  kube_revamped_switch_what="$1" kube_revamped_switch_name="$2"
  shift 2
  if ! kubectl config "$@" >/dev/null 2>&1; then
    kube_revamped_say "kubectl could not switch to the ${kube_revamped_switch_what} ${kube_revamped_switch_name}"
    return 0
  fi
  kube_revamped_load
  kube_revamped_refresh
}

kube_revamped_use_context() {
  kube_revamped_switch context "$1" use-context "$1"
}

kube_revamped_use_namespace() {
  kube_revamped_switch namespace "$1" set-context --current --namespace "$1"
}

kube_revamped_items() {
  sed -e 'h' -e 's/#/##/g' -e 'x' -e "s/'/'\\\\''/g" -e "s/#/'\"\$(printf '%b' '\\\\0043')\"'/g" -e "s/^/'/" -e "s/\$/'/" -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\$/\\$/g' -e 'x' -e 'G' -e "s/\\n/${KUBE_REVAMPED_TAB}/"
}

kube_revamped_menu() {
  kube_revamped_menu_verb="$2" kube_revamped_menu_empty="$4"
  kube_revamped_menu_rows=$(printf '%s\n' "$3" | sed '/^$/d' | kube_revamped_items)
  kube_revamped_tools
  kube_revamped_menu_tool=$(kube_revamped_tmux_string "${KUBE_REVAMPED_TOOL}")
  set -- display-menu -T "$1"
  KUBE_REVAMPED_MENU_ITEMS=0
  while IFS="${KUBE_REVAMPED_TAB}" read -r kube_revamped_menu_label kube_revamped_menu_name; do
    [ -n "${kube_revamped_menu_label}" ] || continue
    set -- "$@" "${kube_revamped_menu_label}" "" "run-shell \"${kube_revamped_menu_tool} ${kube_revamped_menu_verb} ${kube_revamped_menu_name}\""
    KUBE_REVAMPED_MENU_ITEMS=$((KUBE_REVAMPED_MENU_ITEMS + 1))
  done <<EOF
${kube_revamped_menu_rows}
EOF
  if [ "${KUBE_REVAMPED_MENU_ITEMS}" -eq 0 ]; then
    kube_revamped_say "${kube_revamped_menu_empty}"
    return 0
  fi
  tmux "$@"
}

kube_revamped_menu_context() {
  kube_revamped_menu_context_names=$(kube_revamped_read list 2>/dev/null) || kube_revamped_menu_context_names=""
  kube_revamped_menu Context use-context "${kube_revamped_menu_context_names}" "the kubeconfig holds no context"
}

kube_revamped_namespaces() {
  kubectl get namespaces -o name --request-timeout=2 2>/dev/null | sed 's|^namespace/||'
}

kube_revamped_menu_namespace() {
  kube_revamped_menu_namespace_names=$(kube_revamped_namespaces) || kube_revamped_menu_namespace_names=""
  kube_revamped_menu Namespace use-namespace "${kube_revamped_menu_namespace_names}" "kubectl listed no namespace"
}

kube_revamped_version() {
  kube_revamped_version_raw=$(tmux -V 2>/dev/null) || kube_revamped_version_raw=""
  KUBE_REVAMPED_TMUX=$(kube_revamped_parse_version "${kube_revamped_version_raw}")
}

kube_revamped_popup() {
  kube_revamped_load
  kube_revamped_version
  if ! kube_revamped_version_ge "${KUBE_REVAMPED_TMUX}" "${KUBE_REVAMPED_POPUP_SINCE}"; then
    kube_revamped_say "the popup needs tmux ${KUBE_REVAMPED_POPUP_SINCE} or later"
    return 0
  fi
  kube_revamped_split
  if [ -z "${KUBE_REVAMPED_CONTEXT}" ]; then
    kube_revamped_say "no current context to open"
    return 0
  fi
  kube_revamped_popup_program="${KUBE_REVAMPED_S_popup_command%% *}"
  if ! revamped_has_command "${kube_revamped_popup_program}"; then
    kube_revamped_say "${kube_revamped_popup_program} is not installed"
    return 0
  fi
  kube_revamped_popup_context=$(kube_revamped_literal "${KUBE_REVAMPED_CONTEXT}")
  kube_revamped_popup_full="${KUBE_REVAMPED_S_popup_command} --context ${kube_revamped_popup_context}"
  if [ -n "${KUBE_REVAMPED_NAMESPACE}" ]; then
    kube_revamped_popup_namespace=$(kube_revamped_literal "${KUBE_REVAMPED_NAMESPACE}")
    kube_revamped_popup_full="${kube_revamped_popup_full} --namespace ${kube_revamped_popup_namespace}"
  fi
  tmux display-popup -E -w "${KUBE_REVAMPED_S_popup_width}" -h "${KUBE_REVAMPED_S_popup_height}" "${kube_revamped_popup_full}" || :
}

kube_revamped_plan_keys() {
  case "${KUBE_REVAMPED_S_menu_context_key}: ${KUBE_REVAMPED_KEYS} " in
  "${KUBE_REVAMPED_DEFAULT_MENU_KEY}:"*" ${KUBE_REVAMPED_DEFAULT_MENU_KEY} "*) KUBE_REVAMPED_SKIPPED="${KUBE_REVAMPED_DEFAULT_MENU_KEY}" ;;
  *) kube_revamped_bind "${KUBE_REVAMPED_S_menu_context_key}" "Kubernetes contexts" run-shell "${KUBE_REVAMPED_TOOL} menu-context" ;;
  esac
  kube_revamped_bind "${KUBE_REVAMPED_S_menu_namespace_key}" "Kubernetes namespaces" run-shell "${KUBE_REVAMPED_TOOL} menu-namespace"
  kube_revamped_bind "${KUBE_REVAMPED_S_popup_key}" "Kubernetes popup" run-shell "${KUBE_REVAMPED_TOOL} popup"
}

kube_revamped_replaced() {
  printf '%s\n' "$1" | KUBE_REVAMPED_PUT="${KUBE_REVAMPED_JOB}" awk '
    BEGIN {
      command = ENVIRON["KUBE_REVAMPED_PUT"]
      split("kube_context kube_namespace kube", names, " ")
      split("context namespace kube", kinds, " ")
    }
    {
      line = $0
      for (i = 1; i <= 3; i++) {
        holder = "#{" names[i] "}"
        done = ""
        while ((at = index(line, holder)) > 0) {
          done = done substr(line, 1, at - 1) "#(" command " status " kinds[i] ")"
          line = substr(line, at + length(holder))
        }
        line = done line
      }
      print line
    }
  '
}

kube_revamped_plan_status() {
  for kube_revamped_plan_status_option in status-left status-right; do
    kube_revamped_plan_status_now=$(tmux show-option -gqv "${kube_revamped_plan_status_option}" 2>/dev/null) || kube_revamped_plan_status_now=""
    case "${kube_revamped_plan_status_now}" in
    *"#{kube}"* | *"#{kube_context}"* | *"#{kube_namespace}"*) kube_revamped_plan_status_new=$(kube_revamped_replaced "${kube_revamped_plan_status_now}") ;;
    *) continue ;;
    esac
    kube_revamped_emit set-option -gq "${kube_revamped_plan_status_option}" "${kube_revamped_plan_status_new}"
  done
}

kube_revamped_plan() {
  kube_revamped_load
  kube_revamped_version
  KUBE_REVAMPED_NOTES=0
  ! kube_revamped_version_ge "${KUBE_REVAMPED_TMUX}" "${KUBE_REVAMPED_NOTES_SINCE}" || KUBE_REVAMPED_NOTES=1
  kube_revamped_tools
  KUBE_REVAMPED_KEYS=$(kube_revamped_held)
  KUBE_REVAMPED_PLAN="" KUBE_REVAMPED_SKIPPED="" KUBE_REVAMPED_BOUND=""
  kube_revamped_plan_keys
  kube_revamped_plan_status
}

kube_revamped_apply() {
  kube_revamped_plan
  kube_revamped_deliver
}
