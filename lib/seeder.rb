class DefaultSeeder
  class UnexpectedTypeError < StandardError; end
  class << self
    def get type
      return string() if type == "string"
      return float() if type == "float"
      return text() if type == "text"
      return integer() if type == "integer"
      return datetime() if type == "datetime"
      return date() if type == "date"
      return decimal() if type == "decimal"
      return time() if type == "time"
      return binary() if type == "binary"
      return boolean() if type == "boolean"
      raise UnexpectedTypeError.new("#{key}: 予期しない型情報: #{type}カラム")  
    end

    private
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

class DefinedSeeder
  class << self
    def get col, i
      init_data =
      if col["init_data"].kind_of?(Array)
        col["init_data"].map{|m| m =~ /^\s*<.*>\s*$/ ? eval(m.delete("<>")) : m }
      elsif col["init_data"] =~ /^\s*<.*>\s*$/
       replace_expression(col["init_data"].delete("<>"))
      else
        [col["init_data"]] 
      end

      return init_data.sample if col["random"]
      return init_data.first if col["first"]
      return init_data.last if col["last"]
      return init_data.rotate(i).first
    end

    def replace_expression init_data
      if (init_data =~ /^:[A-Z][A-Za-z0-9]*$/)
        eval(init_data.delete(":")).all.pluck(:id)
      else
        eval(init_data)
      end
    end

  end
end