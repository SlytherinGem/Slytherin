require 'seeder.rb'
include DefinedSeeder
include DefaultSeeder

module DataCreater
  class UnexpectedTypeError < StandardError; end
  def create table_info
    table_info.each do |table|
      only_development_puts("#{table["model"]}のseedを実行します")
      # モデルの名前からカラム情報を取得
      column_info = table["get_column_info"][table["model"]]
      # 外部キー指定されている情報の変換
      convert_references(table, column_info)
      # カラムの名前を配列にする
      col_name_arr = get_col_name_arr(column_info)
      # ymlのkey取得（エラー発生時に場所を示すため）
      key = table["key"]
      # データを一括で登録
      values =
        table["loop"].times.reduce([]) do |values, i|
          # seed_dataを取得して登録情報を追加
          values << column_info.map{|m| get_seed_data(m, i, key) }
        end
        # 一括登録
        table["model"].constantize.import(col_name_arr, values,  validate: false)
      end
    end

    def get_col_name_arr column_info
      column_info.map{|m| m["name"].to_sym }
    end
      
    def convert_references table, column_info
      convert_references_to_loop_data(table)
      convert_references_to_init_data(column_info)
    end

    private

    # メソッド名: get_seed_data
    # 引数: col => カラム情報 
    #       i => 連番（エラー処理用）
    #       key => ymlのkey(エラー処理用)
    # 動作: オプションなどを適用してｍseed_dataを作成する。定義されていなかった場合は、DefaultSeederから取得
    #       定義されている場合はDefinedSeederから取得
    def get_seed_data col, i, key
      # seed_dataの取得
      seed_data = col["init_data"].nil? ? DefaultSeeder.get(col["type"]) : DefinedSeeder.get(col["init_data"], col, i)
      # 連番付与オプションが入ってい場合、連番を付与したinit_dataを返却
      seed_data = add_numberling(seed_data, i, key) if col["numberling"]
      return seed_data 
    end

    # メソッド名: add_numberling
    # 引数: seed_data => 取得したseedデータ
    #       i         => 連番(エラー処理用)
    #       key       => ymlのkey(エラー処理用)
    # 動作: numberlingオプションが付与されていた場合に数値をつける
    def add_numberling seed_data, i, key
      if seed_data.kind_of?(String)
        seed_data += "_#{i}"
      else
        UnexpectedTypeError.new("#{key}: String型以外で、numberlingオプションは使用不可能です")
      end
    end

    # メソッド名: convert_references_to_init_data
    # 引数: column_info
    # 動作: init_dataにモデルが入っているのを、そのモデルのIDの配列に変換する
    def convert_references_to_init_data column_info
      column_info.each do |e|
        e["init_data"] = e["init_data"].all.pluck(:id) unless e["init_data"].kind_of?(Array) || e["init_data"].nil?
      end
    end

    # メソッド名: convert_references_to_loop_data
    # 引数: table_info
    # 動作: loopにモデルが入っているのを、そのモデルの配列のlengthに変換する
    def convert_references_to_loop_data table_info
      table_info["loop"] = table_info["loop"].all.count unless table_info["loop"].kind_of?(Integer)
    end

    # メソッド名: only_development_puts
    # 引数: message -> デバッグメッセージ
    # 動作: 開発環境でのみputsする
    def only_development_puts message
      puts message if Rails.env.development?
    end
end

