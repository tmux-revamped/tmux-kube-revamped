# tmux-kube-revamped

Guidance for anyone, human or agent, changing tmux-kube-revamped. What it is and how to use it lives in [README.md](README.md).

[FAMILY.md](FAMILY.md) holds everything this plugin shares with the rest of the tmux-revamped family, and it is the same in every member. This file holds only what is exclusive to tmux-kube-revamped, under the same headings as the agent guide of every member. Read both before changing anything; a rule that would serve the other members goes into [`FAMILY.md`](FAMILY.md) instead of here.

## Layout

| Path | Holds |
|:-----|:------|
| [`kube-revamped.tmux`](kube-revamped.tmux) | The entry point TPM runs: it runs `bin/kube-revamped apply` |
| [`bin/kube-revamped`](bin/kube-revamped) | The command: `apply`, `list`, `status`, `refresh`, `use-context`, `use-namespace`, `menu-context`, `menu-namespace`, `popup`, `doctor`, `version`, `help` and the menu. `apply`, `status`, `refresh` and the key actions run without loading the interface modules |
| [`lib/kube.sh`](lib/kube.sh) | Reading the settings and the stored reading, the refresh, the kubectl probes, the segment, the two menus, the popup and the bindings |
| [`lib/kubeconfig.awk`](lib/kubeconfig.awk) | The kubeconfig reader: the current context with its namespace, cluster and user, or the list of contexts, in one awk run over every file |
| [`lib/state.sh`](lib/state.sh) | Every global, including `KUBE_REVAMPED_SETTINGS`, the table of setting names and defaults, and `KUBE_REVAMPED_LIVE`, the names of the options that hold the reading |
| [`lib/core.sh`](lib/core.sh) | The version |
| [`lib/`](lib) | Every other file is the shared library, identical in every member |
| [`test/kube.bats`](test/kube.bats), [`test/refresh.bats`](test/refresh.bats), [`test/plan.bats`](test/plan.bats), [`test/commands.bats`](test/commands.bats) | The reader and the segment, the refresh with its probes and switches, the bindings with the menus and the popup, and every command, against a stand-in tmux from [`test/kube_helpers.bash`](test/kube_helpers.bash) that keeps options in a file and applies each `set-option` it receives, with stand-ins for `date` and `kubectl` |
| [`test/entrypoint.bats`](test/entrypoint.bats), [`test/keys.bats`](test/keys.bats) | The plugin on a private tmux server, with every key and a menu item of each menu pressed through a second tmux attached to it; both share [`test/server_helpers.bash`](test/server_helpers.bash), whose `kubectl` stand-in rewrites the test's own kubeconfig |
| [`screens/`](screens) | The tapes and the recording's tmux config. `prepare.sh` writes a kubeconfig for the recording and a `kubectl` that answers for the cluster and hands every other call to the real one |

## Names

- Settings are the tmux options `@kube_revamped_<setting>` listed in `KUBE_REVAMPED_SETTINGS`, the long options with dashes, such as `--show-cluster`, and the environment variables `KUBE_REVAMPED_<SETTING>`.
- The stored reading is `@kube_revamped_value`, the context and the namespace joined by `|`, with `_value_ts`, `_value_lock`, `_value_lock_ts`, `_dangling`, `_cluster`, `_user`, `_reach`, `_nodes` and `_pods`. None of them is a setting.
- The placeholders are `#{kube}`, `#{kube_context}` and `#{kube_namespace}`.
- The version constant is `KUBE_REVAMPED_VERSION`.
- The command's own functions and the library's never share a name, because the command is sourced after the library and would replace it.

## Behaviour

- `apply` reads every setting and the stored reading with one `tmux display-message` call and one `env` read, reads the prefix table once, and sends every binding and the replaced status strings in one tmux call. When that call fails, it sends each command alone, so one invalid key leaves the others bound and `apply` exits 1.
- Each placeholder in `status-left` or `status-right` becomes `#(<tool> status <name>)`, with the tool's path quoted for a shell and every `#` doubled. A string without a placeholder is not written, so loading twice changes nothing.
- `status` makes one tmux read and one `date` call, and prints the stored reading at once. Only when that reading is older than `@kube_revamped_interval`, and no reading is under way, does it start one in the background through the shared cache module; a lock older than 20 seconds no longer holds a new reading back.
- A refresh writes the context, its time, the dangling mark, the cluster and the user in one tmux call, then the probes that are on in a second one.
- `M-k` opens the context menu; the namespace menu and the popup have opt-in keys. A key set to `off` binds nothing. Only the default key is skipped when someone else holds it, and `doctor` names it; a key the person names is bound whoever holds it. Two actions set to one key bind it for the first and the clash is named.
- A key with nothing to show says why in a tmux message and exits 0, since a `run-shell` that fails or prints opens tmux's own output screen: no context in the kubeconfig, no namespace from kubectl, no stored context, a tmux older than 3.2, a popup program that is not installed, kubectl missing, or a switch kubectl refused.
- A setting `apply` got from the command line or the environment rides, as an option, on every binding, every menu item and every status call; `KUBE_REVAMPED_CARRIED` lists the ones that ride.
- The entry point clears every inherited `REVAMPED_` variable except the test switches, and every `KUBE_REVAMPED_*_LOADED` guard; every other global is assigned outright in the state file.

## Domain rules

- The reader takes every file in `$KUBECONFIG` in order, or `~/.kube/config`, skips the ones it cannot read, and takes the first `current-context` it finds, as kubectl does. A context is an entry of a top-level `contexts:` list; a nested list inside one, such as `extensions`, starts no entry. A context with no namespace is in `default`, and a current context no file lists is stored as dangling.
- tmux expands formats in the output of a status job, so the context, namespace, cluster and user have each `#` doubled before they are printed. A menu label is doubled the same way; a menu item's command and the popup's command carry the name single-quoted with no `#` left in it.
- Each kubectl probe runs only when its option is `1`, with a 2 second request timeout, and is stopped after 5 seconds by a watcher the probe ends when it finishes first. A dangling context is still probed; no context means no probe.
- The namespace menu asks kubectl when the key is pressed. Switching runs `kubectl config use-context` or `kubectl config set-context --current --namespace`, then reads the kubeconfig again.
- A row of `KUBE_REVAMPED_SETTINGS` with an empty default may end at the name: an editor that trims trailing whitespace would otherwise remove the tab and shift every later setting.
- An argument that ends in `;` is sent as `\;`: tmux reads a bare trailing semicolon in an argument as a command separator. The command list keeps an empty argument, which `set-option` needs to clear an option and `display-menu` needs for an item with no key, as the marker in `KUBE_REVAMPED_EMPTY`; only an empty line ends a command.

## Release

- `KUBE_REVAMPED_VERSION` in [`lib/core.sh`](lib/core.sh) holds the version. Nobody edits it by hand.
- After a green `ci` run on `main`, [`release.yml`](.github/workflows/release.yml) runs semantic-release: a `feat` or `fix` since the last tag publishes a release, [`set-version.sh`](.github/scripts/set-version.sh) stamps the constant, and the notes go into [`CHANGELOG.md`](CHANGELOG.md).

## Gaps against FAMILY.md

As of 2026-11-17, none.
