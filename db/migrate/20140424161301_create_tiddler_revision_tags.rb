class CreateTiddlerRevisionTags < ActiveRecord::Migration
  def change
    create_table :revision_tags do |t|
      t.string :name
      t.belongs_to :revision

      t.timestamps
    end
  end
end
