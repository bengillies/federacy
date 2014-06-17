class AddPermissions < ActiveRecord::Migration
  def change
    change_table :spaces do |t|
      t.integer :space_type, default: 0
    end

    change_table :tiddlers do |t|
      t.belongs_to :user
    end

    change_table :revisions do |t|
      t.belongs_to :user
    end

    create_table :space_users do |t|
      t.belongs_to :space
      t.belongs_to :user
      t.integer :access, default: 0
    end
  end
end
