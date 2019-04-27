require 'default_seeder.rb'
require 'slytherin_logger.rb'
require 'save_data.rb'
require 'regex.rb'
class DataCreater
  class UnexpectedTypeError < StandardError; end
  class << self
    def create table_info
      SaveData.init()
      table_info.each do |table|
        # log情報が存在すれば出力
        SlytherinLogger.print(table["log"]) unless table["log"].nil?
        # モデルの名前からカラム情報を取得
        column_info = table["get_column_info"][table["model"]]
        # modelデータやメソッドで定義されているinit_dataを配列に変換する
        convert_init_data_all(column_info)
        # モデル取得
        model = table["model"].constantize
        # ymlのkey取得（エラー発生時に場所を示すため）
        key = table["key"]
        # 最新のIDを取得
        acc_id = latest_id = model.last.nil? ? 0 : model.last.id
        maked_data = Hash.new
        values =
        get_loop_size(table["loop"]).times.reduce([]) do |acc, i|
          # init_dataを抽出し登録情報を追加
          acc.push(column_info.map{|m|
            if m["name"] == "id"
              maked_data = Hash.new
              acc_id += 1
              maked_data[m["name"]] = acc_id
            elsif m["use_col_info"]
              # メソッドを一時的に格納
              tmp = m["init_data"]
              # init_dataを配列に変換
              m["init_data"] = convert_init_data(m, maked_data)
              maked_data[m["name"]] = InitData.make(m, i, key)
              # 配列情報からメソッドに戻す
              m["init_data"] = tmp
            else
              maked_data[m["name"]] = InitData.make(m, i, key) 
            end
            maked_data[m["name"]]
          })
        end
        # disabledが設定されているレコードは削除
        # ymlファイルではsliceを0始まりではなく1始まりで設定するので、その分の-1
        values.slice!(table["disabled"][0] - 1, table["disabled"][1]) if table["disabled"].present?
        # 一括で登録
        model.import(column_info.map{|m| m["name"].to_sym }, values, validate: false)

        # saveの指定があれば保存
        # データ作成前の最新のid + 1　から　最新のidまでをsave
        SaveData.save(table["save"], column_info, model, (latest_id + 1), acc_id) if table["save"].present? 
      end
    end

    private
    def convert_init_data_all column_info
      column_info.each do |e|
        e["init_data"] =
        if e["use_col_info"]
          # use_col_infoがついているものは、データが作成されてから実行なので
          # このタイミングで作成できない。そのため、そのまま返却
          e["init_data"]
        else
          convert_init_data(e, nil)
        end
      end
    end

    def convert_init_data e, maked_data
      if e["init_data"].kind_of?(Array)
        col = maked_data if maked_data.present?
        e["init_data"].map{|m| m =~ EVAL ? eval(m.delete("<>")) : m }
      elsif e["init_data"] =~ EVAL
        replace_init_data_expression(e, maked_data)
      elsif e["init_data"].nil?
        nil
      else
        [e["init_data"]] 
      end
    end

    def replace_init_data_expression e, maked_data
      init_data = e["init_data"].delete("<>")
      if (init_data =~ COLON_MODEL)
        eval(init_data.delete(":")).all.pluck(:id)
      else
        save = SaveData.get if defined_save? init_data
        col = maked_data if maked_data.present?
        e["init_data"] = eval(init_data)
        convert_init_data(e, nil)
      end
    end

    def get_loop_size defined_loop
      if defined_loop.kind_of?(Integer)
        defined_loop
      elsif defined_loop.kind_of?(Array)
        defined_loop.length
      elsif defined_loop =~ EVAL
        result = replace_loop_expression(defined_loop.delete("<>"))
        get_loop_size(result)
      else
        1
      end
    end

    def replace_loop_expression expression
      if (expression =~ COLON_MODEL)
        eval(expression.delete(":")).all.count
      else
        save = SaveData.get if defined_save? expression
        eval(expression)
      end
    end

    def defined_save? init_data
      init_data.gsub(" ", "") =~ SAVEDATA
    end

  end
end

class InitData
  class << self
    def make col, i, key
      init_data =
      if col["init_data"].nil?
        DefaultSeeder.get(col["type"])
      else
        pick_init_data(col, i)
      end
      shape_init_data(col, i, init_data, key)
    end

    def pick_init_data col, i
      return col["init_data"].sample if col["random"]
      return col["init_data"].first if col["first"]
      return col["init_data"].last if col["last"]

      col["init_data"].rotate(i).first
    end

    def shape_init_data col, i, data, key
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
