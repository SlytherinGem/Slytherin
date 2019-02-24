module Parser
  class NotExistsColumn < StandardError; end
  class TooManyOptions < StandardError; end
  def get_yml_data yml_path
    # ymlファイルの中身を受け取り
    open(yml_path, 'r') { |f| YAML.load(f) }["Mouse"]
  end

  # メソッド名: parse
  # 引数: yml_data -> ymlから抽出したhash
  # 動作: 登録するtableの情報に関してloopの回数やオプションも含めて作成する
  def parse(yml_path, function_path)
    yml_data = get_yml_data(yml_path)
    # メソッドのパスが指定されていたら展開
    require function_path if function_path.present?

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
          return ()
        end

        # 初期値データにModelかメソッドが設定されている
        if defined_col_info["init_data"] =~ /^\s*<.*>\s*$/
          col["init_data"] = eval(defined_col_info["init_data"].delete("<>"))
            return ()
        end

        # 文字列やboolが設定されているので配列に変換
        col["init_data"] = [defined_col_info["init_data"]]
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
      if (defined_loop =~ /^\s*<.*>\s*$/)
        obj = defined_loop.delete("<>")
        # Modelが定義されている
        return obj.constantize if (obj  =~ /^[A-Z][A-Za-z0-9]*$/)
        # メソッドが定義されている
        return eval(obj).length if (obj =~ /^[a-z][_a-z0-9]*$/)
      end

        # 要素にヒットしなかったらloopのサイズは1とする
        return 1
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
end