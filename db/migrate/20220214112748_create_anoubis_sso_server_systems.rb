class CreateAnoubisSsoServerSystems < ActiveRecord::Migration[7.0]
  def change
    create_table :systems do |t|
      t.string :title, limit: 100, null: false
      t.string :uuid, limit: 40, null: false
      t.string :public, limit: 40, null: false
      t.integer :ttl, default: 3600, null: false
      t.integer :state, default: 0, null: false
      t.json :jwk
      t.json :request_uri

      t.timestamps
    end
    add_index :systems, [:uuid], unique: true
    add_index :systems, [:public], unique: true
  end
end
