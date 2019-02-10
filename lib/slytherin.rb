if Rails.env.test?
  require './test/slytherin/data_set'
else
  require './db/slytherin/data_set'
end

module Slytherin
  class Seeder
    def do_seed path
      begin 
        # ymlデータを読み取り
        yml_data = open(path, 'r') { |f| YAML.load(f) }["Mouse"]
        # テーブル情報を形成
        table_info = gen_table_info(yml_data)
        ActiveRecord::Base.transaction do
          # 一括で登録
          create_data(table_info)
        end
      rescue => e
        puts e.message
      end
    end

    private
    def gen_table_info(yml_data)
      
      # 名前: get_key_list
      # 動作： 処理中に使用するキー値をリスト化して取得
      get_key_list = ->(yml_data){ yml_data.map{|m| m[0] }}

      # 名前: block_column
      # 動作： 登録するカラムに制限をかける
      block_column = ->(col_name){
        return true  if col_name == "id"
        return false
      }

      # 名前: check_column
      # 動作： カラム情報のチェック処理
      check_column = ->(yml_data, column_info, key){
        # ymlに記載されたカラムの情報をリスト化
        yml_col_list = yml_data["col_info"].map{|m| m[0] }
        # DBから取得してきたカラムの名前をリスト化
        col_list = column_info.map{|m| m["name"]}
        # 定義されてあるymlのカラム名がDB側に存在しない
        raise NotExistsColumn.new("yml側に定義されている#{key}部分のカラム名が、存在しません")  if !(yml_col_list - col_list).empty?
      }

      # 名前: remove_prefix
      # 動作: ymlファイルに記述されている[任意の文字列_モデル名]の[任意の文字列_]部分を削除して返却
      remove_prefix = ->(key){ key.sub(/.*_/, "") }

      # 名前: input_addtion_info
      # 動作: ymlファイルでユーザが定義したカラム情報を追加
      input_addtion_info = ->(col, col_info){
        return col if col_info.nil?

        input_rotate_option = ->(col, col_info){ 
          col["rotate"] = col_info["rotate"] 

          col
        }

        input_init_data = ->(col, col_info){
          # ユーザによるシード値に配列が使われている
          return col["init_data"] =  col_info["init_data"] if col_info["init_data"].kind_of?(Array)
          # ユーザによるシード値にモデルが使われている
          if (col_info["init_data"]  =~ /^[A-Z][A-Za-z0-9]*$/)
            # 外部キー指定がなされているか
            col["references"] = col_info["references"]
            raise ReferencesError.new("外部キーを指定したseedを入れる時はreferencesをtrueにしてください") unless col["references"]
            col["init_data"] = col_info["init_data"].constantize
          else
            # ユーザによるシード値にメソッドが使われている
            col["init_data"] = send(col_info["init_data"])
          end

          col
        }

        # シード値が循環するかしないか
        input_rotate_option.call(col, col_info)
        # シード値の定義を展開
        input_init_data.call(col, col_info)

        col
      }

      # ymlファイルの定義を元にテーブルの登録情報を作成
      get_key_list.call(yml_data).each.reduce([]) do |table_info, key|
        yml_table_info = yml_data[key]
        obj = remove_prefix.call(key)
        column_info =
        Module.const_get(obj).columns.reduce([]) do |acc, col|
          unless block_column.call(col.name)
            acc.push({"name" => col.name.to_s,
                      "type" => col.type.to_s,
                      "init_data" => nil,
                      "rotate" => nil,
                      "references" => nil })

            input_addtion_info.call(acc.last, yml_table_info["col_info"][col.name.to_s]) unless yml_table_info["col_info"].nil?
            acc
          else
            acc
          end
        end

        # 登録されるカラムの情報が適切かどうかを検証
        check_column.call(yml_table_info, column_info, key)
        # 登録情報を追加
        table_info.push({"obj" => obj,
                         "get_column_info" => { obj => column_info },
                         "loop" => yml_table_info["loop"]})
      end
    end

    def create_data(table_info)

      # 名前: get_seed_data
      # 動作： シード値の取得
      #       ユーザがymlで定義したシード値かデフォルトのシード値か、どちらかを取得する
      get_seed_data = ->(col, i, default_seeder){

        user_seed = ->(seed_data, rotate){ return rotate ? seed_data.rotate(i).first : seed_data.sample }

        default_seed = ->(type, default_seeder){
          return default_seeder.string if type == "string"
          return default_seeder.float if type == "float"
          return default_seeder.text if type == "text"
          return default_seeder.integer if type == "integer"
          return default_seeder.datetime if type == "datetime"
          return default_seeder.date if type == "date"
          return default_seeder.decimal if type == "decimal"
          return default_seeder.time if type == "time"
          return default_seeder.time if type == "binary"
          return default_seeder.time if type == "boolean"

          raise UnexpectedTypeError.new("予期しない型情報: #{type}カラム")
        }

        seed_data = col["init_data"]

        # ユーザが定義したシード値を入れる
        return user_seed.call(seed_data, col["rotate"]) unless seed_data.nil?
        # デフォルトで定義されているシード値を入れる
        return default_seed.call(col["type"], default_seeder)
      }

      # 名前: convert_references_seed_data
      # 動作: referencesオプションで外部キー指定されているモデルのシード値を配列に変換する
      convert_references_seed_data =->(column_info){
        column_info.each do |e|
          e["init_data"] = e["init_data"].all.pluck(:id) if e["references"]
        end
      }

      # デフォルトで定義されているシード値取得
      default_seeder = DefaultSeeder.new

      table_info.each do |table|
        # test時はログが邪魔なので表示しない
        puts "#{table["obj"]}のseedを実行します" unless Rails.env.test?
        # カラム情報を取得
        column_info = table["get_column_info"][table["obj"]]
        # カラム名をリスト化
        columns = column_info.map{|m| m["name"].to_sym }
        # 外部キー指定されているシード値に入っているモデル名をIDのリストに変換
        convert_references_seed_data.call(column_info)
        # BULK INSERTに必要な情報を形成
        values =
        table["loop"].times.reduce([]) do |values, i|
          values << column_info.map{|m| get_seed_data.call(m, i, default_seeder) }
        end
          # 一括で登録
          table["obj"].constantize.import(columns, values,  validate: false)
      end
    end

  end

  class UnexpectedTypeError < StandardError; end
  class ReferencesError < StandardError; end
  class NotExistsColumn < StandardError; end

  class DefaultSeeder
    def string; SecureRandom.hex(8) end
    def text; SecureRandom.hex(300) end
    def integer; rand(100) end
    def datetime; DateTime.now end
    def date; DateTime.now end
    def float; rand(0.0..100.0) end
    def decimal; rand(0.0..1000000000.0) end
    def time; DateTime.now end
    def binary; SecureRandom.hex(300) end
    def boolean; [true, false].sample end
  end
end