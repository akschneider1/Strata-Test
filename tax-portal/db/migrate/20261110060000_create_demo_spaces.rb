# frozen_string_literal: true

# Each visitor to the demo gets a private copy of the demo people. A demo
# space is one such copy; its people and their records on file point at it.
class CreateDemoSpaces < ActiveRecord::Migration[8.0]
  def change
    create_table :demo_spaces, id: :uuid do |t|
      t.datetime :last_used_at, null: false
      t.timestamps
    end
    add_index :demo_spaces, :last_used_at

    add_column :users, :demo_space_id, :uuid
    add_index :users, :demo_space_id
    add_column :wage_records, :demo_space_id, :uuid
    add_index :wage_records, :demo_space_id
  end
end
