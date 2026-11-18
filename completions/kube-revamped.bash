# shellcheck shell=bash
# shellcheck disable=SC2207

_kube_revamped() {
  local cur prev
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"

  case "${prev}" in
  --theme)
    COMPREPLY=($(compgen -W "kodougu catppuccin-mocha catppuccin-latte dracula nord gruvbox tokyo-night mono" -- "${cur}"))
    return
    ;;
  --hide-default | --show-cluster | --show-namespace | --show-user | --probe-reach | --probe-nodes | --probe-pods)
    COMPREPLY=($(compgen -W "0 1" -- "${cur}"))
    return
    ;;
  --menu-context-key | --menu-namespace-key | --popup-key | --interval | --color | --prod-pattern | --prod-color | --warn-color | --warn-icon | --icon | --popup-command | --popup-width | --popup-height)
    return
    ;;
  *) ;;
  esac

  COMPREPLY=($(compgen -W "apply list status refresh use-context use-namespace menu-context menu-namespace popup doctor version help --json --theme --menu-context-key --menu-namespace-key --popup-key --interval --color --prod-pattern --prod-color --warn-color --warn-icon --icon --hide-default --show-cluster --show-namespace --show-user --probe-reach --probe-nodes --probe-pods --popup-command --popup-width --popup-height" -- "${cur}"))
}

complete -F _kube_revamped kube-revamped
