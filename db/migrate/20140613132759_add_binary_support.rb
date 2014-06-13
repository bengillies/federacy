class AddBinarySupport < ActiveRecord::Migration
  def change

    create_table :text_revisions do |t|
      t.string :text
      t.integer :tiddler_id
    end

    create_table :file_revisions do |t|
      t.string :file_path
      t.integer :tiddler_id
    end

    change_table :revisions do |t|
      t.remove :text
      t.integer :textable_id
      t.string :textable_type
    end
  end
end
