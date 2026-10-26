class CheckResult < ApplicationRecord
  belongs_to :uptime_monitor

  enum :status, { up: "up", down: "down" }, validate: true

  validates :checked_at, presence: true

  scope :recent, -> { order(checked_at: :desc) }

  def summary
    error.presence || "HTTP #{http_status}"
  end
end
