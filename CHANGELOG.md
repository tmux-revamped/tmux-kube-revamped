# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.1] - 2026-10-27

### Fixed

- A plugin directory whose path holds a space or an `&` broke every status-line
  placeholder: `/bin/sh` split the path at the space and backgrounded the
  command at the `&`, and bash 5.2 replaced the `&` with the placeholder. The
  path is now shell-quoted.

## [2.0.0] - 2026-10-17

### Changed

- **Breaking:** the context switcher is now bound to `prefix + M-k` by default,
  the key the family allocates to this plugin. It was unbound before. Set
  `@kube_revamped_menu_context_key` to `off` to leave it unbound, or to another
  key. The namespace switcher and the k9s popup stay unbound until set.

### Fixed

- With several KUBECONFIG files, the first file that sets current-context now
  wins, as kubectl resolves it. The 1.1.0 rule of the last one winning could show
  a context kubectl was not using.
- Context entries are parsed whole, so a name written before its context
  block, a quoted name with spaces, and a nested extensions list all
  resolve correctly.
- Context and namespace names are quoted in the switcher menus, the k9s
  popup and the key bindings, so a space, a quote, a semicolon or a # in a
  name, or in the plugin path, no longer breaks the command or runs as
  shell syntax.
- Each cluster probe now has a hard 5-second limit, so a kubectl stuck in
  an auth plugin or a dead VPN can no longer outlive the worker lock and
  let a second worker start beside it.

## [1.1.0] - 2026-06-29

### Added

- Context switcher and namespace switcher in the bar, opened with configurable
  keys via display-menu. The context list is read from the kubeconfig; the
  namespace list comes from the cluster only when you open that menu.
- k9s popup pinned to the current context and namespace, gated on tmux 3.2+.
- Full KUBECONFIG support: every file in the colon-separated list is read and
  merged, with the last current-context winning, so the shown context can no
  longer be wrong when KUBECONFIG names more than one file.
- Dangling-context warning: a current-context absent from the merged kubeconfig
  is flagged with a warning color and marker instead of a misleading name.
- Optional cluster + user in the segment, with a prod-context warning color.
- Opt-in async health badges fed by a detached worker: a reachability dot, a
  node-ready badge, and a non-running pod count. Every cluster call runs behind
  a seam and only when its probe is enabled, so the default plugin never forks
  kubectl and the render never blocks.
- A `doctor` report listing detected tools, kubeconfig readability, and whether
  the current context is dangling.

## [1.0.1] - 2026-06-23

### Changed

- Reviewed the upstream `jonmosco/kube-tmux` issues. Output stays clean in every
  state: an empty or absent current context renders nothing rather than garbled
  text (#22). The default segment color is a named color, so it survives the
  tmux 3.7 format-expansion change unharmed. No code change needed.

## [1.0.0] - 2026-06-22

### Added

- Current Kubernetes context and namespace in the status bar via #{kube},
  #{kube_context}, and #{kube_namespace}.
- Parses ~/.kube/config (honoring $KUBECONFIG) directly, so it needs no kubectl
  and never forks a process on render.
- Async cache in tmux server options with a detached background worker; the
  render never blocks and no temp file is written.
- Configurable icon, color, namespace visibility, refresh interval, and a
  hide-default toggle.
