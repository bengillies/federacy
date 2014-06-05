class CreateTiddlerRevisions < ActiveRecord::Migration
  def change
    create_table :revisions do |t|
      t.string :title
      t.text :text
      t.integer :tiddler_id
      t.string :content_type

      t.timestamps
    end
  end
end
