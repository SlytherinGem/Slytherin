require './db/slytherin/data_set'

module Slytherin
  
  class Seeder
    def gen_table_info(base)
      get_table_obj = ->(base){ base.map{|m| m[0] }  }
  
      block_column = ->(col_name){
        return true  if col_name == "id"
        return false
      }
  
      input_addtion_info = ->(col, col_info){
        return col if col_info.nil?
        init_data = col_info["init_data"]    
        if (init_data =~ /^[A-Z][a-z]*$/)
          col["references"] = col_info["references"]
          raise ReferencesError.new("外部キーを指定したseedを入れる時はreferencesをtrueにしてください") unless col["references"]
        
          col["init_data"] = col_info["init_data"].constantize
        else
          col["init_data"] = send(col_info["init_data"])
        end
  
        col["rotate"] = col_info["rotate"]
  
        col
      }
  
      get_table_obj.call(base).each.reduce([]) do |table_info, obj|
        data = base[obj]
        column_info =
        Module.const_get(obj).columns.reduce([]) do |column_info, col|
          unless block_column.call(col.name)
            column_info.push({"name" => col.name.to_s, 
                              "type" => col.type.to_s,
                              "init_data" => nil,
                              "rotate" => nil,
                              "references" => nil })
  
            input_addtion_info.call(column_info.last, data["col_info"][col.name.to_s]) unless data["col_info"].nil?
  
            column_info
          else
            column_info
          end
        end
        table_info.push({"obj" => obj, 
                         "get_column_info" => { obj => column_info},
                         "loop" => data["loop"]})
      end
    end
  
    def create_data(table_info)
      get_seed_data = ->(col, i, default_seeder){
    
        user_seed = ->(seed_data, rotate){ return rotate ? seed_data.rotate(i).first : seed_data.sample }
  
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
        return user_seed.call(seed_data, col["rotate"]) unless seed_data.nil?
        return default_seed.call(col["type"], default_seeder)
      }
  
      convert_references_seed_data =->(column_info){
        column_info.each do |e|
          e["init_data"] = e["init_data"].all.pluck(:id) if e["references"]
        end
      }
  
      default_seeder = CreateInitialization.new
      table_info.each do |table|
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

    def do_seed path
      begin
        yml_data = open(path, 'r') { |f| YAML.load(f) }["Mouse"]
        table_info = gen_table_info(yml_data)
        ActiveRecord::Base.transaction do
          create_data(table_info)
        end
      rescue => e
        puts "[ ERROR :]"
        puts "-" * 100
        puts e.message
        puts "-" * 100
      end
    end
  end

  class UnexpectedTypeError < StandardError; end
  class ReferencesError < StandardError; end
  
  class CreateInitialization
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