# Records check results for a monitor and drives the incident lifecycle:
# open an incident after N consecutive failures, resolve it on recovery.
module Checkable
  extend ActiveSupport::Concern

  # Persists a CheckResult from an HttpProbe::Result and updates incidents.
  def record_check!(result, checked_at: Time.current)
    transaction do
      check = check_results.create!(
        status: result.success? ? "up" : "down",
        http_status: result.http_status,
        response_time_ms: result.response_time_ms,
        error: result.error,
        checked_at: checked_at
      )
      update!(status: check.status, last_checked_at: checked_at)
      result.success? ? resolve_open_incident!(check) : open_incident_if_threshold_reached!(check)
      check
    end
  end

  private
    def open_incident_if_threshold_reached!(check)
      return if open_incident
      return unless consecutive_failures >= failure_threshold

      incident = incidents.create!(title: "#{name} is down", started_at: check.checked_at)
      incident.updates.create!(status: "investigating",
        body: "#{name} failed #{failure_threshold} consecutive checks. Last error: #{check.summary}.")
      incident.notify_subscribers_later
    end

    def resolve_open_incident!(check)
      incident = open_incident or return
      incident.resolve!(at: check.checked_at,
        body: "#{name} is responding normally again (HTTP #{check.http_status}, #{check.response_time_ms} ms).")
    end

    def consecutive_failures
      check_results.order(checked_at: :desc).limit(failure_threshold).pluck(:status).take_while { |status| status == "down" }.size
    end
end
