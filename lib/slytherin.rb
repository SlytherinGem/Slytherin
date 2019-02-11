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
    def set_path seed_path, function_path = ""
      @seed_path = seed_path
      @function_path = function_path
    end

    def do_seed
      begin
        yml_data = open(@seed_path, 'r') { |f| YAML.load(f) }["Mouse"]
        table_info = gen_table_info(yml_data)
        ActiveRecord::Base.transaction do
          create_data(table_info)
        end
      rescue => e
        puts e.message
      end
    end

    private
    def gen_table_info(yml_data)
      require @function_path if @function_path.present?

      get_key_list = ->(yml_data){ yml_data.map{|m| m[0] }}

      block_column = ->(col_name){
        return true  if col_name == "id"
        return false
      }

      check_column = ->(yml_data, column_info, key){
        yml_col_list = yml_data["col_info"].map{|m| m[0] }
        col_list = column_info.map{|m| m["name"]}
        raise NotExistsColumn.new("#{key}: カラム名が、存在しません") if !(yml_col_list - col_list).empty?
      }

      remove_prefix = ->(key){ key.sub(/.*_/, "") }

      input_addtion_info = ->(col, col_info, key){
        return col if col_info.nil?

        input_option = ->(col, col_info, option){ 
          col[option] = col_info[option] 

          col
        }

        check_option = ->(col){
          option_count = ["rotate", "random", "first", "last"].map{|m| col[m] }.count(true)
          raise TooManyOptions.new("#{key}: 指定されたオプションは、同時に使う事ができません") if option_count > 1
        }

        input_init_data = ->(col, col_info){
          return col["init_data"] =  col_info["init_data"] if col_info["init_data"].kind_of?(Array)
          if (col_info["init_data"]  =~ /^[A-Z][A-Za-z0-9]*$/)
            raise ReferencesError.new("#{key}: 外部キーを指定したseedを入れる時はreferencesをtrueにしてください") unless col["references"]
            col["init_data"] = col_info["init_data"].constantize
          else
            col["init_data"] = send(col_info["init_data"])
          end

          col
        }

        input_option.call(col, col_info, "rotate")
        input_option.call(col, col_info, "random")
        input_option.call(col, col_info, "first")
        input_option.call(col, col_info, "last")
        input_option.call(col, col_info, "numberling")
        input_option.call(col, col_info, "references")
        check_option.call(col)

        input_init_data.call(col, col_info)

        col
      }

      get_key_list.call(yml_data).each.reduce([]) do |table_info, key|
        addtion_info = yml_data[key]
        obj = remove_prefix.call(key)
        column_info =
        Module.const_get(obj).columns.reduce([]) do |acc, col|
          unless block_column.call(col.name)
            acc.push({"name" => col.name.to_s,
                      "type" => col.type.to_s,
                      "init_data" => nil,
                      "rotate" => nil,
                      "random" => nil,
                      "first" => nil,
                      "last" => nil,
                      "numberling" => nil,
                      "references" => nil })

            input_addtion_info.call(acc.last, addtion_info["col_info"][col.name.to_s], key) unless addtion_info["col_info"].nil?
            acc
          else
            acc
          end
        end

        check_column.call(addtion_info, column_info, key) unless addtion_info["col_info"].nil?
        table_info.push({"obj" => obj,
                         "get_column_info" => { obj => column_info },
                         "loop" => addtion_info["loop"]})
      end
    end

    def create_data(table_info)
      get_seed_data = ->(col, i, default_seeder){

        user_seed = ->(seed_data, col){ 
          pick_data = ->(seed_data, col){
            return seed_data.sample if col["sample"]
            return seed_data.first if col["first"]
            return seed_data.last if col["last"]
            return seed_data.rotate(i).first
          }

          add_numberling = ->(data){
            if data.kind_of?(String)
              data + "_#{i}"
            else
              UnexpectedTypeError.new("String型以外で、numberlingオプションは使用不可能です")
            end
          }

          data = pick_data.call(seed_data, col)
          return add_numberling.call(data) if col["numberling"]
          return data
        }

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
        return user_seed.call(seed_data, col) unless seed_data.nil?
        return default_seed.call(col["type"], default_seeder)
      }

      convert_references_seed_data =->(column_info){
        column_info.each do |e|
          e["init_data"] = e["init_data"].all.pluck(:id) if e["references"]
        end
      }

      default_seeder = DefaultSeeder.new
      table_info.each do |table|
        puts "#{table["obj"]}のseedを実行します" unless Rails.env.test?
        column_info = table["get_column_info"][table["obj"]]
        columns = column_info.map{|m| m["name"].to_sym }
        convert_references_seed_data.call(column_info)
        values =
        table["loop"].times.reduce([]) do |values, i|
          values << column_info.map{|m| get_seed_data.call(m, i, default_seeder) }
        end
          table["obj"].constantize.import(columns, values,  validate: false)
      end
    end
  end

  class UnexpectedTypeError < StandardError; end
  class ReferencesError < StandardError; end
  class NotExistsColumn < StandardError; end
  class TooManyOptions < StandardError; end

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