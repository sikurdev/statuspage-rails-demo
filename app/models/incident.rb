class Incident < ApplicationRecord
  STATUSES = %w[ investigating identified monitoring resolved ].freeze

  belongs_to :uptime_monitor
  has_many :updates, -> { order(created_at: :desc) }, class_name: "IncidentUpdate", dependent: :delete_all

  validates :title, :started_at, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :unresolved, -> { where(resolved_at: nil) }
  scope :resolved, -> { where.not(resolved_at: nil) }
  scope :recent_first, -> { order(started_at: :desc) }

  def resolved?
    resolved_at.present?
  end

  def duration
    (resolved_at || Time.current) - started_at
  end

  def resolve!(at: Time.current, body: "This incident has been resolved.")
    transaction do
      update!(status: "resolved", resolved_at: at)
      updates.create!(status: "resolved", body: body)
    end
    notify_subscribers_later
  end

  def notify_subscribers_later
    Subscriber.confirmed.find_each do |subscriber|
      IncidentMailer.with(incident: self, subscriber: subscriber).status_changed.deliver_later
    end
  end
end
