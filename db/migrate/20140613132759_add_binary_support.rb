class AddBinarySupport < ActiveRecord::Migration
  def change

    create_table :text_revisions do |t|
      t.text :text
      t.string :content_type
      t.integer :tiddler_id
    end

    create_table :file_revisions do |t|
      t.string :file
      t.string :content_type
      t.integer :tiddler_id
    end

    change_table :revisions do |t|
      t.remove :text
      t.remove :content_type
      t.integer :textable_id
      t.string :textable_type
    end
  end
end
