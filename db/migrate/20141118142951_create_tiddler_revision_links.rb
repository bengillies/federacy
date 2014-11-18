class CreateTiddlerRevisionLinks < ActiveRecord::Migration
  def change
    create_table :revision_links do |t|
      t.integer :start
      t.integer :end
      t.integer :link_type
      t.string :link
      t.string :tiddler_title
      t.string :space_name
      t.string :user_name
      t.string :title
      t.belongs_to :tiddler
      t.belongs_to :space
      t.belongs_to :user
      t.belongs_to :revision
    end
  end
end
