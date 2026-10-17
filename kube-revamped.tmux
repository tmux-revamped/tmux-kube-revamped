#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KUBE_CMD="${CURRENT_DIR}/src/kube.sh"

placeholders=(
  "\#{kube_context}"
  "\#{kube_namespace}"
  "\#{kube}"
)

commands=(
  "#(${KUBE_CMD} context)"
  "#(${KUBE_CMD} namespace)"
  "#(${KUBE_CMD} kube)"
)

interpolate() {
  local value="${1}"
  for (( i = 0; i < ${#placeholders[@]}; i++ )); do
    value="${value//${placeholders[i]}/${commands[i]}}"
  done
  echo "${value}"
}

update_option() {
  local option="${1}" current
  current=$(tmux show-option -gqv "${option}")
  tmux set-option -gq "${option}" "$(interpolate "${current}")"
}

chmod +x "${KUBE_CMD}" 2>/dev/null || true

update_option "status-left"
update_option "status-right"

"${KUBE_CMD}" bind-keys 2>/dev/null || true
