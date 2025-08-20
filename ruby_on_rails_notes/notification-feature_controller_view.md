## この記事について:
この記事は前回投稿した[通知機能の実装方法：ルーティングとモデル編](https://qiita.com/monyu_02/items/3a077943e14fea4d193b)
の続きです。
コントローラーの実装について解説しますが、一部で退会処理（論理削除）機能が実装されている前提の説明が含まれます。この機能を実装していない方は、その部分の記述を除外していただいても、通知機能の実装は可能です。
調べつつ、記事をまとめましたが勉強不足で記述の間違い等ありましたらご指摘いただけると幸いです！

## コントローラーについて

コントローラーについて解説します。
以下のコマンドでコントローラーファイルを生成します。
```bash
rails g controller public/notifications
```
その次に以下の記述をnotificationsコントローラーファイルに追記します。
```ruby
class Public::NotificationsController < ApplicationController
  def index
    # 非アクティブ含めて既読処理
    current_member.passive_notifications.where(checked: false).each do |notification|
      notification.update(checked: true)
    end 

    # 表示はアクティブユーザーからのみに限定
    base_scope = current_member.passive_notifications.joins(:visitor).merge(Member.available).order(created_at: :desc)
    @notifications = base_scope.includes(:visitor, :post, :comment).page(params[:page]).per(15) 
  end
end
```

①非アクティブ送信者の通知も既読化する理由
- 一覧画面を開いた時に、送信者の状態に関わらず未読通知を既読化する方針です。
- 送信者が後から非アクティブ/非表示になった通知は一覧に出ないが、未読バッジ数だけが残留するのを防ぐためです。
- 例：通知発生 → 送信者が退会/非表示 → 通知は一覧に出ない → 未読バッジのみ残る → 一律既読で解消。

②`current_member.passive_notifications.where(checked: false).each do |notification|`
- ログイン中のメンバー（current_member）あてに届いた通知（passive_notifications）のうち、未読（checked: false）だけを取り出し、1件ずつループします。

③`  notification.update(checked: true)`
 - 各通知を既読（checked: true）に更新

④# 表示はアクティブユーザーからのみに限定
- 以降で、画面に出す通知は「送信者（visitor）がアクティブなものだけ」に絞る方針のコメントです。

⑤`base_scope = current_member.passive_notifications
  .joins(:visitor).merge(Member.available)
  .order(created_at: :desc)`
- 表示用の基礎スコープを作り、コードが長くなるのを避けるために変数 base_scope に代入しています。
  - current_member.passive_notifications：自分あての全通知。
  - .joins(:visitor)：notifications と members を内部結合（visitor_id = members.id）し、members 側のスコープや条件を使えるようにする。
  - .merge(Member.available)：結合した members に「アクティブ会員」条件を適用します。
  - .order(created_at: :desc)：新しい通知順に並べ替えします。

⑥`@notifications = base_scope
  .includes(:visitor, :post, :comment)
  .page(params[:page]).per(15)`
- 実際にビューへ渡す通知一覧を準備します。
  - .includes(:visitor, :post, :comment)：送信者・関連ポスト・コメントを事前に読み込みしてN+1クエリを回避します。
  - .page(params[:page]).per(15)：ページネーション（Kaminariを使用）。1ページ15件表示します。

### CommentsControllerファイルの記述
①データを取得・準備する
```ruby
@post = Post.find(params[:post_id])
```
- params[:post_id]を使って「どの投稿」に対するコメントかを特定します。
```ruby
@comment = current_member.comments.new(comment_params.merge(post_id: @post.id))
```
このコードでは、mergeメソッドを使って2つのハッシュを一つに結合しています。
- ハッシュ1 (comment_params):
  - キー: :comment_body
  - 値: フォームに入力されたコメント本文（例: 'この投稿、最高です！'）
- ハッシュ2 ({ post_id: @post.id }):
  - キー: :post_id
  - 値: Postオブジェクトから取得したID（例: 10）

mergeは、この2つのハッシュを合体させ、以下のような新しいハッシュを生成します。
```ruby
{
  comment_body: 'この投稿、最高です！',
  post_id: 10
}
```
そして、この結合されたハッシュが、Comment.newメソッドに渡され、新しいCommentオブジェクトが作成される、という仕組みです。

②保存と通知の実行
```ruby
if @comment.save
  @post.create_notification_comment(current_member, @comment.id)
else
  # ...
end
```
- if @comment.saveで、作成した@commentオブジェクトをデータベースに保存しようと試みます。
- もし保存に成功した場合、@post.create_notification_comment(...)という通知作成メソッドを呼び出します。
- このメソッドは、@commentが保存された直後に実行されるため、安全かつ効率的に通知を作成できます。

なぜsaveの後に通知を作成するのか:
- コメントがデータベースに保存される前に通知を作成してしまうと、万が一保存に失敗した場合に、存在しないコメントの通知が残ってしまうという問題が起こります。
- @comment.saveが成功したときにのみ通知を作成することで、このような不整合を防いでいます。

③失敗時の処理
```ruby
else
  @comment_body = @comment
  render :error
end
```
- もしコメントのsaveに失敗した場合（例：コメントが空だったなど）、このelseブロックが実行されます。
- render :errorによって、error.html.erbというテンプレートが表示されます。通常、このテンプレートはバリデーションエラーメッセージなどを表示するために使われます。

<details><summary>CommentsControllerファイル</summary>

```ruby
class Public::CommentsController < ApplicationController
  def create
    @post = Post.find(params[:post_id])
    @comment = current_member.comments.new(comment_params.merge(post_id: @post.id))
    
    if @comment.save
      @post.create_notification_comment(current_member, @comment.id)
    else
      @comment_body = @comment
      render :error
    end
  end
end
```

</details>

### RelationshipsControllerファイルの記述
```ruby
class Public::RelationshipsController < ApplicationController
  def create
    @member =  Member.find(params[:member_id])
    current_member.follow(@member)
    @member.create_notification_follow!(current_member)
  end
end
```
①`@member.create_notification_follow!(current_member)`
- このコードは、フォローというアクションが完了した後に、通知を作成するという次のステップを実行するために書かれています。
- @member: これは、current_memberによってフォローされたユーザーのインスタンスです。つまり、通知を受け取る人を指します。
- .create_notification_follow!: これは、memberモデルに定義されたメソッドです。このメソッドが実行されると、フォロー通知の作成ロジックが動きます。
- (current_member): メソッドの引数として、フォローした人（current_member）を渡しています。これにより、通知作成のロジック内で、「誰が」フォローしたかという情報を使えるようになります。


## 最後に：
次回はビューについて解説します。まだ学習中のため、記述に誤りや不足があれば、コメントでご指摘いただけると嬉しいです！！


