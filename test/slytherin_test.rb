require 'test_helper'

class Slytherin::Test < ActiveSupport::TestCase
  # テスト内容: 最低限の情報のみで作成したymlファイルが正常に使用できるか
  # 期待値: 47件の都道府県レコードの生成
  test "can create pref data without input" do
    slytherin = Slytherin
    slytherin.do_seed './test/dummy/db/slytherin/prefecture/simple.yml'
    # 47レコード登録済み
    assert_equal(47, Pref.all.count)
  end

  # テスト内容: 都道府県配列が記述されたymlファイルが正常に使用できるか
  # 期待値: 3レコードの生成
  #         都道府県が登録されていること
  test "can create pref data by array" do
    slytherin = Slytherin
    slytherin.do_seed './test/dummy/db/slytherin/prefecture/array.yml'
    # 3レコード生成済み
    assert_equal(3, Pref.all.count)
    # 内容が登録されているか確認
    registerd = ["北海道", "青森県", "岩手県"]
    registerd.each do |e|
      assert_equal(true, Pref.find_by(name: e).present?)
    end
  end

  # テスト内容: メソッドが記述されたymlファイルが正常に使用できるか
  # 期待値: 47レコードの生成
  #         全都道府県が登録されていること
  test "can create pref data by method" do
    require './test/dummy/db/slytherin/data_set.rb'
    slytherin = Slytherin
    slytherin.set_function_path './test/dummy/db/slytherin/data_set.rb'
    slytherin.do_seed './test/dummy/db/slytherin/prefecture/method.yml'
    # 47レコード生成済み
    assert_equal(47, Pref.all.count)
    # 内容が登録されているか確認
    registerd = set_prefecture
    registerd.each do |e|
      assert_equal(true, Pref.find_by(name: e).present?)
    end
  end

  # テスト内容: loopにメソッドが記述されたymlファイルが正常に使用できるか
  # 期待値: 47レコードの生成
  #         全都道府県が登録されていること
  test "can create pref data with loop method" do
    require './test/dummy/db/slytherin/data_set.rb'
    slytherin = Slytherin
    slytherin.set_function_path './test/dummy/db/slytherin/data_set.rb'
    slytherin.do_seed './test/dummy/db/slytherin/prefecture/loop_method.yml'
    # 47レコード生成済み
    assert_equal(47, Pref.all.count)
    # 内容が登録されているか確認
    registerd = set_prefecture
    registerd.each do |e|
      assert_equal(true, Pref.find_by(name: e).present?)
    end
  end

  # テスト内容: numberlingオプションが正常に動作するか
  # 期待値: 3レコードの生成
  #         連番付きの都道府県が登録されていること
  test "can create pref data with numberling option" do
    slytherin = Slytherin
    slytherin.do_seed './test/dummy/db/slytherin/prefecture/numberling.yml'
    # 3レコード生成済み
    assert_equal(3, Pref.all.count)
    # 内容が登録されているか確認
    registerd = ["北海道_0", "青森県_1", "岩手県_2"]
    registerd.each do |e|
      assert_equal(true, Pref.find_by(name: e).present?)
    end
  end

  # テスト内容: firstオプションが正常に動作するか
  # 期待値: 3レコードの生成
  #         一番最初の都道府県のみが登録されていること
  test "can create pref data with first option" do
    slytherin = Slytherin
    slytherin.do_seed './test/dummy/db/slytherin/prefecture/first.yml'
    # 3レコード生成済み
    assert_equal(3, Pref.all.count)
    assert_equal(3,Pref.where(name: "北海道").count)
  end
  
  # テスト内容: lastオプションが正常に動作するか
  # 期待値: 3レコードの生成
  #         一番最後の都道府県のみが登録されていること
  test "can create pref data with last option" do
    slytherin = Slytherin
    slytherin.do_seed './test/dummy/db/slytherin/prefecture/last.yml'
    # 3レコード生成済み
    assert_equal(3, Pref.all.count)
    assert_equal(3,Pref.where(name: "岩手県").count)
  end

  # テスト内容: 複合オプションの適用
  #            first + numberling
  # 期待値: 3レコードの生成
  #         一番最後の都道府県のみが登録されていること + 連番付き
  test "can create pref data with first and numberling option" do
    slytherin = Slytherin
    slytherin.do_seed './test/dummy/db/slytherin/prefecture/first_numberling.yml'
    # 3レコード生成済み
    assert_equal(3, Pref.all.count)
    # 内容が登録されているか確認
    registerd = ["北海道_0", "北海道_1", "北海道_2"]
    registerd.each do |e|
      assert_equal(true, Pref.find_by(name: e).present?)
    end
  end

end
