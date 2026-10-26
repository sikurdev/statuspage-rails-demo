class CheckMonitorJob < ApplicationJob
  queue_as :checks
  # Never run two checks of the same monitor at once.
  limits_concurrency to: 1, key: ->(monitor) { monitor }, duration: 2.minutes

  discard_on ActiveJob::DeserializationError

  def perform(monitor)
    return unless monitor.active?

    result = HttpProbe.call(monitor.url, expected_status: monitor.expected_status)
    monitor.record_check!(result)
  end
end
