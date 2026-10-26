require "test_helper"

class CheckMonitorJobTest < ActiveJob::TestCase
  setup { @monitor = uptime_monitors(:website) }

  test "records an up check from a real (stubbed) HTTP request" do
    stub = stub_request(:get, @monitor.url).with(headers: { "User-Agent" => HttpProbe::USER_AGENT }).to_return(status: 200)

    assert_difference -> { @monitor.check_results.count }, 1 do
      CheckMonitorJob.perform_now(@monitor)
    end

    assert_requested stub
    check = @monitor.check_results.recent.first
    assert check.up?
    assert_equal 200, check.http_status
    assert @monitor.reload.up?
  end

  test "records failures and opens an incident after the threshold" do
    stub_request(:get, @monitor.url).to_return(status: 503)

    3.times { |i| travel(i.minutes) { CheckMonitorJob.perform_now(@monitor) } }

    assert @monitor.reload.down?
    incident = @monitor.open_incident
    assert incident
    assert_match "Expected HTTP 200, got 503", incident.updates.first.body
  end

  test "resolves the open incident once the endpoint recovers" do
    api = uptime_monitors(:api) # down with an open incident, expects 204
    stub_request(:get, api.url).to_return(status: 204)

    CheckMonitorJob.perform_now(api)

    assert api.reload.up?
    assert incidents(:api_outage).reload.resolved?
  end

  test "skips inactive monitors" do
    assert_no_difference -> { CheckResult.count } do
      CheckMonitorJob.perform_now(uptime_monitors(:paused))
    end
  end
end

class ScheduleChecksJobTest < ActiveJob::TestCase
  test "enqueues checks only for due monitors" do
    travel_to 3.minutes.from_now do
      assert_enqueued_with(job: CheckMonitorJob, args: [ uptime_monitors(:website) ]) do
        ScheduleChecksJob.perform_now
      end
      assert_enqueued_jobs 1, only: CheckMonitorJob
    end
  end
end
