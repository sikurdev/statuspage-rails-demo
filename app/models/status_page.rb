# Read model for the public status page: overall status, per-monitor state and
# daily uptime bars, computed with a single aggregate query.
class StatusPage
  DAYS = 90

  DayBar = Data.define(:date, :total, :up) do
    def uptime = total.zero? ? nil : (up * 100.0 / total)

    def level
      case uptime
      when nil then "none"
      when 99.9.. then "up"
      when 95.. then "degraded"
      else "down"
      end
    end

    def label
      uptime ? "#{date.to_fs(:long)}: #{format('%.2f', uptime)}% uptime (#{total} checks)" : "#{date.to_fs(:long)}: no data"
    end
  end

  attr_reader :monitors

  def initialize(today: Date.current)
    @today = today
    @monitors = UptimeMonitor.active.ordered.to_a
  end

  def overall_status
    states = monitors.map(&:status) - [ "pending" ]
    if states.empty? || states.all?("up") then :operational
    elsif states.all?("down") then :major_outage
    else :partial_outage
    end
  end

  def days
    @days ||= ((@today - (DAYS - 1))..@today).to_a
  end

  def bars_for(monitor)
    stats = daily_stats.fetch(monitor.id, {})
    days.map { |day| DayBar.new(date: day, total: stats.dig(day, 0) || 0, up: stats.dig(day, 1) || 0) }
  end

  def uptime_for(monitor)
    total, up = daily_stats.fetch(monitor.id, {}).values.transpose.map(&:sum)
    total.to_i.zero? ? nil : (up * 100.0 / total)
  end

  def active_incidents
    Incident.unresolved.includes(:uptime_monitor, :updates).recent_first
  end

  def past_incidents(limit: 10)
    Incident.resolved.where(started_at: days.first.beginning_of_day..).includes(:uptime_monitor, :updates).recent_first.limit(limit)
  end

  private
    # { monitor_id => { date => [total, up] } }
    def daily_stats
      @daily_stats ||= CheckResult
        .where(uptime_monitor_id: monitors.map(&:id), checked_at: days.first.beginning_of_day..)
        .group(:uptime_monitor_id, Arel.sql("DATE(checked_at)"))
        .pluck(:uptime_monitor_id, Arel.sql("DATE(checked_at)"), Arel.sql("COUNT(*)"), Arel.sql("COUNT(*) FILTER (WHERE status = 'up')"))
        .each_with_object(Hash.new { |h, k| h[k] = {} }) { |(id, date, total, up), acc| acc[id][date] = [ total, up ] }
    end
end
