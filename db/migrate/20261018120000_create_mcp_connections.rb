class CreateMcpConnections < ActiveRecord::Migration[8.2]
  def change
    create_table :mcp_connections do |t|
      t.references :blog, null: false, foreign_key: true
      t.text :client_id, null: false
      t.string :client_name, null: false
      t.string :redirect_uri, null: false
      t.string :code_digest, index: { unique: true }
      t.string :code_challenge
      t.datetime :code_expires_at
      t.string :token_digest, index: { unique: true }
      t.timestamps
    end
  end
end
