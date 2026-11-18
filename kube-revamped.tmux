#!/bin/sh

kube_revamped_dir=$(cd "$(dirname "$0")" && pwd)
"${kube_revamped_dir}/bin/kube-revamped" apply
