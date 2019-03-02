require 'test_helper'

class Slytherin::Test < ActiveSupport::TestCase
  # テスト内容: 最低限の情報のみでymlファイルを作成し動作させる
  # 期待値: 47件の都道府県レコードの生成
  test "can create data without input" do
    slytherin = Slytherin
    slytherin.do_seed './test/dummy/db/slytherin/prefecture/test_1.yml'
    assert_equal(47, Pref.all.count)
  end
end
