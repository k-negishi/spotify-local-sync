# spotify-local-sync

Music.appのライブラリから、Spotifyで聴く音源を選んでコピーするmacOS向けスクリプト。元の音源は変更せず、コピー先の音源も自動削除しない。

## 日々の運用（iPhone + iCloud Drive）

リポジトリをiCloud Driveの`SpotifyLocal/scripts/`に置くと、コピー先は`SpotifyLocal/music/`になる。MacとiPhoneで同じApple Accountを使い、iCloud Driveを有効にする。

1. Macで`scripts/sync.tsv`を編集し、追加したい曲を指定する。
2. `scripts/`で実行し、iCloud Driveへのアップロード完了を待つ。

   ```bash
   ./sync.py
   ```

3. iPhoneの「ファイル」で「iCloud Drive」>「SpotifyLocal」>「music」を開き、音源をコピーして「このiPhone内」>「Spotify」へペーストする。複数曲をまとめて選べる。iCloud上の音源はダウンロードしてからコピーする。
4. Spotifyの「ライブラリ」>「ローカルファイル」から再生する。初回は「設定とプライバシー」>「アプリとデバイス」>「ローカルファイル」で「このデバイスのオーディオファイルを表示」を有効にし、メディアへのアクセスを許可する。

同名ファイルを更新するときは、iPhone内の古いファイルを削除してからコピーし直す。`sync.tsv`から項目を削除しても、コピー済みの音源は残る。

## セットアップ

- macOS、Python 3.9以降、Music.appで管理している音源が必要。
- 音源の場所は`~/Music/Music/Media.localized`。
- iPhoneで使う場合、リポジトリをiCloud Driveの`SpotifyLocal/scripts/`に配置する。コピー先`music/`はその親ディレクトリに作成される。
- リポジトリを取得し、初回設定を作成する。

  ```bash
  git clone https://github.com/k-negishi/spotify-local-sync.git
  cd spotify-local-sync
  cp sync.tsv.example sync.tsv
  chmod +x sync.py
  ```

外部ライブラリは不要。`./sync.py`または`python3 ./sync.py`で実行する。`COPY`は新規・変更ファイルのコピー、`SKIP`は同一ファイルのスキップ、`WARN`は指定項目が見つからないことを示す。

## `sync.tsv`の指定

ヘッダー付きのタブ区切り。アーティスト名、アルバム名、曲名はMusic.appのディレクトリ名・ファイル名に合わせる。

```tsv
artist<TAB>album<TAB>track
Hi-STANDARD<TAB><TAB>
ELLEGARDEN<TAB>Pepperoni Quattro<TAB>
サバシスター<TAB>覚悟を決めろ！<TAB>ジャージ (2024 ver.)
```

`<TAB>`は実際にはタブ文字。最後の例はアルバム全体の指定。

| 記入する列 | コピー対象 |
| --- | --- |
| artist | アーティスト配下の全音源 |
| artist、album | 指定アルバム |
| artist、album、track | 指定アルバム内の曲 |
| artist、track | 全アルバムから一致する曲 |

曲名はファイル名と一致させる。先頭のトラック番号と空白は省略できる（例：`06 STAY GOLD.m4a`は`STAY GOLD`）。

## Spotifyで使う

- **iPhone:** iCloud Drive上の`music/`に置くだけでは表示されない。「このiPhone内/Spotify」へコピーする。
- **Mac:** Spotifyの設定で「ローカルファイルを表示する」を有効にし、コピー先の`music/`を参照先に追加する。

音源ファイルと個人用の`sync.tsv`はGit管理しない。コピーした音源の利用は、各音源の権利と利用条件に従う。
