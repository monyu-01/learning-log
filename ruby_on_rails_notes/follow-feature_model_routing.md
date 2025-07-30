# フォロー・フォロワー機能を設計から理解する：モデルとルーティング編

### この記事の説明：
SNSにおいて定番の「フォロー・フォロワー機能」。実装するには、ユーザー同士がどのように関係し合うのかをデータベース設計の観点から正しく捉えることが重要です。
本記事では、中間テーブルを用いた多対多の関係構築、そしてRailsでのアソシエーション設定とルーティング設計に焦点を当て、フォロー機能の「土台」となる仕組みを丁寧に解説します。

## フォロー/フォロワー機能のルーティング設定

まずは、`routes.rb` に必要なルーティングを追加します。

```ruby:config/routes.rb
resources :members, only: [:show] do
  member do
    get :followers     #　フォロワー一覧ページ（/members/:id/followers）
    get :followings    #  フォロー中一覧ページ（/members/:id/followings）
  end
  resource :relationship, only: [:create, :destroy] # フォロー・フォロー解除機能
end
```

① `resources :members, only: [:show]`
 - メインのリソースは `members`（ユーザー）であり、ここではプロフィール詳細ページ（`members#show`）のみルートとして定義しています。
 - フォロー関連の機能はすべて「ある特定のメンバーに対して行う」という構造なので、`members` リソースをベースに ID付きのルーティングを構成します。

② `member do ... end` ブロック
 - `member` ブロックは、特定の1人のメンバー（=個別リソース）に対する追加ルーティングを定義する構文です。
 - 例えば `/members/3/followers` というURLは、「ID=3のメンバーに対するフォロワー一覧ページ」を意味します。
 - これにより、プロフィールとは別にフォロー関連の一覧ページを個別に用意できます。

以下のようなルーティングが生成されます：
| HTTPメソッド | パス                                 | アクション             | 概要                             |
|--------------|--------------------------------------|------------------------|----------------------------------|
| GET          | /members/:id                         | members#show           | 指定ユーザーのプロフィール詳細   |
| GET          | /members/:id/followers              | members#followers      | 指定ユーザーのフォロワー一覧を取得 |
| GET          | /members/:id/followings             | members#followings     | 指定ユーザーのフォロー中一覧を取得 |
| POST         | /members/:member_id/relationship    | relationships#create   | 指定ユーザーをフォロー             |
| DELETE       | /members/:member_id/relationship    | relationships#destroy  | 指定ユーザーのフォロー解除         |

③ `resource :relationship, only: [:create, :destroy]`
- `resource`（単数形）を使うことで、URLに :id が含まれないルーティングになります。
  - 理由：フォロー関係は「1対1の関係」であるため、個別IDによる識別が不要（`relationship.id` をURLに含めない方が自然）。
- `create／destroy` の2操作のみ定義し、フォロー／フォロー解除の用途に限定しています。

## モデルの設定

### フォロー機能のデータベース設計：同じユーザー間の多対多関係

SNSのようなフォロー機能は、ユーザーAがユーザーBをフォローしたり、ユーザーBがユーザーAをフォローしたりと、ユーザー同士が互いに関係し合うという特徴があります。これはデータベースの世界では「同じテーブル（`members`）間の多対多関係」として扱われます。

####  なぜ「多対多」なのか？
`members` テーブルに `followers_id` や `followings_id` のようなカラムを直接追加してはいけない理由は、以下の通りです。

- 一人のユーザーは複数の人をフォローできる

- 一人のユーザーは複数の人からフォローされる可能性がある

もし直接カラムを持とうとすると、1つのカラムに複数のIDを格納することになり、データベースの設計上好ましくありません。そのため、これらの複雑な関係性をスマートに管理するには、中間テーブルが不可欠になります。

####  中間テーブル `relationships` の役割
この多対多の関係を表現するために、「`relationships`」という名前の中間テーブルを作成します。このテーブルは、`follower_id` と `followed_id` という2つのカラムを持ちます。



まず、`follower`（フォローする人）と `followed`（フォローされる人）を `references` 型として持つモデルを以下のコマンドで作成します。

```bash
$ rails g model Relationship follower:references followed:references
```

このコマンドにより生成されるマイグレーションファイルを、以下のように外部キーを追記します。

```ruby:db/migrate/タイムスタンプ_create_relationships.rb
class CreateRelationships < ActiveRecord::Migration[6.1]
  def change
    create_table :relationships do |t|
      t.references :follower, null: false, foreign_key: { to_table: :members }
      t.references :followed, null: false, foreign_key: { to_table: :members }

      t.timestamps
    end
    #同じ組み合わせの重複フォローを防ぐユニーク制約
    add_index :relationships, [:follower_id, :followed_id], unique: true
  end
end
```

---

### 解説

- `t.references :follower, null: false, foreign_key: { to_table: :members }`:
「フォローする側」のユーザーIDを格納します。`members` テーブルのidを参照します。

- `t.references :followed, null: false, foreign_key: { to_table: :members }`:
「フォローされる側」のユーザーIDを格納します。こちらも`members` テーブルのidを参照します。

このように、`relationships` テーブルの両方の外部キーが同じ`members`テーブルを参照する点がポイントです。これにより、「どのユーザーがどのユーザーをフォローしているか」という関係性をシンプルに表現できます。

- `add_index :relationships, [:follower_id, :followed_id], unique: true`:
この行は、同じユーザーが同じユーザーを複数回フォローするのを防ぐための非常に重要な設定です。`follower_id`と`followed_id`の組み合わせに対してユニーク制約を追加しています。

具体的には、データベースに「`follower_id`と`followed_id`のペアは、テーブル内で一度しか存在してはならない」というルールを設けることで、誤って同じフォロー関係が二重に登録されてしまうのを防ぎます。これにより、データの整合性を保ち、アプリケーションの不具合や予期せぬ動作を防ぐことができます。

####  図で理解する関係性

`members` テーブル（例：ユーザー情報）

| id | name |
| ---- | ---- |
| 1 | なな |
| 2 | たろう |


`relationships` テーブル（例：フォロー関係）

| follower_id | followed_id |
| ---- | ---- |
| 1 | ２ |

これは「`members`テーブルのIDが1であるユーザー（なな）が、`members`テーブルのIDが2であるユーザー（たろう）をフォローしている」という関係を表しています。



---



## モデルのアソシエーション設定

フォロー機能において、`members`テーブル同士の関係を表現するには、中間テーブル `relationships` を活用します。

この構造を成立させるために、`Member`モデルと`Relationship`モデルに以下のような記述が必要です。

```ruby:app/models/member.rb
class Member < ApplicationRecord
  # 自分がフォローする関係（自分が「follower」になる）
  has_many :active_relationships, class_name: "Relationship", foreign_key: "follower_id", dependent: :destroy
  
  # 自分がフォローされる関係（自分が「followed」になる）
  has_many :passive_relationships, class_name: "Relationship", foreign_key: "followed_id", dependent: :destroy

   # 自分がフォローしているメンバーを特定（active_relationships経由でfollowedを取得
  has_many :followings, through: :active_relationships, source: :followed

  # 自分をフォローしているメンバーを特定（passive_relationships経由でfollowerを取得
  has_many :followers, through: :passive_relationships, source: :follower

  # =====================
  # フォロー・アンフォロー用のインスタンスメソッド
  # =====================

  # 指定したメンバーをフォローする
  def follow(member)
    active_relationships.create(followed_id: member.id)
  end

  # 指定したメンバーのフォローを解除する
  def unfollow(member)
    active_relationships.find_by(followed_id: member.id)&.destroy
  end

  # 自分をフォローしているフォロワーを削除する（相手からのフォローを外す）
  def remove_follower(member)
    passive_relationships.find_by(follower_id: member.id)&.destroy
  end

  # 指定したメンバーを既にフォローしているかを確認する
  def following?(member)
    followings.include?(member)
  end
end
```
※`passive`（受動的な）、`through`（～を通して）

---

### 解説（`member.rb`）

- `active_relationships`:
  自分がフォローする側として関わる`Relationship`レコードの集合です。`foreign_key`で`follower_id`を指定することで、`Member`モデルのidが`relationships`テーブルの`follower_id`と紐づくことを示します。
- `passive_relationships`:
  自分がフォローされる側として関わる`Relationship`レコードの集合です。`foreign_key`で`followed_id`を指定します。
- `followings`:
 `active_relationships`を介して、実際に **フォローしている相手（`followed`）** を取得します。
- `followers`:
 `passive_relationships`を介して、実際に **自分をフォローしている人（`follower`）** を取得します。
- `dependent: :destroy`
  `Member`が削除された際、その`Member`に関連する`active_relationships`と`passive_relationships`も自動的に削除されます。

---

```ruby:app/models/relationship.rb
class Relationship < ApplicationRecord
  # follower_id は Member モデルのインスタンスを参照する
  belongs_to :follower, class_name: "Member"
  # followed_id は Member モデルのインスタンスを参照する
  belongs_to :followed, class_name: "Member"

  # 同じ組み合わせの重複フォローを防ぐユニーク制約
  validates :follower_id, uniqueness: { scope: :followed_id }
end
```

### 解説（`relationship.rb`）

- `belongs_to :follower, class_name: "Member"`:
 `relationships`テーブルの`follower_id`が、`Member`モデルを参照していることを明示します。`Rails`はデフォルトで`Follower`というモデルを探そうとするため、ここで`Member`を指定する必要があります。
- `belongs_to :followed, class_name: "Member"`:
  同様に、`followed_id`も`Member`モデルを参照していることを明示します。
- `validates :follower_id, uniqueness: { scope: :followed_id }`:
  これにより、「同じユーザーが同じユーザーを複数回フォローする」といった重複を防ぐことができます。例えば、`follower_id`が1で`followed_id`が2という組み合わせが既に存在する場合、同じ組み合わせの新規作成はエラーになります。



---

### 全体像のまとめ：フォロー機能のデータとアソシエーションの流れ

```
Member(id: 1) ←─ active_relationships ─→ Relationship(follower_id: 1, followed_id: 2) ─→ followed ─→ Member(id: 2)

Member(id: 2) ←─ passive_relationships ─→ Relationship(follower_id: 1, followed_id: 2) ─→ follower ─→ Member(id: 1)
```

これまで、フォロー機能を実現するためのデータベース設計とRailsのアソシエーションについて、個別に見てきました。ここでは、それらがどのように連携し、ユーザー間のフォロー関係を表現しているのかを、この図を用いて説明していきます。

---

#### 図の要素とデータフロー

この図は、大きく分けて2つの「関係性」を示しています。
1.「フォローしている」側の関係 (`active_relationships` と `followings`)
2.「フォローされている」側の関係 (`passive_relationships` と `followers`)
それぞれ詳しく見ていきます。

---

#### 1. 「フォローしている」側の関係（上段の図）

```
Member(id: 1) ←─ active_relationships ─→ Relationship(follower_id: 1, followed_id: 2) ─→ followed ─→ Member(id: 2)
```

この流れは、「 **IDが1のメンバーが、IDが2のメンバーをフォローしている** 」という状況を示しています。

- `[Member (id: 1)]`:
これは、フォローする側のユーザー（例えば「なな」さん）を表しています。このユーザーが起点となります。

- `--- [active_relationships]`:
`Member`モデルに定義した`has_many :active_relationships`というアソシエーションを指します。これは、 **「自分が起点となってフォローした関係」** をすべて取得するための窓口です。IDが1のメンバーが持つ「アクティブな（能動的な）関係」がここから始まります。

- `--- [Relationship (follower_id: 1, followed_id: 2)]`:
これが実際にデータベースに保存されている **`relationships`テーブルのレコード** です。

  - `follower_id: 1`：この関係を作ったのはIDが1のメンバーです。

  - `followed_id: 2`：この関係によってフォローされたのはIDが2のメンバーです。
つまり、`active_relationships`を通して、IDが1のメンバーは、この`Relationship`レコードにたどり着きます。

- `--- [followed]`:
`Relationship`モデルに定義した`belongs_to :followed`というアソシエーションを指します。この`followed`アソシエーションは、`relationships`テーブルの`followed_id`（この場合は2）を使って、対応する`Member`レコードを探しに行きます。

- `--- [Member (id: 2)]`:
最終的にたどり着くのが、フォローされている側のユーザー（例えば「たろう」さん）です。

この一連の流れは、`Member.find(1).followings`というコードを実行したときに、`Rails`が内部でどのようにデータを辿っていくかを示していると言えます。

---

#### 2. 「フォローされている」側の関係（下段の図）

```
Member(id: 2) ←─ passive_relationships ─→ Relationship(follower_id: 1, followed_id: 2) ─→ follower ─→ Member(id: 1)
```

この流れは、同じ`Relationship`レコードを使って、「IDが2のメンバーが、IDが1のメンバーにフォローされている」という状況を示しています。視点が逆になっただけです。

- `[Member (id: 2)]`:
これは、フォローされている側のユーザー（「たろう」さん）を表しています。このユーザーが起点となります。

- --- `[passive_relationships]`:
`Member`モデルに定義した`has_many :passive_relationships`というアソシエーションを指します。これは、**「自分が対象となってフォローされた関係」**をすべて取得するための窓口です。IDが2のメンバーが持つ「パッシブな（受動的な）関係」がここから始まります。

- `--- [Relationship (follower_id: 1, followed_id: 2)]`:
ここでも、先ほどと同じ`relationships`テーブルのレコードにたどり着きます。このレコードは「IDが1がIDが2をフォローしている」という事実を保存しています。`passive_relationships`を通して、IDが2のメンバーは、この`Relationship`レコードにたどり着きます。

- `--- [follower]`:
`Relationship`モデルに定義した`belongs_to :follower`というアソシエーションを指します。この`follower`アソシエーションは、`relationships`テーブルの`follower_id`（この場合は1）を使って、対応する`Member`レコードを探しに行きます。

- `--- [Member (id: 1)]`:
最終的にたどり着くのが、自分をフォローしている側のユーザー（「なな」さん）です。

この一連の流れは、`Member.find(2).followers`というコードを実行したときに、`Rails`が内部でどのようにデータを辿っていくかを示していると言えます。

---

### まとめ

この図は、1つの`relationships`レコード（例: `follower_id: 1`, `followed_id: 2`）が、`Member`モデルから見て2つの異なる視点で利用されることを示しています。

- ID=1の`Member`から見れば、`active_relationships`を介して「フォローしている相手」（`followed`）に繋がります。

- ID=2の`Member`から見れば、`passive_relationships`を介して「自分をフォローしている相手」（`follower`）に繋がります。

このように、中間テーブルを挟むことで、`Member`モデル自身に変更を加えることなく、複雑な「フォロー/フォロワー」という多対多の関係を、柔軟かつ効率的に管理できます。

