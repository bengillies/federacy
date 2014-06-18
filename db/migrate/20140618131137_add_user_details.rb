class AddUserDetails < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.string :name
      t.string :icon
    end
  end
end
