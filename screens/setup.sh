export PS1='$ '
export PATH="/Users/Shared/demo/bin:/Users/Shared/demo/tmux-kube-revamped/bin:${PATH}"
unset KODOUGU_THEME KODOUGU_ACCENT KUBE_REVAMPED_THEME KUBE_REVAMPED_ACCENT NO_COLOR
export HOME=/Users/Shared/demo/home
export KUBECONFIG=/Users/Shared/demo/home/.kube/config
cd /Users/Shared/demo || return 1
printf '\033]2;demo\033\134'
clear
