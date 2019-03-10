class SaveData
  class << self
    def init
      @save = Hash.new
    end

    def save save_name, column_info, model, latest_id, last_id
      # 変数定義
      @save[save_name] = {}
      # 登録した分のレコード取得
      result = model.where(id: latest_id .. last_id)
      # 各、結果の代入
      column_info.each do |e|
        @save[save_name][e["name"]] = result.pluck(e["name"].to_sym)
      end
    end

    def get
      @save
    end

  end
end