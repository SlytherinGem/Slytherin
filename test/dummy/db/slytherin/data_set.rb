def set_prefecture
  [
    "北海道",
    "青森県",
    "岩手県",
    "宮城県",
    "秋田県",
    "山形県",
    "福島県",
    "茨城県",
    "栃木県",
    "群馬県",
    "埼玉県",
    "千葉県",
    "東京都",
    "神奈川県",
    "新潟県",
    "富山県",
    "石川県",
    "福井県",
    "山梨県",
    "長野県",
    "岐阜県",
    "静岡県",
    "愛知県",
    "三重県",
    "滋賀県",
    "京都府",
    "大阪府",
    "兵庫県",
    "奈良県",
    "和歌山県",
    "鳥取県",
    "島根県",
    "岡山県",
    "広島県",
    "山口県",
    "徳島県",
    "香川県",
    "愛媛県",
    "高知県",
    "福岡県",
    "佐賀県",
    "長崎県",
    "熊本県",
    "大分県",
    "宮崎県",
    "鹿児島県",
    "沖縄県"
  ]
end

def set_time flg
  return [DateTime.now - 10000.day] if flg == 1
  return [DateTime.now - 20000.day] if flg == 2
  return [DateTime.now - 30000.day] if flg == 3
end

def set_birthday name
  result = {
    "スズキ" =>  DateTime.parse('1993-02-22'), 
    "タナカ" =>  DateTime.parse('1993-02-23'), 
    "ヤマダ" =>  DateTime.parse('1993-02-24')
  }[name]
end