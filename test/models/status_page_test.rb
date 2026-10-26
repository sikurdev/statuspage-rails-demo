require "test_helper"

class StatusPageTest < ActiveSupport::TestCase
  test "overall status ignores pending/inactive monitors" do
    assert_equal :partial_outage, StatusPage.new.overall_status

    uptime_monitors(:api).update!(status: "up")
    assert_equal :operational, StatusPage.new.overall_status

    UptimeMonitor.update_all(status: "down")
    assert_equal :major_outage, StatusPage.new.overall_status
  end

  test "builds 90 daily bars with uptime per day" do
    page = StatusPage.new
    bars = page.bars_for(uptime_monitors(:website))

    assert_equal 90, bars.size
    assert_equal Date.current, bars.last.date
    assert_equal "up", bars.last.level
    assert_equal "down", bars[-2].level        # the only check yesterday failed
    assert_equal "none", bars.first.level
    assert_in_delta 50.0, page.uptime_for(uptime_monitors(:website)), 0.01
  end

  test "lists active and past incidents" do
    page = StatusPage.new
    assert_equal [ incidents(:api_outage) ], page.active_incidents.to_a
    assert_equal [ incidents(:website_past) ], page.past_incidents.to_a
  end
end
