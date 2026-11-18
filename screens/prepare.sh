#!/bin/sh
set -eu

: "${SCREENS_REPO:?}"
demo=/Users/Shared/demo
rm -rf "${demo}"
mkdir -p "${demo}/home/.kube" "${demo}/bin" "${demo}/tmux-kube-revamped"
cp -Rpf "${SCREENS_REPO}/bin" "${SCREENS_REPO}/lib" "${SCREENS_REPO}/kube-revamped.tmux" "${demo}/tmux-kube-revamped/"
tmux_path=$(command -v tmux)
ln -s "${tmux_path}" "${demo}/bin/tmux"
kubectl_path=$(command -v kubectl) || kubectl_path=""
if [ -z "${kubectl_path}" ]; then
  printf 'screens: kubectl is missing, and the recording switches contexts with it\n' >&2
  exit 1
fi

cat >"${demo}/home/.kube/config" <<'CONFIG'
apiVersion: v1
kind: Config
current-context: staging
contexts:
- name: staging
  context:
    cluster: staging-eu
    user: deploy
- name: prod-eu
  context:
    cluster: prod-eu-west
    user: oncall
- name: dev
  context:
    cluster: kind-dev
    namespace: sandbox
    user: me
clusters:
- name: staging-eu
  cluster: {}
- name: prod-eu-west
  cluster: {}
- name: kind-dev
  cluster: {}
users:
- name: deploy
  user: {}
- name: oncall
  user: {}
- name: me
  user: {}
CONFIG

cat >"${demo}/bin/kubectl" <<KUBECTL
#!/bin/sh
case "\$*" in
"get namespaces"*) printf 'namespace/default\nnamespace/payments\nnamespace/monitoring\n' ;;
"get nodes"*) printf 'node-a   Ready      worker   12d   v1.33.1\nnode-b   Ready      worker   12d   v1.33.1\nnode-c   NotReady   worker   12d   v1.33.1\n' ;;
"get pods"*) printf 'api-7d9f-1      1/1   Running            0   3d\napi-7d9f-2      1/1   Running            0   3d\nworker-5c8-1    0/1   CrashLoopBackOff   7   3d\n' ;;
cluster-info*) exit 0 ;;
*) exec "${kubectl_path}" "\$@" ;;
esac
KUBECTL

cat >"${demo}/bin/pods" <<'PODS'
#!/bin/sh
printf 'pods of %s in %s\n\n' "$2" "$4"
kubectl get pods --no-headers
printf '\nEnter closes\n'
read -r pods_wait
PODS
chmod +x "${demo}/bin/kubectl" "${demo}/bin/pods"
