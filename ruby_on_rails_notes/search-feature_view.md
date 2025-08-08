### この記事について：
本記事では、前回の「モデル・ルーティング・コントローラー編」で実装した検索処理の土台をもとに、検索結果を画面に表示するビューの作成を解説します。
「なぜその書き方をするのか？」を重視し、検索フォームの裏側の仕組みや、paramsの流れ・GETリクエスト構造・チェックボックスの送信方法などを丁寧に解説しています。
初心者がつまずきやすいポイントを意識した構成のため、内容はやや詳しめです。知識のある方にとっては重たく感じられる部分があるかもしれませんが、フォーム構造を根本から理解したい方には参考になると思います。

## 検索フォームの構成とその実装意図を解説

### 1. form_withで検索フォームを作成

検索フォームには、`form_with` を使用してGETリクエストを送信するようにしています。
```ruby
<%= form_with url: posts_path, method: :get do |f| %>
```
このようにすることで、検索時のキーワードやカテゴリの選択内容が URLにそのまま反映 されるようになります。



例えば以下のようなURLが生成されます：
```
https://tunagarihiroba.com/posts?keyword=家族&commit=検索&genre_ids%5B%5D=7&genre_ids%5B%5D=8
```
- keyword=家族 → キーワードに「家族」を入力
- genre_ids%5B%5D=7&genre_ids%5B%5D=8 → カテゴリとしてID7と8が選択されている
- commit=検索 → 検索ボタンが押されたことを示す

 ### なぜ commit=検索 が送られる？
- commit=検索 が送られるのは、f.submit "検索" で指定したボタンのラベルが「検索」だからです。

- Railsの form_withでは、submit ボタンを押すと、
そのボタンのラベルが自動的に params[:commit] に格納されます。

- 以下では、params[:commit]がどこから出てきたのか、詳しくご説明します。
<%= form_with ... %>というコードは、裏側で以下のようなHTMLを自動で作っています。

```html
<form action="/posts" method="get">
  <input type="submit" name="commit" value="検索">
</form>
```
この input type="submit" がポイントです。
1.ブラウザのルール: input type="submit" は、どの送信ボタンが押されたかをサーバーに伝えるためのHTMLの標準的な部品です。

2.Railsのルール: form_withは、このボタンの name を自動的に "commit" に設定しています。そして、value にはボタンに表示されているテキスト（この場合は「検索」）を入れます。

3.情報伝達: ユーザーがこの「検索」ボタンを押すと、ブラウザはnameとvalueのペア（commit=検索）をサーバーに送信します。

4.paramsは、どのフォームから送信されたか、どのボタンが押されたか、入力された内容は何か、といったリクエストのすべての情報をRailsが扱うための「入れ物」です。

params[:commit]は、その入れ物の中から特に「どのボタンが押されたか」という情報だけを取り出すための仕組みです。

- 「検索」ボタンが押された: params[:commit]には"検索"が入る。

- 「更新」ボタンが押された: params[:commit]には"更新"が入る。

- 「削除」ボタンが押された: params[:commit]には"削除"が入る。

このように、ボタンのvalue属性（ボタンに表示されているテキスト）が、そのままparams[:commit]の値になります。これを利用することで、コントローラー側で簡単に処理を分岐させることができるのです。

### 2. テキスト入力欄：キーワード検索
```ruby
<%= f.text_field :keyword, value: params[:keyword], placeholder: "気になる言葉を入力してみよう", class: "form-control" %>
```
①:keyword
- この引数は、フォーム送信時にどの名前でパラメータを送信するかを指定しています。
- ここでは keyword という名前で、ユーザーが入力したテキストが送られるようになります。
- たとえば、「散歩」と入力して送信した場合、サーバー側では以下のように受け取れます：
```ruby
params[:keyword] # => "散歩"
```
②value: params[:keyword]
- 検索実行後にフォームに戻ってきたとき、直前に入力されていたキーワードを再表示するための指定です。
- これがないと、検索結果ページでフォームがリセットされて空欄になります。
- ユーザーの体験を損なわないように、直前の検索条件を維持する仕組みです。

### 3. 検索ボタン
```ruby
<%= f.submit "検索", class: "btn btn-success" %>
```
- GETメソッドで検索条件が送信される。

### 4. チェックボックスでカテゴリを選択
```ruby
<%= check_box_tag 'genre_ids[]', genre.id, params[:genre_ids]&.include?(genre.id.to_s), class: "form-check-input" %>
```
①check_box_tagとは何か？
- check_box_tagは、Ruby on Railsというウェブ開発のフレームワークで提供されているメソッドです。これは、HTMLの<input type="checkbox">という要素を簡単に生成するために使われます。
- このcheck_box_tagを使うことで、HTMLを直接書かなくてもチェックボックスを作ることができます。

②'genre_ids[]'
これはチェックボックスに名前をつけるためのものです。
- 'genre_ids'という名前は、送信されたデータが「ジャンルのIDのリスト」であることを示しています。
- 末尾の[]は、「複数の値を配列として受け取る」という意味です。これにより、ユーザーが複数のチェックボックスにチェックを入れた場合でも、それらがひとまとまりのデータとしてサーバーに送られます。

>＊なぜ文字列にする必要があるのか詳しく説明
>- ウェブの通信では、ブラウザからサーバーに送られるデータは、すべてテキスト（文字列）として扱われます。フォームのデータも例外ではありません。
>- ブラウザがサーバーにデータを送るとき、genre_ids[]=1&genre_ids[]=3のような形式の文字列を作成します。このgenre_ids[]の部分は、データの「名前」を示すキーとして機能します。
>- Railsのcheck_box_tagメソッドは、この通信のルールに合わせて、チェックボックスのHTML要素を生成します。
 >```html
 ><input type="checkbox" name="genre_ids[]" ... >
 >```
>- このname="genre_ids[]"という部分が、サーバーに送られるデータのキーとなります。このキーはHTMLでは文字列として扱われるため、Rubyでcheck_box_tagを呼び出す際も、文字列として'genre_ids[]'と指定する必要があります。
>- つまり、'genre_ids[]'を文字列にするのは、ブラウザとサーバーが共通で理解できる「データの名前」を定義するためです。

③genre.id
これは、そのチェックボックスがどんな値を持っているかを決めるものです。
- 例えば、このチェックボックスが「健康」というジャンルに対応しているなら、genre.idは「1」のような、そのジャンルを特定するためのIDになります。

- ユーザーがこのチェックボックスにチェックを入れると、このgenre.idの値がサーバーに送られます。

④params[:genre_ids]&.include?(genre.id.to_s)
これは、「もしユーザーが以前にこのチェックボックスにチェックを入れていたなら、今回もチェックが入った状態にしておく」という役割を果たしています。これにより、ページを再読み込みしたり、フォームを再表示したりしても、ユーザーの選択が失われないようにしています。
- params: これは、ユーザーが以前に選択した情報（送信されたデータ）を保持している特別な変数です。
- params[:genre_ids]: paramsの中から、'genre_ids'という名前で送られてきた値を取り出します。
- &. (safe navigation operator): これは「もしparams[:genre_ids]がnil（空っぽ）じゃなかったら、次の処理に進んでね」という意味です。もしユーザーが何もチェックせずに送信した場合、params[:genre_ids]はnilになるので、エラーを防ぐための安全装置です。
- .include?(genre.id.to_s): これは,「params[:genre_ids]の中に、今作っているチェックボックスのID（genre.id）が含まれているか？」をチェックしています。
  - genre.id.to_sとなっているのは、paramsの中の値が文字列（"1", "2"など）になっているため、比較するIDも文字列に変換しているからです。

⑤`each`文と組み合わせるとどうなるか？
この`check_box_tag`のコードは、通常、以下のように`each`文の中で使われます。

```ruby
<% @genres.each do |genre| %>
  ...
  <%= check_box_tag 'genre_ids[]', genre.id, params[:genre_ids]&.include?(genre.id.to_s), class: "form-check-input" %>
  ...
<% end %>
```
このeach文は、データベースから取得した全てのジャンル（例：「健康」「脳疾患」）を一つずつ取り出し、それぞれに対応するチェックボックスを自動的に生成するために使われます。
役割ごとの動き:
- genre.id: each文が繰り返されるたびに、この値は現在のジャンルのIDに変わります。

  - 1回目の繰り返し（「脳疾患」）ではgenre.idは1になります。

  - 2回目の繰り返し（「健康」）ではgenre.idは2になります。

- params[:genre_ids]&.include?(genre.id.to_s): この部分が、チェックボックスに最初からチェックを入れるかどうかを判断します。

  - 例えば、ユーザーが以前「健康」のチェックボックスにチェックを入れて送信した場合、params[:genre_ids]には["2"]という文字列の配列が入っています。

  - 2回目の繰り返しで「健康」のチェックボックスを生成するとき、genre.idは2なので、["2"].include?(2.to_s)が**true**となり、チェックが入った状態になります。

  - 一方、1回目の繰り返しで「脳疾患」のチェックボックスを生成するときは、genre.idは1なので、["2"].include?(1.to_s)が**false**となり、チェックは入りません。

このように、each文を使うことで、データベースのジャンル情報が変更されても、コードを書き換えることなく動的にチェックボックスを生成できます

<details><summary>検索フォームの部分テンプレート</summary>

```ruby
<div class="container">
  <div class="w-50 mx-auto bg-light rounded-3 py-5 px-4 align-items-center justify-content-between content-responsive-md">
    <div class="search-form-area">
      <%= form_with url: posts_path, method: :get do |f| %>
        <div class="container mb-2">
          <h4>キーワード</h4>
        </div>
        <div class="d-flex justify-content-center align-items-center gap-3 mb-4">
          <div class="w-75">
            <%= f.text_field :keyword, value: params[:keyword], placeholder: "気になる言葉を入力してみよう", class: "form-control" %>
          </div>
          <div>
            <%= f.submit "検索" , class: "btn btn-success" %> 
          </div> 
        </div>
        <div>
          <div class="container mb-2">
            <h4>カテゴリー</h4>
            <div class="d-flex flex-wrap gap-3 mb-4">
              <% @genres.each do |genre| %>
                <div class="form-check">
                  <label class="form-check-label">
                    <%= check_box_tag 'genre_ids[]', genre.id, params[:genre_ids]&.include?(genre.id.to_s), class: "form-check-input" %>
                    <%= genre.name %>
                  </label>
                </div>
              <% end %>
            </div>
            <div>
              <h4>検索のヒント</h4>
              <p>
                気になるキーワード（糖尿病、認知症、健康、散歩、30代、70代、名前など）を入力して検索してみましょう。興味のある投稿や、同じ境遇の方とつながりやすくなります。※カテゴリーの選択は任意です。必要に応じて選択し、「検索」ボタンを押してください。
              </p>
            </div>
          </div>
        </div>
      <% end %>
    </div><%# search-form-area %>
  </div><%# container bg-light rounded-3 py-5 px-4 align-items-center justify-content-between %>
</div><%# w-50 mx-auto ontent-responsive-md %>
```
</details>

## 検索結果の表示に関する画面の構成を解説

該当コードはこちらです：
```ruby
<% if params[:keyword].present? || params[:genre_ids].present? %>
  <h4>検索結果（<%= @posts.total_count %> 件）</h4>
<% else %>
  <h4>新着投稿一覧</h4>
<% end %>
```
①if文の条件式: `params[:keyword].present? || params[:genre_ids].present?`
この部分が、見出しを切り替えるための「条件」です。
- params: ユーザーがフォームから送信したデータが格納されている、特別なハッシュ（連想配列）です。検索フォームに入力されたキーワードや、選択されたチェックボックスの情報などがここに入ります。
- params[:keyword]: 検索フォームに入力されたキーワードの値を取得しています。例えば、"家族"と入力されていれば、params[:keyword]は"家族"になります。
- .present?: その値が「存在するかどうか」を判定するメソッドです。
  - "家族".present?は true です。
  - "".present?（空文字列）や nil.present? は false です。
- ||: これは「または（OR）」を意味します。左辺か右辺、どちらか一方がtrueであれば、全体の条件式がtrueになります。

つまり、この条件式全体は、「キーワードが入力されている」または「ジャンルが選択されている」のどちらかが当てはまればtrueになります。

②ifブロック内の処理
```ruby
<h4>検索結果（<%= @posts.total_count %> 件）</h4>
```
if文の条件式がtrue（つまり、ユーザーが何かを検索した場合）のときに、この部分が表示されます。
- h4 検索結果（...）/h4: 検索結果であることを示す見出しが表示されます。
- <%= @posts.total_count %>: @postsという変数に格納されている、検索結果の投稿の総数を取得して表示します。これにより、「検索結果（5件）」のように具体的な件数が示されます。
＊補足：total_countについて
このtotal_countというメソッドは、Kaminariという、ページ分割機能を提供するGemを使っていることが前提です。このメソッドを使うことで、現在表示しているページの件数ではなく、検索結果全体の件数を正しく表示することができます。

③elseブロック内の処理
```ruby
<h4>新着投稿一覧</h4>
```
- if文の条件式がfalse（つまり、ユーザーが何も検索せずにページを訪れた場合）のときに、この部分が表示されます。
- この場合、params[:keyword]もparams[:genre_ids]も存在しないため、**「新着投稿一覧」**という見出しが表示されます。

<details><summary>検索画面のコード全文</summary>

```ruby
<% if current_member&.guest? %>
  <div class="container">
    <div class="alert alert-warning text-center w-50 mx-auto mt-4 py-2">
      <p class="fw-bold mb-1">ゲストモードでご利用中です。</p>
      <p class="mb-0 small lh-sm">
        ※登録すると、プロフィール・コメント<br>
        保存機能などをご利用いただけます。
      </p>
    </div>
  </div>
<% elsif current_member %>
  <div class="border-bottom mt-4">
    <div class="container">
      <div class="w-50 mx-auto title-responsive-md">
        <h2 class="mb-4">投稿を探す</h2>
      </div>
    </div>
  </div> 
<% end %>

<div class="card-list-container py-3">
  <%= render 'public/posts/search_form' %>
  <div class="w-50 mx-auto mt-4 title-responsive-md">
    <% if params[:keyword].present? || params[:genre_ids].present? %>
      <h4>検索結果（<%= @posts.total_count %> 件）</h4>
    <% else %>
      <h4>新着投稿一覧</h4>
    <% end %>
  </div>
  <%= render 'public/posts/post_list', posts: @posts %>
  <div class="d-flex justify-content-center mt-4">
    <%= paginate @posts, theme: 'bootstrap-5' %>
  </div>
</div>
```

</details>

## 最後に

本記事の内容について、少し補足をさせていただきます。

私は現在、自分の言葉でスムーズに説明できる段階に進むための前段階として、「まず実装 → その後に振り返る」という勉強スタイルを採用しています。
今回のように、ジャンルを複数選択できる検索機能の実装は、調べても分かりやすい解説がなかなか見つからず、自分で試行錯誤しながら構築していく必要がありました。

そのため、一度手を動かして形にしたあとで、仕組みを調べ直し、記事としてまとめながら理解を深めていく…という形で学習を進めています。

この記事が、同じようにポートフォリオを制作している方や、検索機能の実装に悩んでいる方のヒントになれば幸いです。
