require "test_helper"

class UptimeMonitorTest < ActiveSupport::TestCase
  test "valid with defaults" do
    monitor = UptimeMonitor.new(name: "New", url: "https://example.com")
    assert monitor.valid?
    assert monitor.pending?
    assert_equal 60, monitor.check_interval_seconds
  end

  test "requires an http(s) url" do
    monitor = UptimeMonitor.new(name: "Bad", url: "ftp://example.com")
    assert_not monitor.valid?
    assert_includes monitor.errors[:url], "must be an http(s) URL"
  end

  test "validates ranges" do
    monitor = UptimeMonitor.new(name: "X", url: "https://x.test", check_interval_seconds: 5, expected_status: 999, failure_threshold: 0)
    assert_not monitor.valid?
    assert monitor.errors.include?(:check_interval_seconds)
    assert monitor.errors.include?(:expected_status)
    assert monitor.errors.include?(:failure_threshold)
  end

  test "names are unique" do
    assert_not UptimeMonitor.new(name: uptime_monitors(:website).name, url: "https://x.test").valid?
  end

  test "due_for_check returns active monitors whose interval elapsed" do
    travel_to 3.minutes.from_now do
      due = UptimeMonitor.due_for_check
      assert_includes due, uptime_monitors(:website)     # 60s interval, last checked 5 min ago
      assert_not_includes due, uptime_monitors(:api)     # 300s interval, last checked 4 min ago
      assert_not_includes due, uptime_monitors(:paused)  # inactive
    end
  end

  test "never-checked active monitors are due" do
    monitor = UptimeMonitor.create!(name: "Fresh", url: "https://fresh.test")
    assert_includes UptimeMonitor.due_for_check, monitor
  end

  test "record_check! stores the result and updates monitor status" do
    monitor = uptime_monitors(:website)
    check = monitor.record_check!(probe_result(success: false, http_status: 500))

    assert check.down?
    assert_equal 500, check.http_status
    assert monitor.reload.down?
    assert_in_delta Time.current, monitor.last_checked_at, 1.second
  end
end
