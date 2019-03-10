require 'default_seeder.rb'
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
        # モデル取得
        model = table["model"].constantize
        # init_dataを配列に変換して更新
        update_init_data(column_info)
        # カラムの名前を配列にする
        col_name_arr = column_info.map{|m| m["name"].to_sym }
        #  ymlのkey取得（エラー発生時に場所を示すため）
        key = table["key"]
        latest_record = model.last
        acc_id = latest_id = latest_record.nil? ? 0 : latest_record.id
        # データを一括で登録
        values =
        get_loop_size(table["loop"]).times.reduce([]) do |values, i|
          # init_dataを抽出し登録情報を追加
          values << column_info.map{|m| 
            m["name"] == "id" ? acc_id += 1 : InitData.make(m, i, key) 
          }
        end
        # disabledの設定
        values.slice!(table["disabled"][0], table["disabled"][1]) if table["disabled"].present?
        # 一括登録
        model.import(col_name_arr, values,  validate: false)
      end
    end

    private

    def update_init_data column_info
      column_info.each do |e|
        e["init_data"] =
        if e["init_data"].kind_of?(Array)
          e["init_data"].map{|m| m =~ /^\s*<.*>\s*$/ ? eval(m.delete("<>")) : m }
        elsif e["init_data"] =~ /^\s*<.*>\s*$/
         replace_init_data_expression(e["init_data"].delete("<>"))
        elsif e["init_data"].nil?
          nil
        else
          [e["init_data"]] 
        end
      end
    end

    def replace_init_data_expression init_data
      if (init_data =~ /^:[A-Z][A-Za-z0-9]*$/)
        eval(init_data.delete(":")).all.pluck(:id)
      else
        eval(init_data)
      end
    end

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

  end
end

class InitData
  class << self
    def make col, i, key
      data =
      if col["init_data"].nil?
        DefaultSeeder.get(col["type"])
      else
        apply_arr_option(col, i)
      end
      apply_contents_option(col, i, data, key)
    end

    def apply_arr_option col, i
      return col["init_data"].sample if col["random"]
      return col["init_data"].first if col["first"]
      return col["init_data"].last if col["last"]

      col["init_data"].rotate(i).first
    end

    def apply_contents_option col, i, data, key
      if col["numberling"]
        add_numberling(data, i, key)
      else
        data
      end
    end

    def add_numberling seed_data, i, key
      if seed_data.kind_of?(String)
        seed_data += "_#{i}"
      else
        UnexpectedTypeError.new("#{key}: String型以外で、numberlingオプションは使用不可能です")
      end
    end

  end
end
