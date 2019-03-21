require 'data_creater.rb'
require 'parser.rb'
module Slytherin
  class SetError < StandardError; end
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

  class << self
    # メソッド名: set_function_path
    # 引数: function_path -> メソッドを定義したファイルのpath
    # 動作: メソッドを定義したファイルのpathをインスタンス変数に格納する
    def set_function_path function_path = ""
      @function_path = function_path
    end

    # メソッド名: do_seed
    # 引数: yml_path -> ymlファイルのpath
    # 動作: ユーザに作成されたymlファイルに基づいてseedを実行する
    def do_seed yml_path
      # 処理しやすいようにymlを独自のデータ構造にParseする
      table_info = 
      if defined? @function_path
        Parser.parse(yml_path, @function_path)
      else
        Parser.parse(yml_path, nil)
      end
      # データを作成
      ActiveRecord::Base.transaction do
        DataCreater.create(table_info)
      end
    end

  end
end