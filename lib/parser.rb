require 'regex.rb'
class Parser
  class NotExistsColumn < StandardError; end
  class << self
    # メソッド名: parse
    # 引数: yml_data -> ymlから抽出したhash
    # 動作: 登録するtableの情報に関してloopの回数やオプションも含めて作成する
    def parse(yml_path, function_path = nil)
      yml_data = get_yml_data(yml_path)

      set_function = ->(){
        # set_function_pathメソッドによるパスの設定
        if function_path.present?
          require function_path
          return 
        end

        # yml記載によるパスの設定
        if yml_data["$function"].present?
          require yml_data["$function"]
        end
      }.call()
          
      # ymlに記述したkey部分を主軸にまわして登録するための情報を一括で作成する
      get_key_list(yml_data).reduce([]) do |parse_data, key|
        # ymlに定義された情報を取得
        defined_data = yml_data[key]
        # prefixを外しymlのkeyからmodel抽出
        model = remove_key_prefix(key)
        column_info = get_column_info(model, defined_data, key)
        check_defined_column(defined_data, column_info, key) unless defined_data["col_info"].nil?
        parse_data.push({
          "model" => model,
          "key" => key,
          "get_column_info" => { model => column_info },
          "loop" => defined_data["loop"],
          "log" => defined_data["log"],
          "disabled" => get_disabled(defined_data["disabled"]),
          "save" => defined_data["save"]
        })
      end
    end

    private
    def get_column_info model, defined_data, key
      Module.const_get(model).columns.reduce([]) do |acc, col|
        acc.push({"name" => col.name.to_s,
                  "type" => col.type.to_s,
                  "use_col_info" => nil,
                  "init_data" => nil,
                  "rotate" => nil,
                  "random" => nil,
                  "first" => nil,
                  "last" => nil,
                  "numberling" => nil})
        # 定義されているデータの中にoptionがあれば設定する
        OptionSetter.set(acc.last, defined_data["col_info"][col.name.to_s], key) unless defined_data["col_info"].nil?
        acc
      end
    end

    def get_disabled disabled
      disabled.gsub(" ", "").split("-").map{ |m| m.to_i } if disabled.present?
    end

    def get_yml_data yml_path
      open(yml_path, 'r') { |f| YAML.load(f) }["Mouse"]
    end

    def get_key_list yml_data
      # $で設定している部分を消去
      yml_data.delete_if {|key, value| key =~ HEAD_CONFIG}
      yml_data.map{|m| m[0] } 
    end

    def remove_key_prefix key; key.sub(KEY_PREFIX, "") end

    def check_defined_column yml_data, column_info, key
      # ymlに記載されたカラム名を取得
      defined_col_list = yml_data["col_info"].map{|m| m[0] }
      # 実際のカラム名を取得
      col_list = column_info.map{|m| m["name"]}
      # 差集合であまりが出たらエラーとする
      raise NotExistsColumn.new("#{key}: カラム名が、存在しません") if !(defined_col_list - col_list).empty?
    end
  end
end

class OptionSetter
  class TooManyOptions < StandardError; end
  class << self
    def set data, defined_col_info, key
      return data if defined_col_info.nil?
      # dataにoptionをセット
      set_option(data, defined_col_info, "rotate") 
      set_option(data, defined_col_info, "random")
      set_option(data, defined_col_info, "first")
      set_option(data, defined_col_info, "last")
      set_option(data, defined_col_info, "numberling")
      set_option(data, defined_col_info, "init_data")
      set_option(data, defined_col_info, "use_col_info")
      # 不適切なオプションの指定の仕方をしていないか検証
      check_option(data)
      data
    end

    private
    def set_option data, defined_col_info, option
      return if defined_col_info[option].nil?
      data[option] = defined_col_info[option]
    end

    def check_option data
      option_count = ["rotate", "random", "first", "last"].map{|m| data[m] }.count(true)
      raise TooManyOptions.new("#{key}: 指定されたオプションは、同時に使う事ができません") if option_count > 1
    end
  end
end