class IncidentUpdate < ApplicationRecord
  belongs_to :incident, touch: true

  validates :body, presence: true
  validates :status, inclusion: { in: Incident::STATUSES }
end
