<div align="center">

# tmux-kube-revamped

<strong>在 tmux 状态栏中显示当前的 Kubernetes 上下文和命名空间，不依赖 kubectl，直接解析 kubeconfig。</strong>

[English](README.md) &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; 简体中文 &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-kube-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-kube-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-kube-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-kube-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-kube-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-kube-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-kube-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#快速开始"><strong>快速开始</strong></a> &nbsp;|&nbsp;
  <a href="#用法">用法</a> &nbsp;|&nbsp;
  <a href="#工作原理">工作原理</a> &nbsp;|&nbsp;
  <a href="#界面">界面</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="kube-revamped 在状态栏中显示上下文，从菜单切换上下文和命名空间，开启探测，并打开弹窗" width="800">
</p>

```console
$ kube-revamped refresh
Refreshed. The context is staging in the namespace payments.
$ kube-revamped status kube
#[fg=blue]staging:payments#[default]
```

**3** 个状态占位符、**2** 个切换菜单和一个 k9s 弹出窗口，默认的状态段从不启动 kubectl。

---

## 快速开始

### 前提条件

| 工具 | 版本 | 用途 |
|:-----|:--------|:---------|
| tmux | 3.2 或更高 | 家族的最低版本，弹窗也需要它 |
| kubeconfig | 任意 | `$KUBECONFIG` 中的每个文件，或 `~/.kube/config`：上下文、命名空间、集群和用户 |
| `kubectl` | 可选 | 命名空间菜单、切换和探测 |
| [k9s](https://k9scli.io) | 可选 | 弹窗，或 `@kube_revamped_popup_command` 中设置的任何程序 |
| gum | 可选 | `kube-revamped` 的菜单、表格和颜色；没有它，所有命令都输出纯文本 |

### 安装

使用 [TPM](https://github.com/tmux-plugins/tpm) 时，将插件添加到 `~/.tmux.conf`，然后按 `prefix + I`：

```tmux
set -g @plugin 'tmux-revamped/tmux-kube-revamped'
```

不使用 TPM 时，克隆仓库并在 `~/.tmux.conf` 中运行入口脚本：

```sh
git clone https://github.com/tmux-revamped/tmux-kube-revamped ~/.tmux/plugins/tmux-kube-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-kube-revamped/kube-revamped.tmux
```

请在插件加载之前设置 `status-left` 或 `status-right`，因为入口脚本在运行时会替换这两个选项中的占位符。

在克隆的目录中运行 `make install`，还会把 `kube-revamped` 放进 `~/.local/bin`，把它的 man 手册和补全放在 `~/.local/share` 下。

### 验证

```bash
~/.tmux/plugins/tmux-kube-revamped/bin/kube-revamped doctor
```

## 用法

在状态行中放入 `#{kube}`，即可显示当前的上下文和命名空间，例如 `prod-ctx:web`。插件用 awk 解析 kubeconfig，因此在未安装 kubectl 的主机上，状态段同样可以工作。

| 占位符 | 输出 |
|:------------|:-------|
| `#{kube}` | 带样式的状态段：上下文、可选的 `@cluster`、`:namespace`、可选的用户，以及已启用的健康徽章 |
| `#{kube_context}` | 仅当前上下文名称 |
| `#{kube_namespace}` | 仅当前命名空间，上下文未设置命名空间时为 `default` |

未设置当前上下文时，状态段为空。如果当前上下文在 kubeconfig 中找不到对应条目，则以 `@kube_revamped_warn_color` 显示，并在其后附加 `@kube_revamped_warn_icon`，而不显示命名空间。

三个健康徽章都需要手动开启，因为每个徽章都会调用集群：

| 徽章 | 探测 | 显示内容 |
|:------|:------|:------|
| 可达性 | `kubectl cluster-info` | 有响应时显示绿色 `o`，无响应时显示红色 `x` |
| 节点 | `kubectl get nodes` | 就绪数与总数，例如 `3/3`；全部就绪时为绿色，否则为警告色 |
| Pod | 当前命名空间中的 `kubectl get pods` | 警告色的 `!N`，N 为既不是 `Running` 也不是 `Completed` 的 Pod 数；为零时隐藏 |

```tmux
set -g status-right '#{kube} | %H:%M'
set -g @kube_revamped_prod_pattern 'prod'
set -g @kube_revamped_probe_reach '1'
```

按 `prefix + M-k` 会打开一个菜单，列出 kubeconfig 中的所有上下文。选择其中一个会运行 `kubectl config use-context`，并立即更新缓存。命名空间菜单和 k9s 弹出窗口在分别设置按键之前不会绑定：

```tmux
set -g @kube_revamped_menu_namespace_key 'M-n'
set -g @kube_revamped_popup_key 'K'
```

命名空间菜单在按键时向集群查询命名空间，因此会在 kubectl 响应或 2 秒请求超时之后打开。选择其中一个会运行 `kubectl config set-context --current --namespace`。弹出窗口针对缓存中的上下文运行 `k9s --context <context> --namespace <namespace>`。没有内容可显示的按键会用一条 tmux 消息说明原因：kubeconfig 中没有上下文、kubectl 没有列出命名空间、尚无当前上下文，或弹出窗口的命令未安装。

| 命令 | 作用 |
|:--------|:-------------|
| `kube-revamped apply` | 立即绑定按键并替换占位符；插件加载时入口点会运行它 |
| `kube-revamped list` | 打印 `apply` 会发送的每条命令，不做任何修改；`--json` 输出一个对象 |
| `kube-revamped status NAME` | 打印一个占位符：`kube`、`context` 或 `namespace`；状态栏会运行它 |
| `kube-revamped refresh` | 立即读取 kubeconfig，并说明读到的内容 |
| `kube-revamped use-context NAME` | 把 kubectl 切换到某个上下文 |
| `kube-revamped use-namespace NAME` | 设置当前上下文的命名空间 |
| `kube-revamped menu-context` | 在 tmux 中打开上下文菜单 |
| `kube-revamped menu-namespace` | 在 tmux 中打开命名空间菜单 |
| `kube-revamped popup` | 针对当前上下文打开弹窗程序 |
| `kube-revamped doctor` | 每个依赖一行，包括每个 kubeconfig 文件、当前上下文、`kubectl`、弹窗程序和保持不动的按键 |
| `kube-revamped version` | 版本，然后是 tmux 版本 |
| `kube-revamped help` | 帮助页；`man kube-revamped` 记录相同的命令和设置 |
| `kube-revamped` | 在终端上显示菜单 |

## 配置

| 选项 | 默认值 | 含义 |
|:-------|:--------|:--------|
| `@kube_revamped_interval` | `10` | 缓存的上下文保持有效的秒数 |
| `@kube_revamped_icon` | 空 | 显示在上下文之前的文本，例如 Nerd Font 图标 |
| `@kube_revamped_color` | `#[fg=blue]` | 状态段样式 |
| `@kube_revamped_show_namespace` | `1` | 设为 `0` 时显示上下文而不带 `:namespace` |
| `@kube_revamped_hide_default` | `0` | 设为 `1` 时，在上下文名为 `default` 时隐藏 `#{kube}` |
| `@kube_revamped_show_cluster` | `0` | 设为 `1` 时在上下文后附加 `@cluster` |
| `@kube_revamped_show_user` | `0` | 设为 `1` 时在状态段后附加 ` (user)` |
| `@kube_revamped_prod_pattern` | 空 | 将上下文标记为生产环境的子字符串 |
| `@kube_revamped_prod_color` | `#[fg=red]` | 上下文包含生产模式时的状态段样式 |
| `@kube_revamped_warn_color` | `#[fg=yellow]` | 缺失的上下文和异常徽章的样式 |
| `@kube_revamped_warn_icon` | `?` | 附加在 kubeconfig 中缺失的上下文之后的标记 |
| `@kube_revamped_menu_context_key` | `M-k` | 上下文菜单的按键；设为 `off` 时不绑定 |
| `@kube_revamped_menu_namespace_key` | 空 | 命名空间菜单的按键 |
| `@kube_revamped_popup_key` | 空 | 弹出窗口的按键 |
| `@kube_revamped_popup_command` | `k9s` | 在弹出窗口中运行的命令，其后附加 `--context` 和 `--namespace` |
| `@kube_revamped_popup_width` | `80%` | 弹出窗口宽度 |
| `@kube_revamped_popup_height` | `80%` | 弹出窗口高度 |
| `@kube_revamped_probe_reach` | `0` | 设为 `1` 时开启可达性徽章 |
| `@kube_revamped_probe_nodes` | `0` | 设为 `1` 时开启节点徽章 |
| `@kube_revamped_probe_pods` | `0` | 设为 `1` 时开启 Pod 徽章 |

每个选项也可以用带连字符的命令选项（例如 `--interval 30`）和环境变量（例如 `KUBE_REVAMPED_INTERVAL`）设置；命令行优先于环境变量，环境变量优先于 tmux 选项。空的 tmux 选项表示使用默认值。`doctor` 会指出值无法识别的设置。传给 `apply` 的选项会随每个绑定、每个菜单项和每次状态调用一起生效。

### 内部状态

以下选项由插件自行管理，请勿设置。

| 选项 | 保存内容 |
|:-------|:------|
| `@kube_revamped_value` | 缓存的 `context\|namespace` 组合 |
| `@kube_revamped_dangling` | 当前上下文在 kubeconfig 中缺失时为 `1` |
| `@kube_revamped_cluster` | 当前上下文的集群 |
| `@kube_revamped_user` | 当前上下文的用户 |
| `@kube_revamped_reach` | 可达性探测的结果 `up` 或 `down` |
| `@kube_revamped_nodes` | 节点探测得到的就绪节点数与总数 |
| `@kube_revamped_pods` | 既未运行也未完成的 Pod 数 |
| `@kube_revamped_value_lock` | 后台刷新运行期间为 `1` |

`@kube_revamped_value_ts` 保存写入读数时的 Unix 时间，`@kube_revamped_value_lock_ts` 保存取得锁时的 Unix 时间。

## 按键绑定

| 按键 | 操作 | 默认 |
|:----|:-------|:--------|
| `prefix + M-k` | 上下文菜单 | 已绑定 |
| `@kube_revamped_menu_namespace_key` | 命名空间菜单 | 未绑定 |
| `@kube_revamped_popup_key` | k9s 弹出窗口 | 未绑定 |

`M-k` 是家族按键分配中分给本插件的位置。2.0.0 版本之前，上下文菜单没有默认按键。如需保持不绑定：

```tmux
set -g @kube_revamped_menu_context_key 'off'
```

<a id="工作原理"></a>

## 工作原理

```mermaid
graph LR
    A[状态栏渲染] --> B[bin/kube-revamped]
    B --> C{缓存是否新鲜}
    C -->|是| D[tmux 选项]
    C -->|否| E[后台工作进程]
    E --> F[解析 kubeconfig]
    E --> G[可选的 kubectl 探测]
    F --> D
    G --> D
    D --> H[状态段]
```

入口脚本 [`kube-revamped.tmux`](kube-revamped.tmux) 把 `status-left` 和 `status-right` 中的每个占位符替换为调用 [`bin/kube-revamped`](bin/kube-revamped) 的 `#()`，然后绑定按键。每次调用都从 tmux 服务器选项中读取缓存。缓存比 `@kube_revamped_interval` 更旧时，调用会启动一个脱离的工作进程并立即返回，因此渲染从不等待，也不会写入临时文件。

工作进程按顺序读取 `$KUBECONFIG` 中的每个文件，与 kubectl 一样采用找到的第一个 `current-context`，并在 [`lib/kubeconfig.awk`](lib/kubeconfig.awk) 中解析 `contexts:` 列表。[`lib/kube.sh`](lib/kube.sh) 中的每个 kubectl 探测仅在对应选项为 `1` 时运行，带有 2 秒请求超时和 5 秒硬性上限。上下文和命名空间名称在传入菜单、弹出窗口或按键绑定之前，会经过 shell 引用，并将 `#` 字符加倍。

<a id="界面"></a>

## 界面

<details>
<summary>所有界面，在真实的 tmux 中用 <code>make screens</code> 录制，每个按键显示在状态栏上</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/context.png" alt="kube-revamped：状态栏中的上下文和命名空间"><br><sub>状态栏中的上下文和命名空间，来自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/context-menu.png" alt="kube-revamped：prefix M-k 打开上下文菜单"><br><sub><code>prefix M-k</code> 打开上下文菜单，来自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/production.png" alt="kube-revamped：选择上下文即可切换，包含 @kube_revamped_prod_pattern 的上下文显示为红色"><br><sub>选择上下文即可切换，包含 <code>@kube_revamped_prod_pattern</code> 的上下文显示为红色，来自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/namespace-menu.png" alt="kube-revamped：命名空间键 prefix M-n 打开命名空间菜单"><br><sub>命名空间键 <code>prefix M-n</code> 打开命名空间菜单，来自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/namespace.png" alt="kube-revamped：选择命名空间即可设置"><br><sub>选择命名空间即可设置，来自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/probes.png" alt="kube-revamped：集群和三项探测：是否应答、就绪节点数与总数、失败的 Pod 数"><br><sub>集群和三项探测：是否应答、就绪节点数与总数、失败的 Pod 数，来自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/popup.png" alt="kube-revamped：弹窗键 prefix M-p 针对上下文运行弹窗程序"><br><sub>弹窗键 <code>prefix M-p</code> 针对上下文运行弹窗程序，来自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/message.png" alt="kube-revamped：未安装的弹窗程序会在消息中指出"><br><sub>未安装的弹窗程序会在消息中指出，来自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/list.png" alt="kube-revamped：list 打印每个绑定"><br><sub><code>list</code> 打印每个绑定，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/status.png" alt="kube-revamped：status kube 打印状态片段"><br><sub><code>status kube</code> 打印状态片段，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="kube-revamped：doctor"><br><sub><code>doctor</code>，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="kube-revamped：没有 gum 的菜单"><br><sub>没有 gum 的菜单，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="kube-revamped：从菜单运行 doctor"><br><sub>从菜单运行 <code>doctor</code>，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/version.png" alt="kube-revamped：版本"><br><sub>版本，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/error.png" alt="kube-revamped：未知命令"><br><sub>未知命令，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/accent.png" alt="kube-revamped：来自 KUBE_REVAMPED_ACCENT 的强调色"><br><sub>来自 <code>KUBE_REVAMPED_ACCENT</code> 的强调色，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/themes.png" alt="kube-revamped：六种主题下的标题"><br><sub>六种主题下的标题，来自 <code>themes.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/help.png" alt="kube-revamped：帮助页"><br><sub>帮助页，来自 <code>help.tape</code></sub></td>
</tr>
</table>

录制时，真实的插件、tmux 和 kubectl 运行在专门准备的 kubeconfig 上。集群的应答由一个小脚本给出，弹窗程序是 `pods`。

</details>

## 可移植性

插件是 POSIX `sh`。CI 在下面每一行上运行全部测试。

| Shell | 状态 |
|:------|:-------|
| `dash`、macOS 上的 `/bin/sh` | 支持 |
| `bash` 3.2 和 5.x、系统自带的 `zsh` 和 Homebrew 的 `zsh` | 支持 |

| 系统 | 状态 |
|:-------|:-------|
| macOS | Apple Silicon 和 Intel 上的 Tahoe，使用系统自带的工具、Homebrew 的 GNU 工具和 Homebrew 的 uutils |
| Linux | x86_64 和 arm64 上的 Ubuntu 26.04，使用 GNU coreutils、uutils 和 BusyBox |

## 开发

| 命令 | 运行内容 |
|:--------|:-------------|
| `make fmt` | 对每个脚本运行 shfmt `-i 2` |
| `make lint` | shfmt、ShellCheck、mandoc、yamllint 和 actionlint，零告警 |
| `make test` | 在系统 `sh` 下运行 bats 测试 |
| `make test-all` | 在每个已安装的 shell 下运行测试，macOS 上包括 bash 和 zsh 的两种构建 |
| `make test-linux` | 在 Ubuntu 容器中运行测试 |
| `make coverage` | 在这台 Mac 和 Ubuntu 容器中运行 bashcov，合并后以 100% 为门槛 |
| `make screens` | 用 VHS 在 tmux 中从真实插件录制上面的界面，在 macOS 上运行 |
| `make install` | 把命令、man 手册和补全安装到 `PREFIX` 下 |

在 macOS 上，运行 `brew bundle` 会根据 [`Brewfile`](Brewfile) 安装这些目标用到的所有工具。

提交遵循 Conventional Commits 格式，直接进入 `main`。`main` 上的 `ci` 通过后，`release.yml` 运行 semantic-release：自上一个标签以来的每个 `feat` 或 `fix` 都会发布新版本，更新版本常量，并把说明写进 [`CHANGELOG.md`](CHANGELOG.md)。

## 许可证

[MIT](LICENSE)，copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped 插件家族

这个插件是 tmux-revamped 插件家族的一员。每个成员都带有 [`FAMILY.md`](FAMILY.md) 中相同的约定和相同的共享库，并且设计为一起安装：没有成员占用另一个成员占用的按键或 tmux 选项。

在一个成员中发现的缺陷，要在全部成员中排查之后才算修复完成。

| 成员 | 功能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | 编辑并保存 tmux 配置后，它会自动重新加载，无需按键，也无需命令 |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | 在 tmux 状态栏显示电池状态，从不阻塞状态栏渲染 |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 在 tmux 状态栏显示每个已连接的蓝牙设备及其电量，不阻塞渲染 |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | 在 tmux 状态栏显示 CPU 负载、温度和频率，从不阻塞渲染 |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | 在 tmux 状态栏显示磁盘用量，从不阻塞状态栏渲染 |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 用 fzf 从屏幕上挑选 URL、路径、哈希或任意其他词元，并输入到光标处，全部用纯 shell 实现 |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | 在弹出窗口中的 fzf 选择器里切换、关闭、重命名或创建 tmux 会话、窗口和窗格 |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | 在 tmux 状态栏中显示活动窗格的 git 分支、改动和托管平台计数，且不阻塞渲染 |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | 在 tmux 状态栏中显示 NVIDIA、AMD、Intel 和 Apple GPU 的负载、温度、频率、功耗和显存 |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | **本插件**，在 tmux 状态栏中显示当前的 Kubernetes 上下文和命名空间，不依赖 kubectl，直接解析 kubeconfig |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 在弹出窗口或新窗口中启动任意 TUI 应用，从当前窗格的目录开始，每个应用可配置一个按键 |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 将任意窗格保存到文件：实时日志、完整回滚缓冲区或一次性截图 |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 在 tmux 状态栏显示正在播放的曲目，从不阻塞状态栏渲染 |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | 在 tmux 状态栏显示网络吞吐量，从不阻塞渲染 |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux 的窗格和窗口管理按键，适配 tmux 版本，兼容 vim，每个 prefix 按键都可禁用 |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | 保存 tmux 的所有会话、窗口和窗格，按定时器自动保存，并在重启后全部恢复 |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起点：共享库、bats 测试框架和 CI |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | tmux 状态栏中的番茄钟计时器，所有状态都保存在 tmux 选项中，不使用临时文件 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 状态栏显示内存、交换空间和内存压力，在后台采样，渲染从不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用鼠标在 tmux 状态栏上拖动窗口标签来移动该窗口 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 将鼠标滚轮交给能自行滚动的应用，其他情况下进入 tmux 复制模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | 按 tmux 版本和终端区分的合理默认设置，不改动你自己设置的选项 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平铺窗口管理：八种布局，包括 BSP dwindle 和 spiral，并支持撤销布局 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 状态栏中的本地时钟和世界时钟，按一天中的时段着色，并提供倒计时和夏令时提醒 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在后台从 wttr.in 获取天气并显示在状态栏，状态栏无需等待 |

<!-- family:end -->
