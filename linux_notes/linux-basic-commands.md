# Linuxコマンド基礎の実践まとめ（CloudTech動画ハンズオン）

## この記事について：
Linuxコマンドをとてもわかりやすく説明しているYouTube動画を見つけました。
CloudTechのサイトを運営している、くろかわこういちさんが説明してくださっています。
この記事は、その動画を見ながらハンズオンで実践したコマンドをまとめています。 
Linuxコマンドをこれから学習する方の参考になれば幸いです🙌

動画はこちら：
[Linux徹底攻略-初学者でもこれ一本で現場で戦える！](https://www.youtube.com/watch?v=EA5sc0ayXYM "Linux徹底攻略-初学者でもこれ一本で現場で戦える！コマンド、カーネル、シェル、グロブ、パスdnf、ディストリビューション、プロンプト、EC2インスタンスやTeraterm導入まで2時間の濃密講義")

# 新しいディレクトリの作成コマンド[mkdir]
- mkdir は make directory の略
- 例：
```bash
$ mkdir linux-practice-log
```

# ディレクトリ内のファイルやフォルダを一覧表示するコマンド[ls]
- シンプル表示でファイル名・ディレクトリ名だけを一覧表示
- 例：
```bash
ec2-user:~/environment $ ls
bookers                      linux-practice-log  nagano_cake_teamB                 tunagarihiroba
everydayrails-rspec-jp-2024  meshiterro          rails6-bookers2-debug-ruby3-main  work-github
learning-log                 nagano_cake         Rails6-rb3-NaganoCake-main
```

# ディレクトリ内のファイルやフォルダを一覧表示するコマンド[ls　-l]
- ロング形式（long format）表示
- ファイルの詳細情報を縦に一覧表示
- 表示項目：	

| 項目 | 意味 | 例 |
|------|------|----|
| 権限 | 読み/書き/実行の可否 | `drwxrwxr-x` |
| リンク数 | ハードリンクの数 | 16 |
| 所有者 | ファイルの持ち主 | ec2-user |
| グループ | 所属グループ | ec2-user |
| サイズ | ファイル容量（バイト） | 4096 |
| 最終更新日時 | 最後に変更された日付と時間 | May 10 07:21 |
| ファイル名 | ファイルやディレクトリ名 | bookers |

- 例：
```bash
ec2-user:~/environment $ ls -l
total 36
drwxrwxr-x 16 ec2-user ec2-user 4096 May 10 07:21 bookers
drwxrwxr-x 15 ec2-user ec2-user 4096 Jul 23 04:41 everydayrails-rspec-jp-2024
drwxrwxr-x  5 ec2-user ec2-user   79 Jul 30 12:03 learning-log
drwxrwxr-x  2 ec2-user ec2-user    6 Aug 11 05:30 linux-practice-log
drwxrwxr-x 16 ec2-user ec2-user 4096 Jun  6 02:43 meshiterro
drwxrwxr-x 15 ec2-user ec2-user 4096 May 22 10:37 nagano_cake
drwxrwxr-x 14 ec2-user ec2-user 4096 May 25 04:39 nagano_cake_teamB
drwxrwxr-x 16 ec2-user ec2-user 4096 May 10 08:45 rails6-bookers2-debug-ruby3-main
drwxrwxr-x 13 ec2-user ec2-user 4096 Jun  3 01:53 Rails6-rb3-NaganoCake-main
drwxrwxr-x 18 ec2-user ec2-user 4096 Jul 24 10:46 tunagarihiroba
drwxrwxr-x 15 ec2-user ec2-user 4096 May 17 08:03 work-github
```


# 今いるディレクトリそのものの詳細情報を表示するためのコマンド[-ls -ld .]
- -d→フォルダの中身ではなく、フォルダそのものの情報を表示する
- .→カレントディレクトリ（今いるディレクトリ）
- 例：
```bash
ec2-user:~/environment $ ls -ld .
drwxrwxr-x 14 ec2-user ec2-user 296 Aug 11 05:30 .
```

# 現在のディレクトリの中にある全てのファイル・ディレクトリを一覧表示するコマンド[-ls -a]
- -a → 「all」の略
  - 通常 ls は ドットで始まる名前（隠しファイル・隠しフォルダ） を表示しません
  - -a を付けると隠しファイルも含めて全て表示する
```bash
ec2-user:~/environment $ ls -a
.        everydayrails-rspec-jp-2024  meshiterro         rails6-bookers2-debug-ruby3-main  tunagarihiroba
..       learning-log                 nagano_cake        Rails6-rb3-NaganoCake-main        work-github
bookers  linux-practice-log           nagano_cake_teamB  .ruby-lsp
```

1.	.
- 「今いるディレクトリ自身」を意味する特別な名前
2.	..
- 「今いるディレクトリの親ディレクトリ」を意味する特別な名前
3.	bookers, learning-log, …
- 通常のディレクトリ（Railsアプリや学習用のフォルダ）
4.	.ruby-lsp
- ドットで始まる「隠しディレクトリ」
- Ruby用の言語サーバー設定やキャッシュを保存するためのもの

# 指定したディレクトリ内に含まれるファイルやサブディレクトリの詳細情報を一覧表示するコマンド[ls -l 表示対象ディレクトリ]
- learning-log：表示対象ディレクトリ（この場合は ~/environment/learning-log）
- 例：
```bash
ec2-user:~/environment $ ls -l learning-log
total 4
-rw-rw-r-- 1 ec2-user ec2-user 812 Jul 27 06:55 README.md
drwxrwxr-x 2 ec2-user ec2-user 211 Aug  9 12:52 ruby_on_rails_notes
drwxrwxr-x 2 ec2-user ec2-user  76 Jul 31 14:47 sql_notes
```

# ターミナル上で文字列をそのまま表示するだけのコマンド[echo]
- echo：引数として与えられた文字列や変数の値を標準出力（通常は画面）に出力するコマンド
- Hello：出力したい文字列（引数）
- 例：
```bash
ec2-user:~/environment/linux-practice-log $ echo Hello
Hello
```
# 指定したテキストファイルの中身を標準出力（ターミナル画面）に表示するコマンド[cat]
- 複数ファイルを指定すると、順に連結して表示できる。
- 由来は “concatenate” コンカティネイト（連結する）の cat から来ています。
- 例：
```bash
ec2-user:~/environment/tunagarihiroba (main) $ cat /etc/nginx/conf.d/tunagarihiroba.conf
```
# 指定したファイルをコビーして、新しいファイル名をつけて保存するコマンド[cp]
- cp → copy（コピー）の略
- 第1引数 → コピー元のファイル
- 第2引数 → コピー先のファイル名またはパス
- 任意の場所に複製が可能
＊第2引数にディレクトリパスを指定した場合は、そのディレクトリ内に同じ名前でコピーされる。（名前を指定しなければ）
- 例：
```bash
ec2-user:~/environment/linux-practice-log $ cp hello.c hello.c.2
ec2-user:~/environment/linux-practice-log $ ls 
hello.c  hello.c.2  hello.js  readme.txt
```

# 指定したファイル名を変更するまたは、指定したディレクトリへのファイルの移動コマンド[mv]
- 第1引数 → 指定のファイル
- 第2引数 → ファイルの変更名
- 例：
```bash
ec2-user:~/environment/linux-practice-log $ mv hello.c hello.c.3
ec2-user:~/environment/linux-practice-log $ ls
hello.c.2  hello.c.3  hello.js  readme.txt
```
- 第1引数 → 指定のファイル
- 第2引数 → 変更したいディレクトリの指定
＊`mv hello.c.3 ../hello_new.c `名前を変更したい場合は、../ の後に新しい名前を直接つなげて書く
- 例：
```bash
ec2-user:~/environment/linux-practice-log $ mv hello.c.3 ../
ec2-user:~/environment/linux-practice-log $ cd ../
ec2-user:~/environment $ ls
bookers                      learning-log        nagano_cake                       Rails6-rb3-NaganoCake-main
everydayrails-rspec-jp-2024  linux-practice-log  nagano_cake_teamB                 tunagarihiroba
```

# 空のファイルの新規作成もしくは、既存ファイルのタイムスタンプを更新するコマンド[touch]
- 新しいファイルの作成例：
```bash
ec2-user:~/environment/linux-practice-log $ touch newfile
ec2-user:~/environment/linux-practice-log $ ls -l
total 16
-rw-rw-r-- 1 ec2-user ec2-user 26 Aug 11 11:45 hello.c.2
-rw-rw-r-- 1 ec2-user ec2-user 26 Aug 11 11:44 hello.c.3
-rw-rw-r-- 1 ec2-user ec2-user 32 Aug 11 11:44 hello.js
-rw-rw-r-- 1 ec2-user ec2-user  0 Aug 11 12:18 newfile 　#新しいファイル
-rw-rw-r-- 1 ec2-user ec2-user 14 Aug 11 11:45 readme.txt
```
- 既存ファイルのタイムスタンプ更新例：
```bash
ec2-user:~/environment/linux-practice-log $ touch newfile
ec2-user:~/environment/linux-practice-log $ ls -l
total 16
-rw-rw-r-- 1 ec2-user ec2-user 26 Aug 11 11:45 hello.c.2
-rw-rw-r-- 1 ec2-user ec2-user 26 Aug 11 11:44 hello.c.3
-rw-rw-r-- 1 ec2-user ec2-user 32 Aug 11 11:44 hello.js
-rw-rw-r-- 1 ec2-user ec2-user  0 Aug 11 12:21 newfile　#更新されたタイムスタンプ
-rw-rw-r-- 1 ec2-user ec2-user 14 Aug 11 11:45 readme.txt
```
