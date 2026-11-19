<div align="center">

# tmux-kube-revamped

<strong>在 tmux 狀態列顯示目前的 Kubernetes 上下文及命名空間，毋須 kubectl，直接解析 kubeconfig。</strong>

[English](README.md) &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; 繁體中文（香港）

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-kube-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-kube-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-kube-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-kube-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-kube-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-kube-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-kube-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#快速開始"><strong>快速開始</strong></a> &nbsp;|&nbsp;
  <a href="#用法">用法</a> &nbsp;|&nbsp;
  <a href="#運作原理">運作原理</a> &nbsp;|&nbsp;
  <a href="#畫面">畫面</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="kube-revamped 在狀態列顯示上下文，從選單切換上下文及命名空間，開啟探測，並開啟彈出視窗" width="800">
</p>

```console
$ kube-revamped refresh
Refreshed. The context is staging in the namespace payments.
$ kube-revamped status kube
#[fg=blue]staging:payments#[default]
```

**3** 個狀態佔位符、**2** 個切換選單及一個 k9s 彈出視窗，預設的狀態段從不啟動 kubectl。

---

## 快速開始

### 前提條件

| 工具 | 版本 | 用途 |
|:-----|:--------|:---------|
| tmux | 3.2 或以上 | 家族的最低版本，彈出視窗亦需要它 |
| kubeconfig | 任何 | `$KUBECONFIG` 中的每個檔案，或 `~/.kube/config`：上下文、命名空間、叢集及使用者 |
| `kubectl` | 可選 | 命名空間選單、切換及探測 |
| [k9s](https://k9scli.io) | 可選 | 彈出視窗，或 `@kube_revamped_popup_command` 中設定的任何程式 |
| gum | 可選 | `kube-revamped` 的選單、表格及顏色；沒有它，所有命令都輸出純文字 |

### 安裝

使用 [TPM](https://github.com/tmux-plugins/tpm) 時，將插件加入 `~/.tmux.conf`，然後按 `prefix + I`：

```tmux
set -g @plugin 'tmux-revamped/tmux-kube-revamped'
```

不使用 TPM 時，複製儲存庫，並在 `~/.tmux.conf` 中執行入口腳本：

```sh
git clone https://github.com/tmux-revamped/tmux-kube-revamped ~/.tmux/plugins/tmux-kube-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-kube-revamped/kube-revamped.tmux
```

請在插件載入之前設定 `status-left` 或 `status-right`，因為入口腳本執行時會取代這兩個選項中的佔位符。

在複製的目錄中執行 `make install`，亦會把 `kube-revamped` 放入 `~/.local/bin`，並把它的 man 手冊和自動完成放在 `~/.local/share` 下。

### 驗證

```bash
~/.tmux/plugins/tmux-kube-revamped/bin/kube-revamped doctor
```

## 用法

在狀態行放入 `#{kube}`，便會顯示目前的上下文及命名空間，例如 `prod-ctx:web`。插件以 awk 解析 kubeconfig，因此在沒有安裝 kubectl 的主機上，狀態段同樣可以運作。

| 佔位符 | 輸出 |
|:------------|:-------|
| `#{kube}` | 帶樣式的狀態段：上下文、可選的 `@cluster`、`:namespace`、可選的用戶，以及已啟用的健康徽章 |
| `#{kube_context}` | 只有目前的上下文名稱 |
| `#{kube_namespace}` | 只有目前的命名空間，上下文沒有設定命名空間時為 `default` |

未設定目前上下文時，狀態段為空。若目前上下文在 kubeconfig 中找不到對應項目，會以 `@kube_revamped_warn_color` 顯示，並在其後加上 `@kube_revamped_warn_icon`，而不顯示命名空間。

三個健康徽章都要自行啟用，因為每個徽章都會呼叫叢集：

| 徽章 | 探測 | 顯示內容 |
|:------|:------|:------|
| 可達性 | `kubectl cluster-info` | 有回應時顯示綠色 `o`，沒有回應時顯示紅色 `x` |
| 節點 | `kubectl get nodes` | 就緒數與總數，例如 `3/3`；全部就緒時為綠色，否則為警告色 |
| Pod | 目前命名空間中的 `kubectl get pods` | 警告色的 `!N`，N 為既非 `Running` 亦非 `Completed` 的 Pod 數目；為零時隱藏 |

```tmux
set -g status-right '#{kube} | %H:%M'
set -g @kube_revamped_prod_pattern 'prod'
set -g @kube_revamped_probe_reach '1'
```

按 `prefix + M-k` 會開啟一個選單，列出 kubeconfig 中的所有上下文。選擇其中一個會執行 `kubectl config use-context`，並即時更新快取。命名空間選單及 k9s 彈出視窗在分別設定按鍵之前不會綁定：

```tmux
set -g @kube_revamped_menu_namespace_key 'M-n'
set -g @kube_revamped_popup_key 'K'
```

命名空間選單在按鍵時向叢集查詢命名空間，因此會在 kubectl 回應或 2 秒請求逾時之後才開啟。選擇其中一個會執行 `kubectl config set-context --current --namespace`。彈出視窗針對快取中的上下文執行 `k9s --context <context> --namespace <namespace>`。沒有內容可顯示的按鍵會以一則 tmux 訊息說明原因：kubeconfig 中沒有上下文、kubectl 沒有列出命名空間、尚未有目前的上下文，或彈出視窗的指令未安裝。

| 命令 | 作用 |
|:--------|:-------------|
| `kube-revamped apply` | 立即綁定按鍵並替換佔位符；插件載入時入口點會執行它 |
| `kube-revamped list` | 列印 `apply` 會傳送的每條命令，不作任何修改；`--json` 輸出一個物件 |
| `kube-revamped status NAME` | 列印一個佔位符：`kube`、`context` 或 `namespace`；狀態列會執行它 |
| `kube-revamped refresh` | 立即讀取 kubeconfig，並說明讀到的內容 |
| `kube-revamped use-context NAME` | 把 kubectl 切換到某個上下文 |
| `kube-revamped use-namespace NAME` | 設定目前上下文的命名空間 |
| `kube-revamped menu-context` | 在 tmux 中開啟上下文選單 |
| `kube-revamped menu-namespace` | 在 tmux 中開啟命名空間選單 |
| `kube-revamped popup` | 針對目前的上下文開啟彈出視窗的程式 |
| `kube-revamped doctor` | 每個依賴一行，包括每個 kubeconfig 檔案、目前的上下文、`kubectl`、彈出視窗的程式及保持不動的按鍵 |
| `kube-revamped version` | 版本，然後是 tmux 版本 |
| `kube-revamped help` | 說明頁；`man kube-revamped` 記錄相同的命令及設定 |
| `kube-revamped` | 在終端機上顯示選單 |

## 設定

| 選項 | 預設值 | 意思 |
|:-------|:--------|:--------|
| `@kube_revamped_interval` | `10` | 快取的上下文維持有效的秒數 |
| `@kube_revamped_icon` | 空 | 顯示在上下文之前的文字，例如 Nerd Font 圖示 |
| `@kube_revamped_color` | `#[fg=blue]` | 狀態段樣式 |
| `@kube_revamped_show_namespace` | `1` | 設為 `0` 時顯示上下文而不帶 `:namespace` |
| `@kube_revamped_hide_default` | `0` | 設為 `1` 時，在上下文名為 `default` 時隱藏 `#{kube}` |
| `@kube_revamped_show_cluster` | `0` | 設為 `1` 時在上下文後加上 `@cluster` |
| `@kube_revamped_show_user` | `0` | 設為 `1` 時在狀態段後加上 ` (user)` |
| `@kube_revamped_prod_pattern` | 空 | 將上下文標示為正式環境的子字串 |
| `@kube_revamped_prod_color` | `#[fg=red]` | 上下文包含正式環境模式時的狀態段樣式 |
| `@kube_revamped_warn_color` | `#[fg=yellow]` | 缺失的上下文及異常徽章的樣式 |
| `@kube_revamped_warn_icon` | `?` | 加在 kubeconfig 中缺失的上下文之後的標記 |
| `@kube_revamped_menu_context_key` | `M-k` | 上下文選單的按鍵；設為 `off` 時不綁定 |
| `@kube_revamped_menu_namespace_key` | 空 | 命名空間選單的按鍵 |
| `@kube_revamped_popup_key` | 空 | 彈出視窗的按鍵 |
| `@kube_revamped_popup_command` | `k9s` | 在彈出視窗中執行的指令，其後加上 `--context` 及 `--namespace` |
| `@kube_revamped_popup_width` | `80%` | 彈出視窗闊度 |
| `@kube_revamped_popup_height` | `80%` | 彈出視窗高度 |
| `@kube_revamped_probe_reach` | `0` | 設為 `1` 時啟用可達性徽章 |
| `@kube_revamped_probe_nodes` | `0` | 設為 `1` 時啟用節點徽章 |
| `@kube_revamped_probe_pods` | `0` | 設為 `1` 時啟用 Pod 徽章 |

每個選項亦可用帶連字號的命令選項（例如 `--interval 30`）及環境變數（例如 `KUBE_REVAMPED_INTERVAL`）設定；命令列優先於環境變數，環境變數優先於 tmux 選項。空的 tmux 選項表示使用預設值。`doctor` 會指出數值無法識別的設定。傳給 `apply` 的選項會隨每個綁定、每個選單項目及每次狀態呼叫一同生效。

### 內部狀態

以下選項由插件自行管理，請勿設定。

| 選項 | 儲存內容 |
|:-------|:------|
| `@kube_revamped_value` | 快取的 `context\|namespace` 組合 |
| `@kube_revamped_dangling` | 目前上下文在 kubeconfig 中缺失時為 `1` |
| `@kube_revamped_cluster` | 目前上下文的叢集 |
| `@kube_revamped_user` | 目前上下文的用戶 |
| `@kube_revamped_reach` | 可達性探測的結果 `up` 或 `down` |
| `@kube_revamped_nodes` | 節點探測所得的就緒節點數與總數 |
| `@kube_revamped_pods` | 既非執行中亦非已完成的 Pod 數目 |
| `@kube_revamped_value_lock` | 背景更新執行期間為 `1` |

`@kube_revamped_value_ts` 儲存寫入讀數時的 Unix 時間，`@kube_revamped_value_lock_ts` 儲存取得鎖定時的 Unix 時間。

## 按鍵綁定

| 按鍵 | 動作 | 預設 |
|:----|:-------|:--------|
| `prefix + M-k` | 上下文選單 | 已綁定 |
| `@kube_revamped_menu_namespace_key` | 命名空間選單 | 未綁定 |
| `@kube_revamped_popup_key` | k9s 彈出視窗 | 未綁定 |

`M-k` 是家族按鍵分配中分給本插件的位置。2.0.0 版之前，上下文選單沒有預設按鍵。如要保持不綁定：

```tmux
set -g @kube_revamped_menu_context_key 'off'
```

<a id="運作原理"></a>

## 運作原理

```mermaid
graph LR
    A[狀態列繪製] --> B[bin/kube-revamped]
    B --> C{快取是否有效}
    C -->|是| D[tmux 選項]
    C -->|否| E[背景工作程序]
    E --> F[解析 kubeconfig]
    E --> G[可選的 kubectl 探測]
    F --> D
    G --> D
    D --> H[狀態段]
```

入口腳本 [`kube-revamped.tmux`](kube-revamped.tmux) 將 `status-left` 及 `status-right` 中的每個佔位符取代為呼叫 [`bin/kube-revamped`](bin/kube-revamped) 的 `#()`，然後綁定按鍵。每次呼叫都從 tmux 伺服器選項讀取快取。快取比 `@kube_revamped_interval` 更舊時，呼叫會啟動一個脫離的工作程序並即時返回，因此繪製從不等待，亦不會寫入暫存檔。

工作程序按次序讀取 `$KUBECONFIG` 中的每個檔案，與 kubectl 一樣採用找到的第一個 `current-context`，並在 [`lib/kubeconfig.awk`](lib/kubeconfig.awk) 中解析 `contexts:` 清單。[`lib/kube.sh`](lib/kube.sh) 中的每個 kubectl 探測只會在對應選項為 `1` 時執行，並設有 2 秒請求逾時及 5 秒硬性上限。上下文及命名空間名稱在傳入選單、彈出視窗或按鍵綁定之前，會經過 shell 引號處理，並將 `#` 字元加倍。

<a id="畫面"></a>

## 畫面

<details>
<summary>所有畫面，在真實的 tmux 中以 <code>make screens</code> 錄製，每個按鍵顯示在狀態列上</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/context.png" alt="kube-revamped：狀態列中的上下文及命名空間"><br><sub>狀態列中的上下文及命名空間，來自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/context-menu.png" alt="kube-revamped：prefix M-k 開啟上下文選單"><br><sub><code>prefix M-k</code> 開啟上下文選單，來自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/production.png" alt="kube-revamped：選擇上下文即可切換，包含 @kube_revamped_prod_pattern 的上下文顯示為紅色"><br><sub>選擇上下文即可切換，包含 <code>@kube_revamped_prod_pattern</code> 的上下文顯示為紅色，來自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/namespace-menu.png" alt="kube-revamped：命名空間鍵 prefix M-n 開啟命名空間選單"><br><sub>命名空間鍵 <code>prefix M-n</code> 開啟命名空間選單，來自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/namespace.png" alt="kube-revamped：選擇命名空間即可設定"><br><sub>選擇命名空間即可設定，來自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/probes.png" alt="kube-revamped：叢集及三項探測：是否回應、就緒節點數與總數、失敗的 Pod 數目"><br><sub>叢集及三項探測：是否回應、就緒節點數與總數、失敗的 Pod 數目，來自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/popup.png" alt="kube-revamped：彈出視窗鍵 prefix M-p 針對上下文執行彈出視窗的程式"><br><sub>彈出視窗鍵 <code>prefix M-p</code> 針對上下文執行彈出視窗的程式，來自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/message.png" alt="kube-revamped：未安裝的彈出視窗程式會在訊息中指出"><br><sub>未安裝的彈出視窗程式會在訊息中指出，來自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/list.png" alt="kube-revamped：list 列印每個綁定"><br><sub><code>list</code> 列印每個綁定，來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/status.png" alt="kube-revamped：status kube 列印狀態片段"><br><sub><code>status kube</code> 列印狀態片段，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="kube-revamped：doctor"><br><sub><code>doctor</code>，來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="kube-revamped：沒有 gum 的選單"><br><sub>沒有 gum 的選單，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="kube-revamped：從選單執行 doctor"><br><sub>從選單執行 <code>doctor</code>，來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/version.png" alt="kube-revamped：版本"><br><sub>版本，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/error.png" alt="kube-revamped：未知命令"><br><sub>未知命令，來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/accent.png" alt="kube-revamped：來自 KUBE_REVAMPED_ACCENT 的強調色"><br><sub>來自 <code>KUBE_REVAMPED_ACCENT</code> 的強調色，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/themes.png" alt="kube-revamped：六種主題下的標題"><br><sub>六種主題下的標題，來自 <code>themes.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/help.png" alt="kube-revamped：說明頁"><br><sub>說明頁，來自 <code>help.tape</code></sub></td>
</tr>
</table>

錄製時，真實的插件、tmux 及 kubectl 在專門準備的 kubeconfig 上執行。叢集的回應由一個小腳本提供，彈出視窗的程式是 `pods`。

</details>

## 可攜性

插件是 POSIX `sh`。CI 在下列每一行上執行全部測試。

| Shell | 狀態 |
|:------|:-------|
| `dash`、macOS 上的 `/bin/sh` | 支援 |
| `bash` 3.2 和 5.x、系統內建的 `zsh` 和 Homebrew 的 `zsh` | 支援 |

| 系統 | 狀態 |
|:-------|:-------|
| macOS | Apple Silicon 和 Intel 上的 Tahoe，使用內建的工具、Homebrew 的 GNU 工具和 Homebrew 的 uutils |
| Linux | x86_64 和 arm64 上的 Ubuntu 26.04，使用 GNU coreutils、uutils 和 BusyBox |

## 開發

| 指令 | 執行內容 |
|:--------|:-------------|
| `make fmt` | 對每個腳本執行 shfmt `-i 2` |
| `make lint` | shfmt、ShellCheck、mandoc、yamllint 和 actionlint，零警告 |
| `make test` | 在系統 `sh` 下執行 bats 測試 |
| `make test-all` | 在每個已安裝的 shell 下執行測試，macOS 上包括 bash 和 zsh 的兩種版本 |
| `make test-linux` | 在 Ubuntu 容器中執行測試 |
| `make coverage` | 在這部 Mac 和 Ubuntu 容器中執行 bashcov，合併後以 100% 為門檻 |
| `make screens` | 以 VHS 在 tmux 中從真實插件錄製上述畫面，在 macOS 上執行 |
| `make install` | 把指令、man 手冊和自動完成安裝到 `PREFIX` 下 |

在 macOS 上，執行 `brew bundle` 會根據 [`Brewfile`](Brewfile) 安裝這些目標用到的所有工具。

提交遵循 Conventional Commits 格式，直接進入 `main`。`main` 上的 `ci` 通過後，`release.yml` 會執行 semantic-release：自上一個標籤以來的每個 `feat` 或 `fix` 都會發佈新版本，更新版本常數，並把說明寫入 [`CHANGELOG.md`](CHANGELOG.md)。

## 授權

[MIT](LICENSE)，copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped 插件家族

這個插件是 tmux-revamped 插件家族的一員。每個成員都帶有 [`FAMILY.md`](FAMILY.md) 中相同的約定和相同的共用程式庫，並且設計為一起安裝：沒有成員佔用另一個成員佔用的按鍵或 tmux 選項。

在一個成員中發現的缺陷，要在全部成員中排查後才算修正完成。

| 成員 | 功能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | 編輯並儲存 tmux 設定後，它會自動重新載入，毋須按鍵，也毋須指令 |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | 在 tmux 狀態列顯示電池狀態，從不阻塞狀態列繪製 |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 在 tmux 狀態列顯示每部已連接的藍牙裝置及其電量，不阻塞繪製 |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | 在 tmux 狀態列顯示 CPU 負載、溫度及頻率，從不阻塞繪製 |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | 在 tmux 狀態列顯示磁碟用量，從不阻塞狀態列繪製 |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 用 fzf 從畫面上揀選 URL、路徑、雜湊值或任何其他字詞，並輸入到游標位置，全部以純 shell 實現 |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | 在彈出視窗的 fzf 選擇器中切換、關閉、重新命名或建立 tmux 工作階段、視窗和窗格 |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | 在 tmux 狀態列顯示當前窗格的 git 分支、改動和託管平台數目，而不會阻塞顯示 |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | 在 tmux 狀態列顯示 NVIDIA、AMD、Intel 及 Apple GPU 的負載、溫度、時脈、功耗及記憶體 |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | **本插件**，在 tmux 狀態列顯示目前的 Kubernetes 上下文及命名空間，毋須 kubectl，直接解析 kubeconfig |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 在彈出視窗或新視窗中啟動任何 TUI 應用程式，從目前窗格的目錄開始，每個應用程式可設定一個按鍵 |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 將任何窗格儲存到檔案：即時記錄、完整捲動緩衝區或一次性截圖 |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 在 tmux 狀態列顯示正在播放的歌曲，從不阻塞狀態列的繪製 |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | 在 tmux 狀態列顯示網絡傳輸量，從不阻塞繪製 |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux 的窗格和視窗管理按鍵，配合 tmux 版本，與 vim 相容，每個 prefix 按鍵都可停用 |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | 儲存 tmux 的所有工作階段、視窗及窗格，按計時器自動儲存，並在重新開機後全部還原 |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起點：共用程式庫、bats 測試框架和 CI |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | tmux 狀態列中的番茄鐘計時器，所有狀態都儲存在 tmux 選項中，不使用暫存檔 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 狀態列顯示記憶體、交換空間及記憶體壓力，在背景取樣，繪製從不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用滑鼠在 tmux 狀態列上拖動視窗標籤來移動該視窗 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 將滑鼠滾輪交給能自行捲動的應用程式，其他情況下進入 tmux 複製模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | 按 tmux 版本和終端機區分的合理預設設定，不會改動你自己設定的選項 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平鋪視窗管理：八種版面，包括 BSP dwindle 和 spiral，並支援復原版面 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 狀態列中的本地時鐘和世界時鐘，按一天中的時段著色，並提供倒數和夏令時間提示 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在背景從 wttr.in 取得天氣並顯示在狀態列，狀態列毋須等待 |

<!-- family:end -->
