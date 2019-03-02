class SlytherinLogger
  class << self
    def print message
      puts message if Rails.env.development?
    end
  end
end