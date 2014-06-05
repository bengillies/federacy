class CreateTiddler < ActiveRecord::Migration
  def change
    create_table :tiddlers do |t|
      t.belongs_to :space

      t.timestamps
    end
  end
end
