class CreateCheckResults < ActiveRecord::Migration[8.1]
  def change
    create_table :check_results do |t|
      t.references :uptime_monitor, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.string :status, null: false
      t.integer :http_status
      t.integer :response_time_ms
      t.string :error
      t.datetime :checked_at, null: false

      t.timestamps
    end
    add_index :check_results, [ :uptime_monitor_id, :checked_at ]
  end
end
