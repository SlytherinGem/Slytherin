class CreateMembers < ActiveRecord::Migration[5.1]
  def change
    create_table :members do |t|
      t.string :name
      t.text :remarks
      t.date :birthday
      t.references :pref

      t.timestamps
    end
  end
end
