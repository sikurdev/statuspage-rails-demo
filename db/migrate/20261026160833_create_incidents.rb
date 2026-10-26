class CreateIncidents < ActiveRecord::Migration[8.1]
  def change
    create_table :incidents do |t|
      t.references :uptime_monitor, null: false, foreign_key: { on_delete: :cascade }
      t.string :title, null: false
      t.string :status, null: false, default: "investigating"
      t.datetime :started_at, null: false
      t.datetime :resolved_at

      t.timestamps
    end
    add_index :incidents, :started_at
    # At most one open incident per monitor, enforced by the database.
    add_index :incidents, :uptime_monitor_id, unique: true, where: "resolved_at IS NULL",
      name: "index_incidents_one_open_per_monitor"
  end
end
