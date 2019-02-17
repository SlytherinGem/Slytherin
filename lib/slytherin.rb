require 'default_seeder.rb'
include DefaultSeeder

module Slytherin

=begin
  Slytherinのrake taskを読み込む用のプログラム
  今後、使う可能性があるのでコメント化
  module Rails
    class Railtie < ::Rails::Railtie
      railtie_name :slytherin

      rake_tasks do
        load "tasks/slytherin_tasks.rake"
      end
    end
  end
=end

  class Seeder
    # メソッド名: set_function_path
    # 引数: function_path -> メソッドを定義したファイルのpath
    # 動作: メソッドを定義したファイルのpathをインスタンス変数に格納する
    def set_function_path function_path = ""
      @function_path = function_path
    end

    # メソッド名: update_loop
    # 引数: key -> ymlファイルのkey
    #       loop_size -> loopの回数
    # 動作: loop回数を設定する
    def update_loop key, loop_size
      @update_loop = Hash.new if @update_loop.nil?
      @update_loop[key] = loop_size
    end

    # メソッド名: do_seed
    # 引数: yml_path -> ymlファイルのpath
    # 動作: ユーザに作成されたymlファイルに基づいてseedを実行する
    def do_seed yml_path
      exists_reconfigure_info = ->(){ @update_loop.present?}
      begin
        # ymlファイルの中身を受け取り
        yml_data = open(yml_path, 'r') { |f| YAML.load(f) }["Mouse"]

        # 登録する際のベースとなるテーブル情報の受け取り
        table_info = gen_table_info(yml_data)
        # ymlファイル以外で設定された情報があれば再設定する
        reconfigure_table_info(table_info) if exists_reconfigure_info.call()
        ActiveRecord::Base.transaction do
          # データ作成
          create_data(table_info)
        end
      rescue => e
        puts e.message
      end
    end

    private
    
    # メソッド名: only_development_puts
    # 引数: message -> デバッグメッセージ
    # 動作: 開発環境でのみputsする
    def only_development_puts message
      puts message if Rails.env.development?
    end

    # メソッド名: reconfigure_table_info
    # 引数: table_info -> テーブル情報
    # 動作: 受け取ったテーブル情報に対して要素を再度設定する
    def reconfigure_table_info table_info
      update_loop = ->(){
        @update_loop.each do |k, v|
          result = table_info.select{|item| item["key"] ==  k}.first
          raise SetError.new("指定されたキー: #{k} はymlに存在しません") if result.nil?
          result["loop"] = v
        end
      }

      # loop回数の再設定
      update_loop.call() if @update_loop.present?
    end

    # メソッド名: gen_table_info
    # 引数: yml_data -> ymlから抽出したhash
    # 動作: 登録するtableの情報に関してloopの回数やオプションも含めて作成する
    def gen_table_info(yml_data)
      # メソッドのパスが指定されていたら展開
      require @function_path if @function_path.present?

      # ymlファイルからのkey取得するための補助関数
      get_key_list = ->(yml_data){ yml_data.map{|m| m[0] }}

      # 不必要なカラム情報をブロックするための補助関数
      block_column = ->(col_name){
        return true  if col_name == "id"
        return false
      }

      # ユーザのカラムのタイポを検知するための補助関数
      check_defined_column = ->(yml_data, column_info, key){
        # ymlに記載されたカラム名を取得
        defined_col_list = yml_data["col_info"].map{|m| m[0] }
        # 実際のカラム名を取得
        col_list = column_info.map{|m| m["name"]}
        # 差集合であまりが出たらエラーとする
        raise NotExistsColumn.new("#{key}: カラム名が、存在しません") if !(defined_col_list - col_list).empty?
      }

      # 補助関数： key部分のprefixを取り除く
      remove_prefix = ->(key){ key.sub(/.*_/, "") }

      # 補助関数: optionをcolhashにセットする
      set_option_info = ->(col, defined_col_info, key){

        # 補助関数: option情報を入れ込む
        input_option = ->(col, defined_col_info, option){ 
          return () if defined_col_info[option].nil?
          col[option] = defined_col_info[option]
        }

        # 補助関数: 不適切に複数のオプションが設定されているケースを検知する
        check_option = ->(col){
          option_count = ["rotate", "random", "first", "last"].map{|m| col[m] }.count(true)
          raise TooManyOptions.new("#{key}: 指定されたオプションは、同時に使う事ができません") if option_count > 1
        }

        # 定義されたカラムの情報が存在しない場合、そのまま返却
        return col if defined_col_info.nil?

        # 初期値データの設定
        input_init_data_option = ->(col, defined_col_info){
          # 初期値データは空
          return () if defined_col_info["init_data"].nil?

          # 初期値データに配列が設定されている
          if defined_col_info["init_data"].kind_of?(Array)
            col["init_data"] = defined_col_info["init_data"].map{|m| 
              # {}で囲われていたらメソッドかモデルなので、evalを使用
              m =~ /^\s*<.*>\s*$/ ? eval(m.delete("<>")) : m
            }
            puts col["init_data"]
            return ()
          end

          # 初期値データにModelかメソッドが設定されている
          col["init_data"] = eval(defined_col_info["init_data"])
        }

        # 定義されたカラムの情報が存在する場合オプションを入れ込む
        input_option.call(col, defined_col_info, "rotate") 
        input_option.call(col, defined_col_info, "random")
        input_option.call(col, defined_col_info, "first")
        input_option.call(col, defined_col_info, "last")
        input_option.call(col, defined_col_info, "numberling")
        input_init_data_option.call(col, defined_col_info)

        # 不適切なオプションの指定の仕方をしていないか検証
        check_option.call(col)

        col
      }

      # 補助関数: loopブロックで定義された情報を元にloopのサイズを取得する
      get_loop_size = ->(defined_loop){
        # 数値が定義されている
        return defined_loop if defined_loop.kind_of?(Integer)
        # 配列が定義されている(lengthを取るだけなので中身の展開は不要)
        return defined_loop.length if defined_loop.kind_of?(Array)
        # Modelが定義されている
        return defined_loop.constantize if (defined_loop  =~ /^[A-Z][A-Za-z0-9]*$/)
        # メソッドが定義されている
        return eval(defined_loop).length if (defined_loop =~ /^[a-z][_a-z0-9]*$/)
      }

      # ymlに記述したkey部分を主軸にまわして登録するための情報を一括で作成する
      get_key_list.call(yml_data).reduce([]) do |table_info, key|
        # ymlに定義された情報を取得
        defined_data = yml_data[key]
        # prefixを外しymlのkeyからmodel抽出
        model = remove_prefix.call(key)
        # 抽出したmodelを元にDBにアクセスしにいきカラム情報を取得
        column_info =
        Module.const_get(model).columns.reduce([]) do |acc, col|
          # 登録しないブロック対象のカラムを弾く
          unless block_column.call(col.name)
            acc.push({"name" => col.name.to_s,
                      "type" => col.type.to_s,
                      "init_data" => nil,
                      "rotate" => nil,
                      "random" => nil,
                      "first" => nil,
                      "last" => nil,
                      "numberling" => nil})
            # 定義されているデータのoptionがあれば設定する
            set_option_info.call(acc.last, defined_data["col_info"][col.name.to_s], key) unless defined_data["col_info"].nil?

            acc
          else
            acc
          end
        end

        # 間違って定義したカラムがないかを最終チェック
        check_defined_column.call(defined_data, column_info, key) unless defined_data["col_info"].nil?

        # table情報に追加
        table_info.push({
          "model" => model,
          "key" => key,
          "get_column_info" => { model => column_info },
          "loop" => get_loop_size.call(defined_data["loop"])
        })
      end
    end

    # メソッド名: create_data
    # 引数: table_info -> テーブル情報
    # 動作: 受け取ったテーブル情報を元にデータを作成
    def create_data(table_info)

      # 補助関数: seed_dataを取得する
      get_seed_data = ->(col, i, default_seeder, key){

        # 補助関数: numberlingオプションが指定されていた場合の連番の付与
        add_numberling = ->(data){
          if data.kind_of?(String)
            data + "_#{i}"
          else
            UnexpectedTypeError.new("#{key}: String型以外で、numberlingオプションは使用不可能です")
          end
        }

        # 補助関数: ユーザが定義したinit_dataを取得する
        defined_seed = ->(init_data, col){ 

          # 補助関数: 設定したオプションによりデータを選択
          pick_data = ->(init_data, col){
            return init_data.sample if col["random"]
            return init_data.first if col["first"]
            return init_data.last if col["last"]
            return init_data.rotate(i).first
          }

          # data取得
          data = pick_data.call(init_data, col)
          return data
        }

        # 補助関数： デフォルトで定義してあるinit_dataを取得
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
          return default_seeder.boolean if type == "boolean"

          raise UnexpectedTypeError.new("#{key}: 予期しない型情報: #{type}カラム")
        }

        # init_dataの取得
        init_data = col["init_data"].nil? ? default_seed.call(col["type"], default_seeder) : defined_seed.call(col["init_data"], col)
        # 連番付与オプションが入ってい場合、連番を付与したinit_dataを返却
        return add_numberling.call(init_data) if col["numberling"]
        return init_data 
      }

      # 補助関数: 外部キー指定されているinit_dataをIDの配列に変換
      convert_references_init_data =->(column_info){
        column_info.each do |e|
          e["init_data"] = e["init_data"].all.pluck(:id) unless e["init_data"].kind_of?(Array) || e["init_data"].nil?
        end
      }

      # 補助関数: 外部キー指定されているloopをモデルの全体個数に変換
      convert_references_loop_data = ->(table){
        table["loop"] = table["loop"].all.count unless table["loop"].kind_of?(Integer)
      }

      table_info.each do |table|
        only_development_puts("#{table["model"]}のseedを実行します")
        # モデルの名前からカラム情報を取得
        column_info = table["get_column_info"][table["model"]]
        # カラムの名前を配列にする
        columns = column_info.map{|m| m["name"].to_sym }
        # 外部キー指定されている情報を適切な情報に変換しておく
        convert_references_init_data.call(column_info)
        convert_references_loop_data.call(table)
        # ymlのkey取得（エラー発生時に場所を示すため）
        key = table["key"]
        # データを一括で登録
        values =
        table["loop"].times.reduce([]) do |values, i|
          # seed_dataを取得して登録情報を追加
          values << column_info.map{|m| get_seed_data.call(m, i, DefaultSeeder, key) }
        end
          # 一括登録
          table["model"].constantize.import(columns, values,  validate: false)
      end
    end
  end

  # 各、エラークラス
  class UnexpectedTypeError < StandardError; end
  class ReferencesError < StandardError; end
  class NotExistsColumn < StandardError; end
  class TooManyOptions < StandardError; end
  class SetError < StandardError; end
end