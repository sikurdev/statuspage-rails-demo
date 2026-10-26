require "test_helper"

class StatusPageFlowTest < ActionDispatch::IntegrationTest
  test "public status page shows overall status, monitors, bars and incidents" do
    get root_path
    assert_response :success

    assert_select "#overall-status", text: /Partial outage/
    assert_select ".monitor", 2 # paused monitor is hidden
    assert_select "#uptime_monitor_#{uptime_monitors(:website).id} .bar", 90
    assert_select ".incident--active h3", text: "API is down"
    assert_select ".incident--resolved h3", text: "Website is down"
    assert_select "form[action='#{subscriptions_path}']"
  end

  test "all systems operational when everything is up" do
    UptimeMonitor.update_all(status: "up")
    Incident.update_all(resolved_at: Time.current, status: "resolved")
    get root_path
    assert_select "#overall-status", text: /All systems operational/
    assert_select ".incident--active", 0
  end
end
