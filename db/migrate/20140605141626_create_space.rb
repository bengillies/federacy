class CreateSpace < ActiveRecord::Migration
  def change
    create_table :spaces do |t|
      t.string :name, default: ''
      t.text :description, default: ''

      t.timestamps
    end
  end
end
