# Slytherin
Slytherinは、ymlファイルを使って誰でも簡単にシードを記述する事ができるGemです。

## 使用方法
railsのdbディレクトリ配下に以下のフォルダ構成を作成してください

 ```
db
│
└───slytherin
│   │   data_set.rb
│   │
│   └───mouse
│       │  [任意の名前].yml
```

### mouse-ymlの記述方法

例えば、下記の例だと、
Prefectureモデルを使って
loopの回数は47回
初期値には、開発者がdata_set.rbに記述したset_prefectureをnameカラムに対して使用する事になります。
また、nameカラム以外にカラムが存在する場合は、Slytherinが自動的に定義したデータが入る事になります。

 ```
Mouse:
  Prefecture:
    loop: 47
    col_info:
      name:
        init_data: set_prefecture
 ```
 
init_dataにモデル名を記述しreferences: trueを設定する事で以下のような外部キー参照にも対応する事ができます。
 
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
 ```
 
 また、シードデータをランダムで投入したくない場合は、rotate: trueを設定することによって
 順番に作成する事も可能です。
 
 ```
Mouse:
  Prefecture:
    loop: 47
    col_info:
      name:
        init_data: set_prefecture
        rotate: true
 ```
 
### data_set.rbの記述方法
 配列を返却するメソッドを記述してください。
 以下の例だと都道府県を返却します。
 
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
  　...
  ]
end
 ```
 
### 実行
seed.rbファイルに以下のように記述しrails db:seedを実行してください。
 
  ```
slytherin = Slytherin::Seeder.new()
slytherin.do_seed('./db/slytherin/mouse/[任意の名前].yml')
 
  ```
 
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
