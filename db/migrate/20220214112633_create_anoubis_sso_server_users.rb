class CreateAnoubisSsoServerUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :email, limit: 100, null: false
      t.string :name, limit: 100, null: false
      t.string :surname, limit: 100, null: false
      t.string :timezone, limit: 30, null: false
      t.string :locale, limit: 10, null: false, default: 'ru-RU'
      t.string :password_digest, limit: 60, null: false
      t.string :uuid, limit: 40, null: false
      t.string :public, limit: 40, null: false

      t.timestamps
    end
    add_index :users, [:email], unique: true
    add_index :users, [:uuid], unique: true
    add_index :users, [:public], unique: true
  end
end
