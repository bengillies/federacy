class CreateTiddlerRevisionFields < ActiveRecord::Migration
  def change
    create_table :revision_fields do |t|
      t.string :key
      t.string :value
      t.belongs_to :revision

      t.timestamps
    end
  end
end
