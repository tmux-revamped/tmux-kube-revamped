#!/bin/sh
# shellcheck disable=SC2034

[ -n "${KUBE_REVAMPED_CORE_LOADED:-}" ] && return 0
KUBE_REVAMPED_CORE_LOADED=1

readonly KUBE_REVAMPED_VERSION="2.0.2"
