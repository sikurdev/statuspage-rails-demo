# An HTTP endpoint we check periodically. Named UptimeMonitor because Ruby's
# standard library already defines ::Monitor (used by Rails internals).
class UptimeMonitor < ApplicationRecord
  include Checkable

  has_many :check_results, dependent: :delete_all
  has_many :incidents, dependent: :destroy

  enum :status, { pending: "pending", up: "up", down: "down" }, default: :pending, validate: true

  normalizes :url, with: ->(url) { url.strip }

  validates :name, presence: true, uniqueness: true, length: { maximum: 100 }
  validates :url, presence: true, format: { with: %r{\Ahttps?://[^\s]+\z}i, message: "must be an http(s) URL" }
  validates :check_interval_seconds, numericality: { only_integer: true, in: 30..86_400 }
  validates :expected_status, numericality: { only_integer: true, in: 100..599 }
  validates :failure_threshold, numericality: { only_integer: true, in: 1..20 }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }
  scope :due_for_check, ->(now = Time.current) {
    active.where("last_checked_at IS NULL OR last_checked_at <= CAST(? AS timestamp) - make_interval(secs => check_interval_seconds)", now)
  }

  def open_incident
    incidents.unresolved.first
  end
end
