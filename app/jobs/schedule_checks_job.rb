# Runs every minute (config/recurring.yml) and enqueues checks for monitors
# whose interval has elapsed.
class ScheduleChecksJob < ApplicationJob
  queue_as :default

  def perform
    UptimeMonitor.due_for_check.find_each do |monitor|
      CheckMonitorJob.perform_later(monitor)
    end
  end
end
