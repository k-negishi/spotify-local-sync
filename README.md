# spotify-local-sync

Music.appのライブラリから、Spotifyで再生したいローカル音源だけを別ディレクトリへコピーするmacOS向けスクリプトです。

コピー対象は`sync.tsv`で指定します。元の音源は変更・削除せず、コピー先に同じ内容のファイルがある場合はスキップします。`sync.tsv`から項目を削除しても、コピー済みの音源は自動削除しません。

## 必要なもの

- macOS
- Bash
- Music.appで管理しているローカル音源

このスクリプトは、Music.appのメディアディレクトリが次の場所にあることを前提としています。

```text
~/Music/Music/Media.localized
```

## ディレクトリ構成

このリポジトリを、音源のコピー先と同じ親ディレクトリに配置します。

```text
SpotifyLocal/
├── music/                       # コピー先（Git管理外）
└── scripts/                     # このリポジトリ
    ├── README.md
    ├── sync.sh
    ├── sync.tsv                 # 個人用設定（Git管理外）
    └── sync.tsv.example
```

`scripts/`の配置場所にかかわらず、コピー先はその親ディレクトリにある`music/`です。

## セットアップ

リポジトリを取得し、サンプルから個人用設定を作成します。

```bash
git clone https://github.com/k-negishi/spotify-local-sync.git
cd spotify-local-sync
cp sync.tsv.example sync.tsv
chmod +x sync.sh
```

## `sync.tsv`の書式

`sync.tsv`は、ヘッダーを含むタブ区切りのファイルです。

```tsv
artist<TAB>album<TAB>track
Hi-STANDARD<TAB><TAB>
ELLEGARDEN<TAB>Pepperoni Quattro<TAB>
サバシスター<TAB>覚悟を決めろ！<TAB>ジャージ (2024 ver.)
```

上記の`<TAB>`は、実際のファイルではタブ文字です。リポジトリに含まれる`sync.tsv.example`は、そのままコピーして利用できます。

各列の指定方法は次のとおりです。

| 指定 | 動作 |
| --- | --- |
| `artist`のみ | アーティスト配下の全音源をコピー |
| `artist`と`album` | 指定アルバムの全音源をコピー |
| `artist`、`album`、`track` | 指定アルバム内の曲をコピー |
| `artist`と`track` | アーティスト配下の全アルバムから曲を検索してコピー |

アルバム全体を指定する場合の例です。

```tsv
Hi-STANDARD<TAB>MAKING THE ROAD<TAB>
```

アーティスト名、アルバム名、曲名は、Music.appが作成したディレクトリ名およびファイル名と一致させてください。曲名については、ファイル名の先頭にあるトラック番号と空白を省略できます。

たとえば、次のファイルは`STAY GOLD`として指定できます。

```text
06 STAY GOLD.m4a
```

## 実行

このリポジトリ内で実行します。

```bash
./sync.sh
```

または、Bashを明示して実行します。

```bash
bash ./sync.sh
```

`sh ./sync.sh`は使用しないでください。このスクリプトはBashのプロセス置換を使用しています。

実行結果には次のいずれかが表示されます。

- `COPY`: 新規ファイル、または内容が変更されたファイルをコピー
- `SKIP`: コピー先に同一内容のファイルが存在
- `WARN`: 指定したアーティスト、アルバム、または曲が見つからない

## Spotifyで使う

Mac版Spotifyの設定で「ローカルファイルを表示する」を有効にし、コピー先の`music/`を参照先として追加します。

iPhoneで利用する場合は、必要な音源をiCloud Driveなどを経由して「このiPhone内」のSpotifyフォルダへコピーしてください。

## 注意事項

- 音源ファイルと個人用の`sync.tsv`はGit管理しないでください。
- このスクリプトはコピー先からファイルを削除しません。
- コピーした音源の利用・管理は、各音源の権利と利用条件に従ってください。
