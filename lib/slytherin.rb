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

    # メソッド名: set_loop
    # 引数: key -> ymlファイルのkey
    #       loop_size -> loopの回数
    # 動作: loop回数を設定する 
    def set_loop key, loop_size
      @update_loop = Hash.new if @update_loop.nil?
      @update_loop[key] = loop_size
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
      # yml以外で設定された情報があれば再設定する
      reconfigure_table_info(table_info) if defined? @update_loop
      # データを作成
      ActiveRecord::Base.transaction do
        DataCreater.create(table_info)
      end
    end

    private
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
  end
end