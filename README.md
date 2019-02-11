# Slytherin
Slytherinは、ymlファイルを使ったSeederプログラムで誰でも簡単に速いSeedを記述する事ができるGemです。

## 使用方法

以下のようなModelがある事を過程してください<p>

```
モデル名: Prefecture
カラム名: id (Int型)
        name (string型)
```

 ```
モデル名: Member
カラム名: id (Int型)
         prefecture_id(Prefectureの外部キー)
         name (String型)
```
---
### カラム名を書くのが面倒
---
「カラム名を書くのが面倒だ」という問題をSlytherinは解決してくれます。 <p>
 
以下のようにymlファイルを定義しましょう。 場所は任意で構いません。<p>
今回は./db/slytherin/mouse/seeder.ymlに保存します。<p>

 ```
Mouse:
  Prefecture:
    loop: 47
 ```
Mouseの下に、モデル名を記述しましょう。その下のloopにはループ回数を指定します。<p>
loop: 47の場合は、47回ループします。<p>
また、カラム名が省略された場合には、Slytherinが定義している適当なSeedデータが入ります。<p>
ymlファイルを定義できたら、seeds.rbに以下のように記述します。<p>

  ```
slytherin = Slytherin::Seeder.new()
slytherin.set_path('./db/slytherin/mouse/seeder.yml')
slytherin.do_seed()
  ```

以上で終わりです。<p>
rake db:seedコマンドを実行したらPrefectureのレコードが47件に増えている事がわかるでしょう。<p>
        
---
### 自分で定義したSeedデータを入れたい
---
Slytherinは開発者が自分でSeedデータを入れたい場合も想定してあります。<p>

 ```
Mouse:
  Prefecture:
    loop: 47
    col_info:
      name:
        init_data: ["北海道","青森県","岩手県","宮城県", ...]
 ```

自分でSeedデータを入れたい場合は、col_infoと記述しましょう。<p>
その下に、カラム名を、さらにその下にinit_dataを定義しシード値として使いたい配列を記述します。<p>
先ほどと同じようにrake db:seedを実行してみてください。<p>
今度は、貴方が定義したデータが入るはずです。<p>
        
---
### ymlファイルが配列だらけになってかさばる
---
確かに47の配列をymlファイルに定義するのは、何となく見栄えが悪いです。<p>
そういう場合は、set_dataファイルを作成しましょう。<p>
場所は任意で構いません。<p>
今回は./db/slytherin/set_data.rbに保存します。<p>

 ```
def set_prefecture
  [
    "北海道",
    "青森県",
    "岩手県",
    "宮城県",
    "秋田県",
    "山形県",
    "福島県",
    "茨城県",
    "栃木県",
    ...
end
 ```

このset_data.rbをymlにセットします。
 ```
Mouse:
  Prefecture:
    loop: 47
    col_info:
      name:
        init_data: set_prefecture
 ```

これでスッキリりました。<p><p>

次にseeds.rbに以下のように記述します。<p>

  ```
slytherin = Slytherin::Seeder.new()
slytherin.set_path('./db/slytherin/mouse/seeder.yml',
                   './db/slytherin/set_data.rb')
slytherin.do_seed()
  ```

データ定義ファイルをSlytherinの読み込みに追加しました。<p>
これでrake db:seedを実行してみてください。<p>
都道府県が綺麗に入っているはずです。<p>
        
---
### ランダムに初期値を入れたい（オプションに関して）
---
デフォルトでは、配列の値は循環して投入されますがオプションを付けることで<p>
ランダムに投入する事も可能です。<p>

 ```
Mouse:
  Prefecture:
    loop: 47
    col_info:
      name:
        init_data: set_prefecture
        random: true
 ```

Slytherinには、上記のようなデータ投入に関するオプションが多く存在します。<p>
現在実装されているオプションを下記に記述します。<p>

rotate → trueにすると循環してデータが入る。<p>
random → trueにするとバラバラで入る<p>
first →  trueにすると一番初めのデータのみが入る<p>
last →   trueにすると一番最後のデータのみが入る<p>
numberling → trueにするとString型のSeedデータ投入時に自動で連番をふってくれる<p>
              例えば、北海道_1, 北海道_2 など<p>

---
### 外部キーを入れたい(オプションに関して2)
---
外部キーを入れたい場合にもオプションを使います。<p>
今回はMemberのSeedを作成してみましょう。<p>

 ```
Mouse:
  Prefecture:
    loop: 47
    col_info:
      name:
        init_data: set_prefecture
  Member:
    loop: 100
    col_info:
      prefecture_id:
        init_data: Prefecture
        references: true
        random: true
 ```

referencesオプションをtrueにしてinit_dataにモデル名を記載すると <p>
SlytherinはPrefectureモデルからIDを引っ張りだし自動的に投入してくれます。 <p>
        
---
### 同一モデルのSeedを複数回連続で入れたい。
---
モデル名の左にプレフィックスを設定する事で、同一モデルに対してシードを複数回投入する事が出来ます。<p>
以下のようなymlファイルを定義してください。<p>

 ```
Mouse:
  Prefecture:
    loop: 47
    col_info:
      name:
        init_data: set_prefecture
  1_Member:
    loop: 100
    col_info:
      name:
        init_data: Prefecture
        random: true
  2_Member:
    loop: 10
    col_info:
      name:
        init_data: Prefecture
        rotate: true
 ```

rake db:seedが終われば110件のMemberが入っているでしょう。<p>
        
---
### 今後の予定
---
○ シード投入時の挙動を並行処理化<p>
○ テスト記述<p>
○ リファクタリング<p>

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'slytherin', git: "https://github.com/SlytherinGem/Slytherin"
```

And then execute:
```bash
$ bundle install
```

Or install it yourself as:
```bash
$ gem install slytherin
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
