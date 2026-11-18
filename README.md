<div align="center">

# tmux-kube-revamped

<strong>Current Kubernetes context and namespace in the tmux status bar, parsed from kubeconfig without kubectl.</strong>

English &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-kube-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-kube-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-kube-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-kube-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-kube-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-kube-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-kube-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#quick-start"><strong>Quick start</strong></a> &nbsp;|&nbsp;
  <a href="#usage">Usage</a> &nbsp;|&nbsp;
  <a href="#how-it-works">How it works</a> &nbsp;|&nbsp;
  <a href="#screens">Screens</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="kube-revamped showing the context in the status line, switching the context and the namespace from its menus, turning on the probes and opening the popup" width="800">
</p>

```console
$ kube-revamped refresh
Refreshed. The context is staging in the namespace payments.
$ kube-revamped status kube
#[fg=blue]staging:payments#[default]
```

**3** status placeholders, **2** switcher menus and a k9s popup, and the default segment never starts kubectl.

---

## Quick start

### Prerequisites

| Tool | Version | Used for |
|:-----|:--------|:---------|
| tmux | 3.2 or later | the family floor, and the popup |
| kubeconfig | any | every file in `$KUBECONFIG`, or `~/.kube/config`: the context, namespace, cluster and user |
| `kubectl` | optional | the namespace menu, switching and the probes |
| [k9s](https://k9scli.io) | optional | the popup, or any program set in `@kube_revamped_popup_command` |
| gum | optional | the menu, tables and colours of `kube-revamped`; without it every command prints plain text |

### Install

With [TPM](https://github.com/tmux-plugins/tpm), add the plugin to `~/.tmux.conf` and press `prefix + I`:

```tmux
set -g @plugin 'tmux-revamped/tmux-kube-revamped'
```

Without TPM, clone the repository and run the entrypoint from `~/.tmux.conf`:

```sh
git clone https://github.com/tmux-revamped/tmux-kube-revamped ~/.tmux/plugins/tmux-kube-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-kube-revamped/kube-revamped.tmux
```

Set `status-left` or `status-right` before the plugin loads, because the entrypoint replaces the placeholders in those two options when it runs.

`make install` in the clone also puts `kube-revamped` in `~/.local/bin`, with its man page and completions under `~/.local/share`.

### Verify

```bash
~/.tmux/plugins/tmux-kube-revamped/bin/kube-revamped doctor
```

## Usage

Put `#{kube}` in your status line and it shows the current context and namespace, such as `prod-ctx:web`. The plugin parses the kubeconfig with awk, so the segment works on a host with no kubectl installed.

| Placeholder | Output |
|:------------|:-------|
| `#{kube}` | the styled segment: context, optional `@cluster`, `:namespace`, optional user, and any health badges |
| `#{kube_context}` | the current context name only |
| `#{kube_namespace}` | the current namespace only, `default` when the context sets none |

The segment is empty when no current context is set. A current context that names no entry in the kubeconfig is shown in `@kube_revamped_warn_color` with `@kube_revamped_warn_icon` after it, instead of a namespace.

Three health badges are opt-in, because each one calls the cluster:

| Badge | Probe | Shows |
|:------|:------|:------|
| reachability | `kubectl cluster-info` | a green `o` when it answers, a red `x` when it does not |
| nodes | `kubectl get nodes` | ready over total, such as `3/3`, green when all are ready and in the warning color otherwise |
| pods | `kubectl get pods` in the current namespace | `!N` in the warning color, where N counts pods neither `Running` nor `Completed`; hidden at zero |

```tmux
set -g status-right '#{kube} | %H:%M'
set -g @kube_revamped_prod_pattern 'prod'
set -g @kube_revamped_probe_reach '1'
```

`prefix + M-k` opens a menu of every context in the kubeconfig. Picking one runs `kubectl config use-context` and updates the cache at once. The namespace menu and the k9s popup stay unbound until you give each one a key:

```tmux
set -g @kube_revamped_menu_namespace_key 'M-n'
set -g @kube_revamped_popup_key 'K'
```

The namespace menu asks the cluster for its namespaces when you press the key, so it opens once kubectl answers or its 2-second request timeout passes. Picking one runs `kubectl config set-context --current --namespace`. The popup runs `k9s --context <context> --namespace <namespace>` for the cached context. A key with nothing to show says why in a tmux message: no context in the kubeconfig, no namespace from kubectl, no current context yet, or a popup command that is not installed.

| Command | What it does |
|:--------|:-------------|
| `kube-revamped apply` | Binds the keys and fills the placeholders now; the entry point runs it when tmux loads the plugin |
| `kube-revamped list` | Prints every command `apply` would send and changes nothing; `--json` prints one object |
| `kube-revamped status NAME` | Prints one placeholder, `kube`, `context` or `namespace`; the status line runs it |
| `kube-revamped refresh` | Reads the kubeconfig now and says what it found |
| `kube-revamped use-context NAME` | Switches kubectl to a context |
| `kube-revamped use-namespace NAME` | Sets the namespace of the current context |
| `kube-revamped menu-context` | Opens the context menu in tmux |
| `kube-revamped menu-namespace` | Opens the namespace menu in tmux |
| `kube-revamped popup` | Opens the popup program on the current context |
| `kube-revamped doctor` | One row per dependency: each kubeconfig file, the current context, `kubectl`, the popup program and any key left alone |
| `kube-revamped version` | The version, then the tmux version |
| `kube-revamped help` | The help page; `man kube-revamped` documents the same commands and settings |
| `kube-revamped` | On a terminal, a menu |

## Configuration

| Option | Default | Meaning |
|:-------|:--------|:--------|
| `@kube_revamped_interval` | `10` | seconds a cached context stays fresh |
| `@kube_revamped_icon` | empty | text shown before the context, such as a Nerd Font glyph |
| `@kube_revamped_color` | `#[fg=blue]` | segment style |
| `@kube_revamped_show_namespace` | `1` | `0` shows the context without `:namespace` |
| `@kube_revamped_hide_default` | `0` | `1` hides `#{kube}` when the context is named `default` |
| `@kube_revamped_show_cluster` | `0` | `1` appends `@cluster` to the context |
| `@kube_revamped_show_user` | `0` | `1` appends ` (user)` to the segment |
| `@kube_revamped_prod_pattern` | empty | substring that marks a context as production |
| `@kube_revamped_prod_color` | `#[fg=red]` | segment style when the context contains the production pattern |
| `@kube_revamped_warn_color` | `#[fg=yellow]` | style for a missing context and for unhealthy badges |
| `@kube_revamped_warn_icon` | `?` | marker after a context missing from the kubeconfig |
| `@kube_revamped_menu_context_key` | `M-k` | key for the context menu; `off` leaves it unbound |
| `@kube_revamped_menu_namespace_key` | empty | key for the namespace menu |
| `@kube_revamped_popup_key` | empty | key for the popup |
| `@kube_revamped_popup_command` | `k9s` | command run in the popup, followed by `--context` and `--namespace` |
| `@kube_revamped_popup_width` | `80%` | popup width |
| `@kube_revamped_popup_height` | `80%` | popup height |
| `@kube_revamped_probe_reach` | `0` | `1` turns on the reachability badge |
| `@kube_revamped_probe_nodes` | `0` | `1` turns on the nodes badge |
| `@kube_revamped_probe_pods` | `0` | `1` turns on the pods badge |

Every option is also a command option with dashes, such as `--interval 30`, and an environment variable, such as `KUBE_REVAMPED_INTERVAL`; the command line wins over the environment, and the environment over the tmux option. An empty tmux option means its default. One given to `apply` rides on every binding, every menu item and every status call.

### Internal state

The plugin manages these options itself. Do not set them.

| Option | Holds |
|:-------|:------|
| `@kube_revamped_value` | the cached `context\|namespace` pair |
| `@kube_revamped_dangling` | `1` when the current context is missing from the kubeconfig |
| `@kube_revamped_cluster` | the cluster of the current context |
| `@kube_revamped_user` | the user of the current context |
| `@kube_revamped_reach` | `up` or `down` from the reachability probe |
| `@kube_revamped_nodes` | ready over total nodes from the nodes probe |
| `@kube_revamped_pods` | the count of pods that are neither running nor completed |
| `@kube_revamped_value_lock` | `1` while a background refresh runs |

`@kube_revamped_value_ts` holds the Unix time the reading was written, and `@kube_revamped_value_lock_ts` the time the lock was taken.

## Key bindings

| Key | Action | Default |
|:----|:-------|:--------|
| `prefix + M-k` | context menu | bound |
| `@kube_revamped_menu_namespace_key` | namespace menu | unbound |
| `@kube_revamped_popup_key` | k9s popup | unbound |

`M-k` is this plugin's slot in the family key allocation. Before version 2.0.0 the context menu had no default key. To leave it unbound:

```tmux
set -g @kube_revamped_menu_context_key 'off'
```

<a id="how-it-works"></a>

## How it works

```mermaid
graph LR
    A[status render] --> B[bin/kube-revamped]
    B --> C{cache fresh}
    C -->|yes| D[tmux options]
    C -->|no| E[background worker]
    E --> F[kubeconfig parse]
    E --> G[opt-in kubectl probes]
    F --> D
    G --> D
    D --> H[segment]
```

The entrypoint [`kube-revamped.tmux`](kube-revamped.tmux) replaces each placeholder in `status-left` and `status-right` with a `#()` call to [`bin/kube-revamped`](bin/kube-revamped), then binds the keys. Each call reads the cache from tmux server options. When the cache is older than `@kube_revamped_interval`, the call starts a detached worker and returns at once, so the render never waits and no temp file is written.

The worker reads every file in `$KUBECONFIG` in order, takes the first `current-context` it finds as kubectl does, and parses the `contexts:` list in [`lib/kubeconfig.awk`](lib/kubeconfig.awk). Each kubectl probe in [`lib/kube.sh`](lib/kube.sh) runs only when its option is `1`, with a 2-second request timeout and a hard 5-second limit. Context and namespace names are shell-quoted and their `#` characters doubled before they reach a menu, a popup or a key binding.

<a id="screens"></a>

## Screens

<details>
<summary>Every screen, recorded inside a real tmux with <code>make screens</code>, with each key on the status line</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/context.png" alt="kube-revamped: The context and its namespace in the status line"><br><sub>The context and its namespace in the status line, from <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/context-menu.png" alt="kube-revamped: prefix M-k opens the context menu"><br><sub><code>prefix M-k</code> opens the context menu, from <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/production.png" alt="kube-revamped: Choosing a context switches to it, and one holding @kube_revamped_prod_pattern turns red"><br><sub>Choosing a context switches to it, and one holding <code>@kube_revamped_prod_pattern</code> turns red, from <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/namespace-menu.png" alt="kube-revamped: prefix M-n, the namespace key, opens the namespace menu"><br><sub><code>prefix M-n</code>, the namespace key, opens the namespace menu, from <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/namespace.png" alt="kube-revamped: Choosing a namespace sets it"><br><sub>Choosing a namespace sets it, from <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/probes.png" alt="kube-revamped: The cluster and the three probes: it answers, ready nodes over all, failing pods"><br><sub>The cluster and the three probes: it answers, ready nodes over all, failing pods, from <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/popup.png" alt="kube-revamped: prefix M-p, the popup key, runs the popup program on the context"><br><sub><code>prefix M-p</code>, the popup key, runs the popup program on the context, from <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/message.png" alt="kube-revamped: A popup program that is not installed is named in a message"><br><sub>A popup program that is not installed is named in a message, from <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/list.png" alt="kube-revamped: list prints every binding"><br><sub><code>list</code> prints every binding, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/status.png" alt="kube-revamped: status kube prints the segment"><br><sub><code>status kube</code> prints the segment, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="kube-revamped: doctor"><br><sub><code>doctor</code>, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="kube-revamped: The menu without gum"><br><sub>The menu without gum, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="kube-revamped: doctor from the menu"><br><sub><code>doctor</code> from the menu, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/version.png" alt="kube-revamped: The version"><br><sub>The version, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/error.png" alt="kube-revamped: An unknown command"><br><sub>An unknown command, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/accent.png" alt="kube-revamped: An accent from KUBE_REVAMPED_ACCENT"><br><sub>An accent from <code>KUBE_REVAMPED_ACCENT</code>, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/themes.png" alt="kube-revamped: The header in six themes"><br><sub>The header in six themes, from <code>themes.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/help.png" alt="kube-revamped: The help page"><br><sub>The help page, from <code>help.tape</code></sub></td>
</tr>
</table>

The recordings run the real plugin, tmux and kubectl on a kubeconfig made for them. A small script answers for the cluster, and `pods` is the popup program.

</details>

## Portability

The plugin is POSIX `sh`. CI runs every suite on each row below.

| Shell | Status |
|:------|:-------|
| `dash`, `/bin/sh` on macOS | Supported |
| `bash` 3.2 and 5.x, the system's `zsh` and Homebrew's | Supported |

| System | Status |
|:-------|:-------|
| macOS | Tahoe on Apple Silicon and Intel, with the tools it ships, Homebrew's GNU tools and Homebrew's uutils |
| Linux | Ubuntu 26.04 on x86_64 and arm64, with GNU coreutils, uutils and BusyBox |

## Development

| Command | What it runs |
|:--------|:-------------|
| `make fmt` | shfmt `-i 2` on every script |
| `make lint` | shfmt, ShellCheck, mandoc, yamllint and actionlint, at zero findings |
| `make test` | The bats suites under the system `sh` |
| `make test-all` | The suites under every installed shell, both builds of bash and zsh on macOS |
| `make test-linux` | The suites in an Ubuntu container |
| `make coverage` | bashcov on this Mac and in the Ubuntu container, merged and gated at 100 percent |
| `make screens` | The screens above, recorded from the real plugin inside tmux with VHS, on macOS |
| `make install` | The command, its man page and completions under `PREFIX` |

On macOS, `brew bundle` installs every tool these targets call, from the [`Brewfile`](Brewfile).

Commits follow the conventional commit format and go straight to `main`. After a green `ci` run on `main`, `release.yml` runs semantic-release: every `feat` or `fix` since the last tag publishes a release, stamps the version constant and adds the notes to [`CHANGELOG.md`](CHANGELOG.md).

## License

[MIT](LICENSE), copyright Gustavo Franco.

<!-- family:begin -->

## The tmux-revamped family

This plugin is one member of the tmux-revamped family. Every member carries the same contract in [`FAMILY.md`](FAMILY.md) and the same shared library, and they are built to be installed together: no member claims a key or a tmux option that another member claims.

A defect found in one member is hunted across all of them before the fix is called done.

| Member | What it does |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | Edit your tmux config, save, and watch it reload itself, no key, no command |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | Battery status for your tmux status bar, without ever blocking the status render |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | Every connected Bluetooth device and its battery in your tmux status bar, without blocking the render |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | CPU load, temperature, and frequency in your tmux status bar, without ever blocking the render |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | Disk usage for your tmux status bar, without ever blocking the status render |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | Pick a URL, path, hash or any other token off the screen with fzf and type it at the cursor, in pure shell |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | Switch to, kill, rename or create tmux sessions, windows and panes from fzf pickers in a popup |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | Show the active pane's git branch, changes and provider counts in the tmux status bar without blocking it |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | GPU load, temperature, clock, power and memory in the tmux status bar, from NVIDIA, AMD, Intel and Apple GPUs |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | **this plugin**, Current Kubernetes context and namespace in the tmux status bar, parsed from kubeconfig without kubectl |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | Open any terminal app in a tmux popup, window or split from one menu, starting at the project root |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | Capture any pane to a file: live logging, full scrollback, or a one-shot screenshot |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | Now playing in your tmux status bar, without ever blocking the status render |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | Network throughput in your tmux status bar, without ever blocking the render |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | Pane and window management bindings for tmux, version aware, vim friendly, every prefix key can be disabled |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | Save every tmux session, window and pane, auto-save on a timer, and restore it all after a reboot |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | The starting point for a tmux-revamped plugin: shared library, bats harness and CI |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | A Pomodoro timer in the tmux status bar that keeps all of its state in tmux options, with no temp files |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM, swap and memory pressure in the tmux status bar, sampled in the background so the render never waits |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | Drag a window tab along the tmux status bar with the mouse to move that window |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | Send the mouse wheel to apps that scroll themselves and into tmux copy-mode everywhere else |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | Sensible tmux defaults, gated by tmux version and terminal, that leave the options you set alone |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | Tiling window management for tmux: eight layouts including BSP dwindle and spiral, with layout undo |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | Local and world clocks for the tmux status bar, colored by time of day, with countdowns and a DST warning |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | Weather for the tmux status bar from wttr.in, fetched in the background so the status line never waits |

<!-- family:end -->
