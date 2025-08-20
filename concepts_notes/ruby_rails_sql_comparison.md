## この記事について
Ruby on Railsをスクールでハンズオン学習をして、卒業後に振り返りつつ疑問に思ったことは、「どれがRubyでどれがRailsなのか？」という点でした。  
また、自身の制作したポートフォリオではSQLについても記述する実装があり、SQL文の生成についても触れていきます。  
この記事は、実装機能の理解を深めるために**Ruby / Rails / SQL**のよく使うものを表形式でまとめたものです。  

---

### 2. よく使う **Ruby構文**
| 構文 | 用途 | 例 |
|------|------|----|
| `def ... end` | メソッド定義 | `def hello_world; puts "Hello"; end` |
| `class ... end` | クラス定義 | `class Post; end` |
| `module ... end` | モジュール定義 | `module Searchable; end` |
| `if / elsif / else / unless` | 条件分岐 | `if user.active?` |
| `case ... when ... end` | 複数条件分岐 | `case status; when 1; ... end` |
| `:symbol` | シンボル | `:member` |
| `-> { ... }` | ラムダ式 | `-> { where(active: true) }` |
| `{ ... }` / `do ... end` | ブロック | `.each { \|x\| ... }` |
| 変数代入 | 値の保存 | `name = "Ruby"` |
| 配列・ハッシュリテラル | データ構造 | `[1, 2, 3]`, `{ a: 1, b: 2 }`|
| 式展開 | 文字列に式の値を埋め込む | `"Hello #{name}"` |

---

### 3. よく使う **Railsメソッド**（ActiveRecord中心）

#### 3-1. 検索・条件指定系
| メソッド | 用途 | 生成SQL例 |
|----------|------|-----------|
| `where` | 条件指定 | `WHERE active = TRUE` |
| `or` | OR条件指定 | `WHERE a = 1 OR b = 1` |
| `not` | NOT条件指定 | `WHERE NOT(active = TRUE)` |
| `order` | 並び順 | `ORDER BY created_at DESC` |
| `limit` | 件数制限 | `LIMIT 10` |
| `offset` | 開始位置指定 | `OFFSET 20` |
| `find` | 主キー検索 | `WHERE id = 1` |
| `find_by` | 条件に合う最初の1件 | `LIMIT 1` |
| `first` / `last` | 最初/最後の1件 | `ORDER BY id ASC/DESC LIMIT 1` |
| `exists?` | 存在確認 | `SELECT 1 FROM ... WHERE ... LIMIT 1` |

#### 3-2. 関連・結合系
| メソッド | 用途 | 生成SQL例 |
|----------|------|-----------|
| `joins` | 内部結合 | `INNER JOIN members ON ...` |
| `left_joins` | 左外部結合 | `LEFT OUTER JOIN members ON ...` |
| `includes` | Eager loading | 複数SELECTやJOIN |
| `merge` | 他モデルのスコープ適用 | `WHERE members.is_active = TRUE` |
| `belongs_to` / `has_many` | 関連付け定義 | JOIN条件の基礎になる |

#### 3-3. 集計系
| メソッド | 用途 | 生成SQL例 |
|----------|------|-----------|
| `count` | 件数取得 | `SELECT COUNT(*) FROM ...` |
| `sum` | 合計値 | `SUM(price)` |
| `average` | 平均値 | `AVG(price)` |
| `minimum` / `maximum` | 最小/最大値 | `MIN(price)` / `MAX(price)` |
| `group` | グループ化 | `GROUP BY category_id` |
| `having` | 集約後条件 | `HAVING COUNT(*) > 1` |
| `distinct` | 重複除去 | `SELECT DISTINCT ...` |

#### 3-4. スコープ系
| メソッド | 用途 | 生成SQL例 |
|----------|------|-----------|
| `scope` | 名前付きクエリ定義 | `scope :published, -> {...}` |
| `default_scope` | デフォルト条件 | 自動的にWHERE追加 |
| `unscoped` | デフォルト条件解除 | 条件無し |

---

### 4. よく使う **SQL構文**
| 構文 | 用途 | 例 |
|------|------|----|
| `SELECT` | カラム選択 | `SELECT * FROM posts` |
| `FROM` | 参照テーブル | `FROM posts` |
| `WHERE` | 条件 | `WHERE title LIKE '%運動%'` |
| `AND` / `OR` | 論理条件 | `WHERE active = TRUE AND age > 20` |
| `NOT` | 否定条件 | `WHERE NOT(active = TRUE)` |
| `JOIN` | 内部結合 | `INNER JOIN members ON ...` |
| `LEFT JOIN` | 左外部結合 | `LEFT JOIN members ON ...` |
| `LIKE` | 部分一致 | `LIKE '%keyword%'` |
| `IN` | 複数候補 | `WHERE id IN (1,2,3)` |
| `BETWEEN` | 範囲条件 | `WHERE price BETWEEN 100 AND 500` |
| `GROUP BY` | グループ化 | `GROUP BY genre_id` |
| `HAVING` | 集約後条件 | `HAVING COUNT(*) > 1` |
| `ORDER BY` | 並び替え | `ORDER BY created_at DESC` |
| `LIMIT` | 件数制限 | `LIMIT 10` |
| `OFFSET` | 開始位置指定 | `OFFSET 20` |
| `DISTINCT` | 重複除去 | `SELECT DISTINCT posts.id` |

---

## 最後に
表形式で Ruby / Rails / SQL の違いをまとめることで、区別をつける第一歩になりました。
学び始めた頃は動かすだけで精一杯でしたが、最近は全体像から具体へと視点が変わり、Railsの理解が少しずつ深まってきた気がします。
まだ完全に理解していない部分もあり、今後学びながら補足していく予定です。
記事の内容に間違いや不明点があれば、ぜひ教えていただけると嬉しいです。最後まで読んでいただきありがとうございました。

