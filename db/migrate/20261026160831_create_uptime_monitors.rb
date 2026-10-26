class CreateUptimeMonitors < ActiveRecord::Migration[8.1]
  def change
    create_table :uptime_monitors do |t|
      t.string :name, null: false
      t.string :url, null: false
      t.integer :check_interval_seconds, null: false, default: 60
      t.integer :expected_status, null: false, default: 200
      t.integer :failure_threshold, null: false, default: 3
      t.string :status, null: false, default: "pending"
      t.boolean :active, null: false, default: true
      t.datetime :last_checked_at

      t.timestamps
    end
    add_index :uptime_monitors, :name, unique: true
  end
end
