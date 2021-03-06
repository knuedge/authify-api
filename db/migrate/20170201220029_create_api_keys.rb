# Creates the apikeys table
class CreateApiKeys < ActiveRecord::Migration[5.0]
  def change
    create_table :apikeys do |t|
      t.references :user, index: true
      t.string :access_key, index: true
      t.text :secret_key_digest

      t.timestamps
    end
  end
end
