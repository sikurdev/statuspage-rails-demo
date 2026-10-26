require "test_helper"

class AdminMonitorsTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include AdminAuthHelper

  test "admin is disabled when ADMIN_PASSWORD is not set" do
    with_admin_password(nil) do
      get admin_monitors_path, headers: admin_headers("")
      assert_response :service_unavailable
    end
  end

  test "requires valid basic auth" do
    with_admin_password do
      get admin_monitors_path
      assert_response :unauthorized

      get admin_monitors_path, headers: admin_headers("wrong")
      assert_response :unauthorized
    end
  end

  test "lists and shows monitors" do
    with_admin_password do
      get admin_monitors_path, headers: admin_headers
      assert_response :success
      assert_select "tbody tr", 3

      get admin_monitor_path(uptime_monitors(:api)), headers: admin_headers
      assert_response :success
      assert_select "h1", /API/
    end
  end

  test "creates a monitor and queues its first check" do
    with_admin_password do
      assert_enqueued_with(job: CheckMonitorJob) do
        post admin_monitors_path, headers: admin_headers, params: {
          uptime_monitor: { name: "Search", url: "https://search.test", check_interval_seconds: 60, expected_status: 200, failure_threshold: 3, active: "1" }
        }
      end
      monitor = UptimeMonitor.find_by!(name: "Search")
      assert_redirected_to admin_monitor_path(monitor)
    end
  end

  test "rejects invalid monitors" do
    with_admin_password do
      post admin_monitors_path, headers: admin_headers, params: { uptime_monitor: { name: "", url: "nope" } }
      assert_response :unprocessable_content
    end
  end

  test "updates, checks and deletes a monitor" do
    monitor = uptime_monitors(:website)
    with_admin_password do
      patch admin_monitor_path(monitor), headers: admin_headers, params: { uptime_monitor: { check_interval_seconds: 120 } }
      assert_redirected_to admin_monitor_path(monitor)
      assert_equal 120, monitor.reload.check_interval_seconds

      assert_enqueued_with(job: CheckMonitorJob, args: [ monitor ]) do
        post check_admin_monitor_path(monitor), headers: admin_headers
      end

      assert_difference -> { UptimeMonitor.count }, -1 do
        delete admin_monitor_path(monitor), headers: admin_headers
      end
      assert_redirected_to admin_monitors_path
    end
  end
end
