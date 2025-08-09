# 通知機能の実装方法：ルーティングとモデル編
## この記事について：
ポートフォリオで実装した通知機能について説明します。通知のロジックは、フォローやコメントが付いた際に、通知ページから内容を確認できる仕様としています。他の通知機能との違いとして、通知ページを開くと該当の通知が既読状態になる点があります。なお、一般的なポリモーフィック設計は採用しておらず、一対多の構造となっています。本記事は、自己学習用のまとめとして実装内容の理解を深めることを目的としています。私の自己学習まとめが、実装練習のヒントになれば幸いです。
＊前提条件として、コメント機能とフォロー機能を実装済みの程での説明とします。

##### 下記が完成イメージ画像です。私がポートフォリオで実装したものです。
通知アイコン

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/4046616/54c5e77c-d0bb-492e-bf86-a674dd251911.png" width="50%">

通知一覧

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/4046616/c57401f3-fe6c-45a3-8109-49a7694104a6.png" width="50%">

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/4046616/9cbcf22f-0ebb-454b-af59-41de8a0d58cf.png" width="50%">

## ルーティングについて
まずルーティングに以下の記述を記載します。
```ruby
scope module: :public do
  resources :notifications, only: :index
end
```
- resources は複数形のリソースを扱うためのルーティング構文で、デフォルトでは、index / show / new / create / edit / update / destroy の7つのルートを生成します。
- 今回は、通知一覧の表示のみを実装しているため、only: :indexを指定しています。
- index アクションはもともとidを必要としないコレクションルートなので、この指定により /notifications のみが生成されます。

rails routes の出力例は以下です。
```bash
     Prefix Verb URI Pattern           Controller#Action
notifications GET  /notifications(.:format) public/notifications#index
```

## モデルについて
次はモデルについて解説します。
その前に、モデルで扱うデータを保存するためのテーブル作成から説明します。
以下のコマンドでマイグレーションファイルを生成します。
```bash
$ rails g migration CreateNotifications
```
その次に以下の記述をマイグレーションファイルに追記します。
```ruby
class CreateNotifications < ActiveRecord::Migration[6.1]
  def change
    create_table :notifications do |t|
      t.integer :visitor_id, null: false
      t.integer :visited_id, null: false
      t.integer :post_id
      t.integer :comment_id
      t.string :action, default: '', null: false
      t.boolean :checked, default: false, null: false

      t.timestamps
    end

    add_index :notifications, :visitor_id
    add_index :notifications, :visited_id
    add_index :notifications, :post_id
    add_index :notifications, :comment_id
  end
end
```
各カラムの説明
- visitor_id（必須）
通知を発生させたユーザーのID（例：フォローした人、コメントを書いた人）です。
- visited_id（必須）
通知を受け取るユーザーのID（例：フォローされた人、コメントされた人）です。
- action（必須・デフォルト空文字）
通知の種類を表す文字列（例："follow", "comment"）。
default: ''（空文字）にしている理由は、レコード作成時点ではどちらが入るかわからないため空で用意し、通知作成時にどちらかを設定します。
- checked（必須・初期値false）
既読フラグ。未読（false）で作られ、通知一覧を開いた等のタイミングで 既読(true)になります。
- index
インデックスをつける理由は、必要なレコードだけを素早く見つけるためです。
インデックスがないとデータ量が増えたときにテーブル全件を最初から最後まで調べる全表走査（full table scan）が発生し、データ量が多くなると表示が遅くなります。

マイグレーションを実行してテーブルを作成します。
```bash
$ rails db:migrate
```
次はモデルファイルを作成します。
```bash
$ rails g model Notification
```
その次に以下の記述をモデルファイルに追記します。
```ruby
class Notification < ApplicationRecord
  belongs_to :post, optional: true
  belongs_to :comment, optional: true
  belongs_to :visitor, class_name: 'Member', foreign_key: 'visitor_id', optional: true
  belongs_to :visited, class_name: 'Member', foreign_key: 'visited_id', optional: true
end
```
① `belongs_to :post, optional: true`
- belongs_to :post: この通知が関連している投稿を示します。

- 例: ある投稿に「いいね！」が押されたら、その投稿のIDが通知に記録されます。

- belongs_toはデフォルトで関連先が必須ですが、optional: trueを付けることで、関連先がなくても保存できます。

- 例えば、「フォローされました」という通知には、特定の投稿は関係ありません。

②`belongs_to :comment, optional: true`
- belongs_to :comment: この通知がどのコメントに関連しているかを示します。

- 例: 誰かがあなたの投稿にコメントしたら、通知にコメントのIDが保存されます。

- こちらもoptional: trueが付いているので、すべての通知にコメントが紐づくわけではありません。

③`visitorとvisitedの役割`
- belongs_to :visitor, ...
belongs_to :visitor: 通知を起こした人、つまり「訪問者」を意味します。

- 例: Aさんがあなたの投稿にコメントした場合、Aさんがvisitorです。

- class_name: 'Member', foreign_key: 'visitor_id': visitorという名前のテーブルはないため、代わりにMemberテーブルと関連付け、データベース上のvisitor_idというカラムで紐づけています。

- optional: trueが必要な理由: 通知の種類によっては、visitorが存在しない場合があります。例えば、「システムからのお知らせ」のような通知では、特定のユーザーが通知を発生させているわけではありません。

- belongs_to :visited, ...
belongs_to :visited: 通知を受け取る人、つまり「訪問された人」を意味します。

- 例: Aさんがあなたの投稿にコメントした場合、あなたがvisitedです。

- class_name: 'Member', foreign_key: 'visited_id': こちらもMemberテーブルと関連付け、データベース上のvisited_idで紐づけています。

- optional: trueが必要な理由: visitedも通知によっては存在しない場合があります。例えば、「Aさんが退会しました」という通知をシステムが生成する場合、誰かが通知を受け取るわけではないケースも考えられます。

### モデルの関連付け
メンバーモデルに以下の記述を追記します。
```ruby
class Member < ApplicationRecord
  has_many :active_notifications, class_name: 'Notification', foreign_key: 'visitor_id', dependent: :destroy
  has_many :passive_notifications, class_name: 'Notification', foreign_key: 'visited_id', dependent: :destroy
end
```
①`has_many :active_notifications, ...`
- メンバー（Member）が誰かに通知を送った履歴を管理するための関連付けです。

- class_name: 'Notification': 関連付けの対象となるモデルが、Notificationモデルであることを明示しています。

- foreign_key: 'visitor_id': 関連付けのキーとして、Notificationモデルのvisitor_id（訪問者である、通知を送った人）カラムを使用することを指定しています。

- dependent: :destroy: Memberが削除されたときに、そのメンバーが送った通知（active_notifications）もすべて自動的に削除されるように設定しています。

- この設定により、@member.active_notificationsと書くことで、そのメンバーが送った通知の一覧を取得できるようになります。

②`has_many :passive_notifications, ...`
- メンバー（Member）が誰かから受け取った通知の履歴を管理するための関連付けです。
- 構造は①と同じですが、foreign_key が visited_id になっており、通知の受け取り側のメンバーを表します。


### コメントやフォローと通知の関係について
コメント機能やフォロー機能は、すでに Member モデルと関連付けられています。
具体的には以下のような関連があります。

```ruby
has_many :comments, dependent: :destroy
has_many :active_relationships,  class_name: "Relationship", foreign_key: "follower_id", dependent: :destroy
has_many :passive_relationships, class_name: "Relationship", foreign_key: "followed_id", dependent: :destroy
```
このため、コメントやフォローをトリガーに通知を送受信する場合でも、新しく関連を追加する必要はありません。
既存の関連を使って、Notification モデルのレコードを作成すれば通知機能は動作します。


## 最後に：
次回はコントローラーとビューについて解説します。まだ学習中のため、記述に誤りや不足があれば、コメントでご指摘いただけると嬉しいです！！
