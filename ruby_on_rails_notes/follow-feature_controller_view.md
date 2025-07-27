# フォロー・フォロワー機能を設計から理解する：コントローラーとビュー編

###  この記事の説明：
SNSに欠かせない「フォロー・フォロワー機能」。本記事では、前回のモデルとルーティング編で設計した基盤をもとに、実際にユーザー同士の関係を「操作」できるようにするコントローラーの処理と、その操作結果を「表示」するビューの作成に焦点を当てます。フォロー・フォロワーの登録・解除、一覧表示といった機能を、標準的なRailsの書き方に基づく実装方法で段階的に解説し、ユーザーのつながりを可視化するための仕組みを完成させていきます。

## `RelationshipsController`: フォロー・アンフォロー機能の設定

### 1. コントローラーの役割とアクションの概要

フォロー・フォロワー機能の核となるのが、`RelationshipsController` です。このコントローラーは、ユーザー間の「フォロー関係」の作成と削除を担います。

具体的には、

-  `create` アクション: あるユーザーが別のユーザーを**フォローする**際に実行されます。
-  `destroy` アクション: あるユーザーが別のユーザーの**フォローを解除する**際に実行されます。

これらのアクションを通じて、ユーザー間のつながりが管理されています。

### 2. `Public::RelationshipsController` の詳細解説

```ruby: relationships_controller.rb
class Public::RelationshipsController < ApplicationController
  def create
    # どのユーザーをフォローするのか、URLからIDを取得
    @member = Member.find(params[:member_id])
    # 現在ログインしているユーザーが、@memberをフォローする
    current_member.follow(@member)
  end

  def destroy
    # どのユーザーのフォローを解除するのか、URLからIDを取得
    @member = Member.find(params[:member_id])
    # 現在ログインしているユーザーが、@memberのフォローを解除する
    current_member.unfollow(@member)
  end
end
```

このコードでは、`create` と `destroy` の両方のアクションで `@member = Member.find(params[:member_id])` という行が共通しています。

- `params[:member_id]`: ここが非常に重要なポイントです。この `member_id` は、URLから渡されるパラメーターで、「フォロー・アンフォローの対象となるユーザーのID」 を表します。

- `Member.find(params[:member_id])`: URLから取得したIDを使って、データベースから該当する `Member` (ユーザー) の情報を取得し、`@member` 変数に格納しています。

- `current_member.follow(@member)` / `current_member.unfollow(@member)`: ここで、現在ログインしているユーザー (`current_member`) が、取得した `@member` に対して実際にフォロー(`follow`)またはアンフォロー(`unfollow`)の操作を実行します。

## `Public::MembersController`: フォロー・フォロワー一覧の表示

### 1. コントローラーの役割とアクションの概要

ユーザーが「誰をフォローしているか」や「誰にフォローされているか」を確認する機能は、SNSにおいて非常に重要です。この一覧表示を担うのが、`Public::MembersController` 内の `followings` と `followers` アクションです。

ここでは、特定のユーザーのフォローリストとフォロワーリストを表示するロジックが書かれています。

### 2. `Public::MembersController` の詳細解説

```ruby: members_controller.rb
class Public::MembersController < ApplicationController
  
  def followings
    # URLから取得したIDを使って、表示対象となるユーザーを取得
    @member = Member.find(params[:id])
    # @member がフォローしているユーザーたちを取得
    @followings = @member.followings
  end

  def followers
    # URLから取得したIDを使って、表示対象となるユーザーを取得
    @member = Member.find(params[:id])
    # @member をフォローしているユーザーたちを取得
    @followers = @member.followers
  end
end
```

### `followings` と `followers` の仕組み
これらのアクションは、特定のユーザーがフォローしている人、またはフォローされている人を一覧表示するために使われます。両方のアクションが共通して行うのは、以下の2ステップです。

1.表示対象となるユーザーの特定:
まず、URLから取得した `params[:id]` を使って、「誰のリストを表示したいのか」という対象のユーザーをデータベースから取得し、`@member` 変数に格納します。たとえば、URLが `/members/5/followings` であれば `params[:id]` は 5 となり、IDが5のユーザー情報が `@member` に入ります。

2.関連するユーザーのリスト取得:
次に、取得した `@member` が持つ関連付けメソッドを呼び出します。

- `followings` アクションでは、`@member.followings` を使って、`@member` がフォローしている全てのユーザー（`Member`オブジェクトのコレクション）を取得し、`@followings` 変数に格納します。

- `followers` アクションでは、`@member.followers` を使って、`@member` をフォローしている全てのユーザー（`Member`オブジェクトのコレクション）を取得し、`@followers` 変数に格納します。

取得されたユーザーリスト (`@followings` または `@followers`) は、それぞれ対応するビュー（例: `followings.html.erb` や `followers.html.erb`）に渡され、一覧として表示されることで、ユーザー間の関係性が視覚的に提供されます。

## `params[:member_id]` と `params[:id]` がどこから来るのか

Railsのルーティングでは、URLパスの一部として渡される動的な値は**パラメーター (params)** としてコントローラーのアクションで利用できます。このパラメーターの名前は、ルーティング定義の方法によって決まります。

### 1. `relationships_controller.rb` の `params[:member_id]`

`Public::RelationshipsController` の `create` と `destroy` アクションでは、`params[:member_id]` を使って `Member` を取得しています。これは、通常、**ネストされたルーティング (nested routes)** から来ています。

例えば、`config/routes.rb` に以下のような記述があるとします。

```ruby:config/routes.rb
resources :members do
  resource :relationships, only: [:create, :destroy]
end
```
このルーティングを `rails routes --expanded | grep member` で出力すると、以下のような行が見つかるはずです。

```Bash:$rails routes --expanded | grep member の出力例 (一部)
Prefix Verb   URI Pattern                                               Controller#Action

member_relationships POST   /members/:member_id/relationships(.:format) public/relationships#create
                     DELETE /members/:member_id/relationships(.:format) public/relationships#destroy
```

- URL `Pattern` の `members/:member_id/relationships` に注目してください。
この `:member_id` の部分が、URLから受け取った値を `params[:member_id]` としてコントローラーに渡すことを示しています。
例えば、`/members/1/relationships` のようにアクセスすると、`params[:member_id]` には 1 が格納されます。

- なぜ `:id` ではなく `:member_id` なのか？
`relationships` リソースは `members` リソースにネストされています。これは、「どのメンバーに対するリレーションシップか」を明確にするためです。Railsの慣習として、親リソースのIDは :親リソース名_id という形式でパラメーターとして渡されます。これにより、`relationships_controller` では、どの `Member` との関係を操作するのかを明確に区別できます。

### 2. `members_controller.rb` の `params[:id]`

`Public::MembersController` の `followings` と `followers` アクションでは、`params[:id]` を使って `Member` を取得しています。これは、通常、`members` リソース自体に対するアクション、またはコレクションメンバーに対するカスタムアクションで使われます。

例えば、`config/routes.rb` に以下のような記述があるとします。

```ruby:config/routes.rb
resources :members do
  member do
    get :followings
    get :followers
  end
end
```

このルーティングを `rails routes --expanded | grep member` で出力すると、以下のような行が見つかるはずです。

```Bash:$rails routes --expanded | grep memberの出力例 (一部)
Prefix Verb   URI Pattern                                              Controller#Action
followings_member GET    /members/:id/followings(.:format)             public/members#followings
followers_member  GET    /members/:id/followers(.:format)              public/members#followers
```

- URI `Pattern` の `members/:id/followings` や `members/:id/followers` に注目してください。
この `:id` の部分が、URLから受け取った値を `params[:id]` としてコントローラーに渡すことを示しています。
例えば、`/members/5/followings` のようにアクセスすると、`params[:id]` には 5 が格納されます。

- なぜ `:id` なのか？
これは、`members` リソースそのものに対するアクションであるためです。`Rails`のリソースルーティングの基本的な慣習として、特定のインスタンス（この場合は特定の`Member`）を識別するためのIDは`:id`というパラメーター名で渡されます。`member do ... end` ブロック内で定義されたアクションは、そのリソースの特定のメンバー（インスタンス）に紐づくアクションであるため、`:id` が使われます。

### まとめ
- `params[:member_id]: relationships_controller` で使われるのは、親リソース（`members`）のIDを子リソース（`relationships`）に渡すための、ネストされたルーティングの慣習です。

- `params[:id]: members_controller` で使われるのは、リソースそのもののIDを指す場合、またはそのリソースの特定のメンバーに対するカスタムアクションの場合の慣習です。
*カスタムアクションとは、`Rails`の`resources`ヘルパーがデフォルトで提供する7つの`CRUD`操作（`index`, `show`, `new`, `create`, `edit`, `update`, `destroy`）以外の、独自に定義されたアクションのことです。
たとえば、`followings`や`followers`のように、特定のデータを取得したり、標準の`CRUD`には当てはまらない機能を実現するために追加されるアクションがこれにあたります。

## ビュー編：フォロー・アンフォローボタンを実装する

これまで、フォロー・フォロワー機能の「裏側」、つまりコントローラーがどのように関係性を管理しているかを解説してきました。
このセクションでは、ユーザーが「応援する（フォローする）」または「応援をやめる（アンフォローする）」ためのボタンがどのように実装されているのか、その「表側」のビューの解説をします。

### `_follow_btn.html.erb`：ボタンのロジック
フォロー・アンフォローのボタンは、複数の場所（例：ユーザープロフィールページ、投稿一覧など）で使い回されることが多いため、`Rails`では **部分テンプレート（`Partial Template`）** として切り出すのが一般的です。

今回見ていくのは、`views/public/relationships/_follow_btn.html.erb` というファイルです。この部分テンプレートは、表示対象のユーザー（`member`）と現在ログインしているユーザー（`current_member`）の状態に応じて、適切なボタンを表示するロジックを含んでいます。

### `views/public/relationships/_follow_btn.html.erb` の詳細解説

```ruby:views/public/relationships/_follow_btn.html.erb
<% if current_member != member %>
  <% if current_member.following?(member) %>
    <%= link_to member_relationship_path(member.id), method: :delete, remote: true, class: "btn btn-success btn-sm me-4" do %>
      <span><i class="fa-solid fa-thumbs-up"></i>応援をやめる</span> 
    <% end %>
  <% else %>
    <%= link_to member_relationship_path(member.id), method: :post, remote: true, class: "btn btn-outline-success btn-sm me-4" do %>
      <span><i class="fa-regular fa-thumbs-up"></i>応援をする</span>
    <% end %>
  <% end %>
<% end %>
```

このコードブロックは、以下のステップでボタンの表示を制御しています。

1.`<% if current_member != member %>`
最初の条件分岐です。これは、「現在ログインしているユーザー（`current_member`）と、ボタンが表示されている対象のユーザー（`member`）が同じではない場合のみ」という条件を表しています。つまり、ユーザーが自分自身をフォローできないようにするための重要なチェックです。もしこの条件がなければ、ユーザーが自分のプロフィールページで「応援する」ボタンを押せてしまうことになります。

2.`<% if current_member.following?(member) %>`
ログインユーザーが自分以外のユーザーであると確認できた後、次にこの条件分岐が評価されます。
`current_member.following?(member)` は、`Member` モデルに定義されているヘルパーメソッドです。このメソッドは、「`current_member` が `member` をすでにフォローしているか（応援しているか）」を `true` または `false` で判定します。

- もし `true` （すでにフォローしている場合）:
応援をやめる ボタンが表示されます。
`<%= link_to member_relationship_path(member.id), method: :delete, remote: true, ... %>`
この `link_to` ヘルパーは、`DELETE` メソッドで `RelationshipsController` の `destroy` アクションにリクエストを送るリンク（ボタン）を生成します。`method: :delete` と `remote: true` の組み合わせは、`JavaScript（Ajax）`を使ってページ遷移なしでフォロー解除の処理を行うための手法です。
＊ ページ遷移なしでフォロー解除の処理を行うための手法（非同期通信につきましては、次の章で詳しく説明します。）

- もし `false` （まだフォローしていない場合）:
応援をする ボタンが表示されます。
`<%= link_to member_relationship_path(member.id), method: :post, remote: true, ... %>`
こちらは POST メソッドで RelationshipsController の create アクションにリクエストを送るリンク（ボタン）を生成します。これにより、フォロー関係が新しく作成されます。`remote: true` も同様に`Ajax`通信を行います。

### まとめ：フォロー・アンフォローボタンを実装する
このように、ビューでは、コントローラーから渡されたデータ（`current_member` や `member` の状態）に基づいて、ユーザーにどのような情報を見せるか、どのような操作ボタンを提供するかを決定します。

特に、今回のフォロー・アンフォローボタンでは、`_follow_btn.html.erb` という部分テンプレートが以下の重要な役割を果たしていました。

- 条件分岐による表示の切り替え: ログインユーザーと表示対象ユーザーが同一か、フォロー済みか未フォローかによって、表示されるボタンの種類を適切に切り替えます。

- ルーティングとの連携: `link_to` ヘルパーを通じて、適切な`HTTP`メソッド（`POST / DELETE`）と`URL（member_relationship_path(member.id)）`でコントローラーのアクションと連携し、フォロー関係の作成・削除をトリガーします。

- 非同期通信 `(remote: true)`: ユーザー体験を向上させるために、ページ全体のリロードなしに操作を完結させます。

表示例
![スクリーンショット 2025-07-27 11.54.49.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/4046616/b215e48f-b573-4419-92c2-e2ebf9dfb09a.png)

## ビュー編：フォロワー・フォロー中リストの表示

前回のセクションで、フォロー・アンフォローのボタンがどのように機能するかを見てきました。今回は、そのフォロー関係がどのようにリストとして表示されるかに焦点を当てていきます。

`Public::MembersController` の `followings` アクションと `followers` アクションから渡された `@followings` と `@followers` というデータが、実際に画面にどう表示されるのか説明します

### リスト表示の共通構造：`followers.html.erb` と `followings.html.erb`
このファイルは、ほぼ同じ構造で構成されています。これは、どちらも「ユーザーのリスト」を表示するという共通の目的を持っているためです。

### フォロワー一覧 
```ruby:views/public/members/followers.html.erb
<% @followers.each do |member| %>
  <div class="d-flex align-items-center border-bottom py-3">
    <%= link_to member_path(member), class: "text-decoration-none link-dark" do %>  
      <%= image_tag member.get_profile_image(40,40), class: "rounded-circle me-2" %>
      <span><%= member.name %></span>
    <% end %> 
  </div>
<% end %>
```

### フォロー一覧
```ruby:views/public/members/@followings.html.erb
<% @followings.each do |member| %>
  <div class="d-flex align-items-center border-bottom py-3">
    <%= link_to member_path(member), class: "text-decoration-none link-dark" do %>  
      <%= image_tag member.get_profile_image(40,40), class: "rounded-circle me-2" %>
      <span><%= member.name %></span>
    <% end %> 
  </div>
<% end %>
```

どちらのビューファイルも、本質的には同じ処理を行っています。

1.`<% @followers.each do |member| %>` または `<% @followings.each do |member| %>`
この行は、Rubyの繰り返し処理です。コントローラーから渡された `@followers`（フォロワーの`Member`オブジェクトのコレクション）または `@followings`（フォロー中の`Member`オブジェクトのコレクション）の各要素を、`member` という一時変数に代入しながら、ブロック内のコードを繰り返し実行します。これにより、リスト内の各ユーザーに対して同じHTML構造が生成されます。

この繰り返し処理の中で、各ユーザーの具体的な情報を表示していきます。ここでは、主に以下の **カラム（データ）** が利用され、HTMLヘルパーとCSSクラス（`Bootstrap`など）によって整形されています。

- `member.get_profile_image(40,40)`: 各ユーザーのプロフィール画像を取得し、`image_tag` ヘルパーで表示します。

- `member.name`: 各ユーザーの名前を表示します。

- `member_path(member)`: クリックすると、そのユーザーのプロフィールページへ遷移するためのリンクを生成します。

これらが link_to ヘルパーによってクリック可能な要素となり、div タグのクラス設定（`d-flex, border-bottom, py-3` など）で、視覚的に整ったリストとして表示されます。
※HTMLヘルパーは、Railsが提供する **「HTMLタグを生成するための便利なRubyメソッド」** であり、Web開発をより効率的で堅牢にするためのツールです。

### まとめ:フォロワー・フォロー中リストの表示
これらのビューファイルは、コントローラーから受け取ったユーザーデータのコレクションをループ処理し、各ユーザーのプロフィール画像と名前を、スタイルが適用されたリンクとして表示しています。これにより、ユーザーはフォロー中リストやフォロワーリストを確認し、気になったユーザーのプロフィールページへ簡単に移動できるようになります。

表示例

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/4046616/81915f63-c3b2-448c-9359-ecb186339c40.png" width=50%>

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/4046616/aa8120ca-035d-4b58-bf87-e19bebbacd21.png" width=50%>

## ちょっと雑談：Web系エンジニアリングって、結局「文理融合」じゃない？
ここまで、フォロー・フォロワー機能の技術的な側面を深掘りしてきました。コードと向き合う時間は、まさに論理的な思考力が試される「理系」の世界ですよね。

でも、Web系エンジニアとして学習を進める中で、私はふとこんなことを感じています。

「これって、理系と文系の混合領域じゃないか？」

特に、複雑なアプリケーションの構造を読み解いたり、ユーザーが使いやすいように機能を設計したりする場面で、その思いが強くなるんです。技術書やブログ記事を読み込んで、コードの裏にある「なぜ？」や「どう動く？」を理解しようとする活動って、まるで難解な文章を読み解くような感覚に近いんですよね。

この感覚について、AI（Gemini）に意見を求めてみたところ、まさに私のモヤモヤを言語化してくれました。

「複雑な問題を論理的に分解し（理系）、それを抽象的な概念に落とし込み（文系）、人間に分かりやすい形で表現し（文系）、最終的にシステムとして構築する（理系）という、文理融合的な創造活動」

なるほど、まさにこれだ！と思いました。

システムを動かすロジックを組むのは確かに理系的なアプローチですが、そのロジックをどのような抽象概念で表現するか（MVCやRESTfulなど）、そしてそれをどうやってユーザーが直感的に使えるUI・UXとして落とし込むか、さらに言えば、ブログでこうして技術を「伝える」ことも、すべて文系的な思考力があってこそだと感じています。

「理系だからプログラミングが得意」「文系だから苦手」なんて一概には言えない、奥深さがこの分野にはありますよね。このブログを通して、そんなWeb系エンジニアリングの多様な側面に触れてもらえたら嬉しいです。

