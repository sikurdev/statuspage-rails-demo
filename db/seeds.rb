# Synthetic demo data: 4 monitors, 90 days of check history (one check every
# 30 minutes) and a handful of incidents with timelines.
# Idempotent: wipes demo tables first. Run with `bin/rails db:seed`.

rng = Random.new(42)
now = Time.current.change(sec: 0)
step = 30.minutes
start = (now - 90.days).beginning_of_day

Incident.delete_all
CheckResult.delete_all
UptimeMonitor.delete_all
Subscriber.delete_all

monitors = {
  website: UptimeMonitor.create!(name: "Website", url: "https://example.com", check_interval_seconds: 60),
  api: UptimeMonitor.create!(name: "Public API", url: "https://example.org", check_interval_seconds: 60, failure_threshold: 2),
  docs: UptimeMonitor.create!(name: "Documentation", url: "https://www.iana.org/help/example-domains", check_interval_seconds: 300),
  billing: UptimeMonitor.create!(name: "Legacy billing API", url: "http://127.0.0.1:9/health", check_interval_seconds: 120)
}

# Outage windows per monitor => incident timelines.
outages = {
  api: [ { from: (now - 63.days).change(hour: 2), minutes: 120, updates: [
    [ "investigating", "Public API failed 2 consecutive checks. Last error: Expected HTTP 200, got 502." ],
    [ "identified", "A database failover left the API pool without connections. Restarting workers." ],
    [ "monitoring", "Workers restarted, error rate is back to normal. Monitoring." ],
    [ "resolved", "Public API is responding normally again." ]
  ] } ],
  website: [ { from: (now - 21.days).change(hour: 14), minutes: 150, updates: [
    [ "investigating", "Website failed 3 consecutive checks. Last error: Net::OpenTimeout: execution expired." ],
    [ "resolved", "CDN provider mitigated a regional routing issue. Website is responding normally again." ]
  ] }, { from: (now - 4.days).change(hour: 9), minutes: 90, updates: [
    [ "investigating", "Website failed 3 consecutive checks. Last error: Expected HTTP 200, got 503." ],
    [ "resolved", "A bad deploy was rolled back. Website is responding normally again." ]
  ] } ],
  billing: [ { from: now - 3.hours, minutes: nil, updates: [
    [ "investigating", "Legacy billing API failed 3 consecutive checks. Last error: Errno::ECONNREFUSED: Connection refused." ],
    [ "identified", "The legacy billing host is out of disk space. Migration to the new billing service is in progress." ]
  ] } ]
}

down_at = ->(key, time) do
  outages.fetch(key, []).any? { |o| time >= o[:from] && (o[:minutes].nil? || time < o[:from] + o[:minutes].minutes) }
end

monitors.each do |key, monitor|
  rows = []
  time = start
  while time <= now
    down = down_at.(key, time) || (key == :docs && rng.rand < 0.0012) # rare blips below the incident threshold
    http_status = down ? [ 502, 503, nil ].sample(random: rng) : 200
    rows << {
      uptime_monitor_id: monitor.id, checked_at: time, created_at: time, updated_at: time,
      status: down ? "down" : "up",
      http_status: http_status,
      response_time_ms: down ? nil : (80 + rng.rand(120) + (key == :docs ? 150 : 0)),
      error: if down then http_status ? "Expected HTTP 200, got #{http_status}" : "Errno::ECONNREFUSED: Connection refused" end
    }
    time += step
  end
  rows.each_slice(2_000) { |batch| CheckResult.insert_all!(batch) }
  monitor.update!(status: rows.last[:status], last_checked_at: rows.last[:checked_at])

  outages.fetch(key, []).each do |outage|
    resolved_at = outage[:minutes] && outage[:from] + outage[:minutes].minutes
    incident = monitor.incidents.create!(title: "#{monitor.name} is down", started_at: outage[:from],
      resolved_at: resolved_at, status: resolved_at ? "resolved" : outage[:updates].last.first)
    outage[:updates].each_with_index do |(status, body), i|
      at = resolved_at && status == "resolved" ? resolved_at : outage[:from] + (i * 20).minutes
      incident.updates.create!(status: status, body: body, created_at: at, updated_at: at)
    end
  end
end

Subscriber.create!(email: "subscriber@example.com", confirmed_at: now)

puts "Seeded #{UptimeMonitor.count} monitors, #{CheckResult.count} check results, " \
     "#{Incident.count} incidents (#{Incident.unresolved.count} active), #{Subscriber.count} subscriber."
