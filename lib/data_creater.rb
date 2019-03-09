require 'seeder.rb'
require 'slytherin_logger.rb'

class DataCreater
  class UnexpectedTypeError < StandardError; end
  class << self
    def create table_info
      table_info.each do |table|
        # log情報が存在すれば出力
        SlytherinLogger.print(table["log"]) unless table["log"].nil?
        # モデルの名前からカラム情報を取得
        column_info = table["get_column_info"][table["model"]]
        # カラムの名前を配列にする
        col_name_arr = get_col_name_arr(column_info)
        #  ymlのkey取得（エラー発生時に場所を示すため）
        key = table["key"]
        # loop_sizeを取得
        loop_size = get_loop_size(table["loop"])
        # データを一括で登録
        values =
        loop_size.times.reduce([]) do |values, i|
          # seed_dataを取得して登録情報を追加
          values << column_info.map{|m| get_seed_data(m, i, key) }
        end
        # 一括登録
        table["model"].constantize.import(col_name_arr, values,  validate: false)
      end
    end

    private

    def get_loop_size defined_loop    
      if defined_loop.kind_of?(Integer)
        defined_loop
      elsif defined_loop.kind_of?(Array)
        defined_loop.length
      elsif defined_loop =~ /^\s*<.*>\s*$/
        result = replace_loop_expression(defined_loop.delete("<>"))
        get_loop_size(result)
      else
        1
      end
    end

    def replace_loop_expression expression
      if (expression =~ /^:[A-Z][A-Za-z0-9]*$/)
        eval(expression.delete(":")).all.count
      else
        eval(expression)
      end
    end
  
    def get_col_name_arr column_info
      column_info.map{|m| m["name"].to_sym }
    end
      
    # メソッド名: get_seed_data
    # 引数: col => カラム情報 
    #       i => 連番（エラー処理用）
    #       key => ymlのkey(エラー処理用)
    # 動作: オプションなどを適用してｍseed_dataを作成する。定義されていなかった場合は、DefaultSeederから取得
    #       定義されている場合はDefinedSeederから取得
    def get_seed_data col, i, key
      seed_data = col["init_data"].nil? ? DefaultSeeder.get(col["type"]) : DefinedSeeder.get(col, i)
      # 連番付与オプションが入ってい場合、連番を付与したseed_dataを返却
      if col["numberling"]
        add_numberling(seed_data, i, key)
      else
        seed_data
      end
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
  end
end