module DefaultSeeder
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