<div align="center">

# tmux-kube-revamped

<strong>現在の Kubernetes コンテキストと名前空間を、kubectl を使わずに kubeconfig から解析して tmux のステータスバーに表示します。</strong>

[English](README.md) &nbsp;|&nbsp; 日本語 &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-kube-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-kube-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-kube-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-kube-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-kube-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-kube-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-kube-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#クイックスタート"><strong>クイックスタート</strong></a> &nbsp;|&nbsp;
  <a href="#使い方">使い方</a> &nbsp;|&nbsp;
  <a href="#仕組み">仕組み</a> &nbsp;|&nbsp;
  <a href="#画面">画面</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="ステータスラインにコンテキストを表示し、メニューからコンテキストと名前空間を切り替え、プローブを有効にし、ポップアップを開く kube-revamped" width="800">
</p>

```console
$ kube-revamped refresh
Refreshed. The context is staging in the namespace payments.
$ kube-revamped status kube
#[fg=blue]staging:payments#[default]
```

ステータス用プレースホルダーが **3** 個、切り替えメニューが **2** 個と k9s ポップアップがあり、既定のセグメントは kubectl を一度も起動しません。

---

## クイックスタート

### 前提条件

| ツール | バージョン | 用途 |
|:-----|:--------|:---------|
| tmux | 3.2 以降 | ファミリー共通の最低バージョン。ポップアップにも必要です |
| kubeconfig | 任意 | `$KUBECONFIG` の各ファイル、または `~/.kube/config`。コンテキスト、名前空間、クラスター、ユーザーを読み取ります |
| `kubectl` | 任意 | 名前空間メニュー、切り替え、プローブ |
| [k9s](https://k9scli.io) | 任意 | ポップアップ。`@kube_revamped_popup_command` に設定した別のプログラムでもかまいません |
| gum | 任意 | `kube-revamped` のメニュー、表、色。なくてもすべてのコマンドがプレーンテキストで動きます |

### インストール

[TPM](https://github.com/tmux-plugins/tpm) を使う場合は、`~/.tmux.conf` にプラグインを追加して `prefix + I` を押します。

```tmux
set -g @plugin 'tmux-revamped/tmux-kube-revamped'
```

TPM を使わない場合は、リポジトリをクローンし、`~/.tmux.conf` からエントリポイントを実行します。

```sh
git clone https://github.com/tmux-revamped/tmux-kube-revamped ~/.tmux/plugins/tmux-kube-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-kube-revamped/kube-revamped.tmux
```

エントリポイントは実行時に `status-left` と `status-right` の 2 つのオプション内のプレースホルダーを置き換えるため、これらはプラグインを読み込む前に設定してください。

クローンで `make install` を実行すると、`kube-revamped` が `~/.local/bin` に、manページと補完が `~/.local/share` の下に入ります。

### 確認

```bash
~/.tmux/plugins/tmux-kube-revamped/bin/kube-revamped doctor
```

## 使い方

ステータスラインに `#{kube}` を置くと、`prod-ctx:web` のように現在のコンテキストと名前空間が表示されます。プラグインは awk で kubeconfig を解析するため、kubectl がインストールされていないホストでもセグメントは動作します。

| プレースホルダー | 出力 |
|:------------|:-------|
| `#{kube}` | 装飾付きのセグメント。コンテキスト、任意の `@cluster`、`:namespace`、任意のユーザー、有効なヘルスバッジを含みます |
| `#{kube_context}` | 現在のコンテキスト名のみ |
| `#{kube_namespace}` | 現在の名前空間のみ。コンテキストが名前空間を指定していない場合は `default` |

現在のコンテキストが設定されていない場合、セグメントは空になります。kubeconfig のどのエントリにも一致しない現在のコンテキストは、名前空間の代わりに `@kube_revamped_warn_icon` を後ろに付け、`@kube_revamped_warn_color` で表示されます。

ヘルスバッジは 3 種類あり、それぞれクラスターを呼び出すため、すべてオプトインです。

| バッジ | プローブ | 表示内容 |
|:------|:------|:------|
| 到達性 | `kubectl cluster-info` | 応答があれば緑の `o`、なければ赤の `x` |
| ノード | `kubectl get nodes` | `3/3` のように準備完了数と総数。すべて準備完了なら緑、そうでなければ警告色 |
| Pod | 現在の名前空間での `kubectl get pods` | 警告色の `!N`。N は `Running` でも `Completed` でもない Pod の数で、0 のときは非表示 |

```tmux
set -g status-right '#{kube} | %H:%M'
set -g @kube_revamped_prod_pattern 'prod'
set -g @kube_revamped_probe_reach '1'
```

`prefix + M-k` を押すと、kubeconfig にあるすべてのコンテキストのメニューが開きます。1 つを選ぶと `kubectl config use-context` が実行され、キャッシュがすぐに更新されます。名前空間メニューと k9s ポップアップは、それぞれにキーを割り当てるまでバインドされません。

```tmux
set -g @kube_revamped_menu_namespace_key 'M-n'
set -g @kube_revamped_popup_key 'K'
```

名前空間メニューはキーを押した時点でクラスターに名前空間を問い合わせるため、kubectl が応答するか、2 秒のリクエストタイムアウトが過ぎた後に開きます。1 つを選ぶと `kubectl config set-context --current --namespace` が実行されます。ポップアップは、キャッシュされたコンテキストに対して `k9s --context <context> --namespace <namespace>` を実行します。表示するものがないキーは、その理由を tmux のメッセージで伝えます。kubeconfig にコンテキストがない、kubectl が名前空間を返さない、現在のコンテキストがまだない、ポップアップのコマンドがインストールされていない、のいずれかです。

| コマンド | 動作 |
|:--------|:-------------|
| `kube-revamped apply` | キーを割り当て、プレースホルダーを今すぐ置き換えます。プラグインの読み込み時にエントリーポイントが実行します |
| `kube-revamped list` | `apply` が送るコマンドをすべて表示し、何も変更しません。`--json` で 1 つのオブジェクトを出力します |
| `kube-revamped status NAME` | プレースホルダーを 1 つ出力します。`kube`、`context`、`namespace` のいずれかで、ステータスラインが実行します |
| `kube-revamped refresh` | kubeconfig を今すぐ読み、見つけた内容を表示します |
| `kube-revamped use-context NAME` | kubectl のコンテキストを切り替えます |
| `kube-revamped use-namespace NAME` | 現在のコンテキストの名前空間を設定します |
| `kube-revamped menu-context` | tmux でコンテキストメニューを開きます |
| `kube-revamped menu-namespace` | tmux で名前空間メニューを開きます |
| `kube-revamped popup` | 現在のコンテキストでポップアップのプログラムを開きます |
| `kube-revamped doctor` | 依存関係ごとに 1 行。各 kubeconfig ファイル、現在のコンテキスト、`kubectl`、ポップアップのプログラム、触れなかったキーも含みます |
| `kube-revamped version` | バージョンと tmux のバージョン |
| `kube-revamped help` | ヘルプ。`man kube-revamped` にも同じコマンドと設定があります |
| `kube-revamped` | 端末ではメニュー |

## 設定

| オプション | 既定値 | 意味 |
|:-------|:--------|:--------|
| `@kube_revamped_interval` | `10` | キャッシュしたコンテキストが有効な秒数 |
| `@kube_revamped_icon` | 空 | コンテキストの前に表示するテキスト。Nerd Font のグリフなど |
| `@kube_revamped_color` | `#[fg=blue]` | セグメントのスタイル |
| `@kube_revamped_show_namespace` | `1` | `0` にすると `:namespace` を付けずにコンテキストを表示します |
| `@kube_revamped_hide_default` | `0` | `1` にするとコンテキスト名が `default` のときに `#{kube}` を非表示にします |
| `@kube_revamped_show_cluster` | `0` | `1` にするとコンテキストの後ろに `@cluster` を付けます |
| `@kube_revamped_show_user` | `0` | `1` にするとセグメントの後ろに ` (user)` を付けます |
| `@kube_revamped_prod_pattern` | 空 | コンテキストを本番環境とみなす部分文字列 |
| `@kube_revamped_prod_color` | `#[fg=red]` | コンテキストに本番パターンが含まれるときのセグメントのスタイル |
| `@kube_revamped_warn_color` | `#[fg=yellow]` | 存在しないコンテキストと異常のあるバッジのスタイル |
| `@kube_revamped_warn_icon` | `?` | kubeconfig に存在しないコンテキストの後ろに付ける印 |
| `@kube_revamped_menu_context_key` | `M-k` | コンテキストメニューのキー。`off` にするとバインドしません |
| `@kube_revamped_menu_namespace_key` | 空 | 名前空間メニューのキー |
| `@kube_revamped_popup_key` | 空 | ポップアップのキー |
| `@kube_revamped_popup_command` | `k9s` | ポップアップで実行するコマンド。後ろに `--context` と `--namespace` が付きます |
| `@kube_revamped_popup_width` | `80%` | ポップアップの幅 |
| `@kube_revamped_popup_height` | `80%` | ポップアップの高さ |
| `@kube_revamped_probe_reach` | `0` | `1` にすると到達性バッジを有効にします |
| `@kube_revamped_probe_nodes` | `0` | `1` にするとノードバッジを有効にします |
| `@kube_revamped_probe_pods` | `0` | `1` にすると Pod バッジを有効にします |

どのオプションも、ダッシュ区切りのコマンドオプション（例 `--interval 30`）と環境変数（例 `KUBE_REVAMPED_INTERVAL`）で指定できます。優先順位はコマンドライン、環境変数、tmux オプションの順です。空の tmux オプションは既定値を意味します。`doctor` は、プラグインが認識できない値を持つ設定の名前を表示します。`apply` に渡したものは、すべての割り当て、メニュー項目、ステータスの呼び出しに引き継がれます。

### 内部状態

以下のオプションはプラグインが自ら管理します。設定しないでください。

| オプション | 保持する内容 |
|:-------|:------|
| `@kube_revamped_value` | キャッシュされた `context\|namespace` の組 |
| `@kube_revamped_dangling` | 現在のコンテキストが kubeconfig に存在しないときに `1` |
| `@kube_revamped_cluster` | 現在のコンテキストのクラスター |
| `@kube_revamped_user` | 現在のコンテキストのユーザー |
| `@kube_revamped_reach` | 到達性プローブの結果 `up` または `down` |
| `@kube_revamped_nodes` | ノードプローブによる準備完了ノード数と総数 |
| `@kube_revamped_pods` | 実行中でも完了済みでもない Pod の数 |
| `@kube_revamped_value_lock` | バックグラウンド更新の実行中は `1` |

`@kube_revamped_value_ts` は読み取りを書き込んだ時刻を、`@kube_revamped_value_lock_ts` はロックを取得した時刻を Unix 時間で保持します。

## キーバインド

| キー | 動作 | 既定 |
|:----|:-------|:--------|
| `prefix + M-k` | コンテキストメニュー | バインド済み |
| `@kube_revamped_menu_namespace_key` | 名前空間メニュー | 未バインド |
| `@kube_revamped_popup_key` | k9s ポップアップ | 未バインド |

`M-k` は、ファミリーのキー割り当てでこのプラグインに与えられた枠です。バージョン 2.0.0 より前は、コンテキストメニューに既定のキーはありませんでした。バインドしないままにするには次のように設定します。

```tmux
set -g @kube_revamped_menu_context_key 'off'
```

<a id="仕組み"></a>

## 仕組み

```mermaid
graph LR
    A[ステータスの描画] --> B[bin/kube-revamped]
    B --> C{キャッシュは新しいか}
    C -->|はい| D[tmux オプション]
    C -->|いいえ| E[バックグラウンドワーカー]
    E --> F[kubeconfig の解析]
    E --> G[オプトインの kubectl プローブ]
    F --> D
    G --> D
    D --> H[セグメント]
```

エントリポイント [`kube-revamped.tmux`](kube-revamped.tmux) は、`status-left` と `status-right` の各プレースホルダーを [`bin/kube-revamped`](bin/kube-revamped) を呼ぶ `#()` に置き換え、その後キーをバインドします。各呼び出しは tmux サーバーオプションからキャッシュを読みます。キャッシュが `@kube_revamped_interval` より古い場合、呼び出しは切り離されたワーカーを起動してすぐに戻るため、描画が待たされることはなく、一時ファイルも書き込まれません。

ワーカーは `$KUBECONFIG` のすべてのファイルを順に読み、kubectl と同じく最初に見つかった `current-context` を採用し、[`lib/kubeconfig.awk`](lib/kubeconfig.awk) で `contexts:` の一覧を解析します。[`lib/kube.sh`](lib/kube.sh) の各 kubectl プローブは、対応するオプションが `1` のときだけ、2 秒のリクエストタイムアウトと 5 秒の絶対制限付きで実行されます。コンテキスト名と名前空間名は、メニュー、ポップアップ、キーバインドに渡る前にシェル用にクォートされ、`#` が二重化されます。

<a id="画面"></a>

## 画面

<details>
<summary>すべての画面。本物の tmux の中で <code>make screens</code> で録画し、押したキーをステータスラインに表示しています</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/context.png" alt="kube-revamped: ステータスラインのコンテキストと名前空間"><br><sub>ステータスラインのコンテキストと名前空間。<code>hero.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/context-menu.png" alt="kube-revamped: prefix M-k でコンテキストメニューを開く"><br><sub><code>prefix M-k</code> でコンテキストメニューを開く。<code>hero.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/production.png" alt="kube-revamped: コンテキストを選ぶと切り替わり、@kube_revamped_prod_pattern を含むものは赤くなる"><br><sub>コンテキストを選ぶと切り替わり、<code>@kube_revamped_prod_pattern</code> を含むものは赤くなる。<code>hero.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/namespace-menu.png" alt="kube-revamped: 名前空間のキー prefix M-n で名前空間メニューを開く"><br><sub>名前空間のキー <code>prefix M-n</code> で名前空間メニューを開く。<code>hero.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/namespace.png" alt="kube-revamped: 名前空間を選ぶと設定される"><br><sub>名前空間を選ぶと設定される。<code>hero.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/probes.png" alt="kube-revamped: クラスターと 3 つのプローブ。応答の有無、準備完了ノード数と全ノード数、失敗している Pod の数"><br><sub>クラスターと 3 つのプローブ。応答の有無、準備完了ノード数と全ノード数、失敗している Pod の数。<code>hero.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/popup.png" alt="kube-revamped: ポップアップのキー prefix M-p でコンテキストに対してプログラムを実行する"><br><sub>ポップアップのキー <code>prefix M-p</code> でコンテキストに対してプログラムを実行する。<code>hero.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/message.png" alt="kube-revamped: インストールされていないプログラムはメッセージで知らせる"><br><sub>インストールされていないプログラムはメッセージで知らせる。<code>hero.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/list.png" alt="kube-revamped: list がすべての割り当てを表示する"><br><sub><code>list</code> がすべての割り当てを表示する。<code>stills.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/status.png" alt="kube-revamped: status kube が表示を出力する"><br><sub><code>status kube</code> が表示を出力する。<code>stills.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="kube-revamped: doctor"><br><sub><code>doctor</code>。<code>stills.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="kube-revamped: gum なしのメニュー"><br><sub>gum なしのメニュー。<code>stills.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="kube-revamped: メニューからの doctor"><br><sub>メニューからの <code>doctor</code>。<code>stills.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/version.png" alt="kube-revamped: バージョン"><br><sub>バージョン。<code>stills.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/error.png" alt="kube-revamped: 不明なコマンド"><br><sub>不明なコマンド。<code>stills.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/accent.png" alt="kube-revamped: KUBE_REVAMPED_ACCENT によるアクセント"><br><sub><code>KUBE_REVAMPED_ACCENT</code> によるアクセント。<code>stills.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/themes.png" alt="kube-revamped: 6 つのテーマのヘッダー"><br><sub>6 つのテーマのヘッダー。<code>themes.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/help.png" alt="kube-revamped: ヘルプ"><br><sub>ヘルプ。<code>help.tape</code>より</sub></td>
</tr>
</table>

録画では、専用に用意した kubeconfig の上で本物のプラグイン、tmux、kubectl を動かしています。クラスターの応答は小さなスクリプトが返し、ポップアップのプログラムは `pods` です。

</details>

## 移植性

プラグインは POSIX `sh` です。CI は下の各行ですべてのテストを実行します。

| シェル | 状態 |
|:------|:-------|
| `dash`、macOS の `/bin/sh` | 対応 |
| `bash` 3.2 と 5.x、システムの `zsh` と Homebrew の `zsh` | 対応 |

| システム | 状態 |
|:-------|:-------|
| macOS | Apple Silicon と Intel の Tahoe。付属のツール、Homebrew の GNU ツール、Homebrew の uutils で確認 |
| Linux | x86_64 と arm64 の Ubuntu 26.04。GNU coreutils、uutils、BusyBox で確認 |

## 開発

| コマンド | 実行内容 |
|:--------|:-------------|
| `make fmt` | すべてのスクリプトに shfmt `-i 2` をかけます |
| `make lint` | shfmt、ShellCheck、mandoc、yamllint、actionlint を、指摘ゼロで通します |
| `make test` | システムの `sh` で bats のテスト |
| `make test-all` | インストール済みのすべてのシェルでテスト。macOS では bash と zsh の両方のビルドを含みます |
| `make test-linux` | Ubuntu のコンテナでテスト |
| `make coverage` | この Mac と Ubuntu のコンテナで bashcov を実行し、合算して 100 パーセントで判定します |
| `make screens` | 上の画面を、本物のプラグインから tmux の中で VHS で録画します。macOS で実行します |
| `make install` | コマンド、manページ、補完を `PREFIX` の下に置きます |

macOS では、`brew bundle` を実行すると、これらのターゲットが使うツールがすべて [`Brewfile`](Brewfile) からインストールされます。

コミットは Conventional Commits の形式に従い、そのまま `main` に入ります。`main` で `ci` が成功すると、`release.yml` が semantic-release を実行します。前回のタグ以降に `feat` か `fix` があればリリースを公開し、バージョン定数を更新し、変更内容を [`CHANGELOG.md`](CHANGELOG.md) に追加します。

## ライセンス

[MIT](LICENSE)、copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped ファミリー

このプラグインは tmux-revamped ファミリーの一員です。すべてのメンバーが [`FAMILY.md`](FAMILY.md) の同じ規約と同じ共有ライブラリを持ちます。メンバーは一緒にインストールする前提で作られており、ほかのメンバーが使うキーや tmux オプションを使うメンバーはありません。

あるメンバーで見つかった不具合は、修正完了とする前に全メンバーで同じ不具合を探します。

| メンバー | 機能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | tmuxの設定を編集して保存するだけで、キーもコマンドも使わずに自動で再読み込みされます |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | tmuxのステータスバーに電池の状態を表示し、ステータスの描画を一切止めません |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | 接続中のすべてのBluetooth機器とその電池残量をtmuxのステータスバーに表示し、描画を止めません |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | CPUの負荷、温度、周波数をtmuxのステータスバーに表示し、描画を一切止めません |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | tmuxのステータスバーにディスク使用量を表示し、ステータスの描画を一切止めません |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 画面上の URL、パス、ハッシュなどのトークンを fzf で選び、カーソル位置に入力します。純粋なシェルだけで動きます |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | ポップアップ内の fzf ピッカーから、tmux のセッション、ウィンドウ、ペインの切り替え、終了、名前変更、作成を行います |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | アクティブなペインのgitブランチ、変更、プロバイダーの件数を、描画を止めずにtmuxのステータスバーに表示します |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | NVIDIA、AMD、Intel、Apple の GPU の負荷、温度、クロック、電力、メモリを tmux のステータスバーに表示します |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | **このプラグイン**、現在の Kubernetes コンテキストと名前空間を、kubectl を使わずに kubeconfig から解析して tmux のステータスバーに表示します |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 任意の TUI アプリを、現在のペインのディレクトリでポップアップまたはウィンドウとして起動します。アプリごとにキーを設定できます |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 任意のペインをファイルに保存します。ライブのログ記録、スクロールバック全体、1 回限りのスクリーンショットに対応します |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 再生中の曲をステータスバーに表示し、ステータスの描画を止めません |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | ネットワークのスループットをステータスバーに表示し、描画を止めません |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux のペインとウィンドウの操作キー。tmux のバージョンに対応し、vim と共存でき、どの prefix キーも無効にできます |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | tmuxのすべてのセッション、ウィンドウ、ペインを保存し、タイマーで自動保存して、再起動後にすべて復元します |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revampedプラグインの出発点です。共有ライブラリ、batsハーネス、CIを含みます |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | すべての状態をtmuxオプションに保持し、一時ファイルを使わない、tmuxステータスバーのポモドーロタイマーです |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM、スワップ、メモリプレッシャーをtmuxのステータスバーに表示します。計測はバックグラウンドで行うため描画を待たせません |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | tmuxのステータスバー上でウィンドウのタブをマウスでドラッグして、そのウィンドウを移動します |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 自分でスクロールできるアプリにはマウスホイールを渡し、それ以外ではtmuxのコピーモードに入ります |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | tmuxのバージョンと端末に合わせて適用され、ユーザーが設定したオプションには触れない、妥当な初期設定です |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmuxのタイル型ウィンドウ管理です。BSPのdwindleとspiralを含む8つのレイアウトと、レイアウトの取り消しがあります |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | ステータスバーにローカル時計と世界時計を時間帯ごとの色で表示し、カウントダウンと夏時間の警告も出します |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | wttr.inの天気をバックグラウンドで取得し、ステータスバーを待たせずに表示します |

<!-- family:end -->
