require "test_helper"

class IncidentTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup { @monitor = uptime_monitors(:website) } # threshold: 3 failures, no open incident

  test "does not open an incident below the failure threshold" do
    assert_no_difference -> { Incident.count } do
      record_checks(@monitor, false, false)
    end
  end

  test "opens an incident after N consecutive failures with a timeline entry" do
    assert_difference -> { @monitor.incidents.count }, 1 do
      record_checks(@monitor, false, false, false)
    end

    incident = @monitor.open_incident
    assert_equal "Website is down", incident.title
    assert_equal "investigating", incident.status
    assert_equal [ "investigating" ], incident.updates.map(&:status)
    assert_match "failed 3 consecutive checks", incident.updates.first.body
  end

  test "a success in between resets the consecutive failure count" do
    assert_no_difference -> { Incident.count } do
      record_checks(@monitor, false, false, true, false, false)
    end
  end

  test "further failures do not open a second incident" do
    record_checks(@monitor, false, false, false)
    assert_no_difference -> { Incident.count } do
      record_checks(@monitor, false, false, false)
    end
  end

  test "auto-resolves on recovery and appends a resolved update" do
    record_checks(@monitor, false, false, false)
    incident = @monitor.open_incident

    record_checks(@monitor, true)

    incident.reload
    assert incident.resolved?
    assert_equal "resolved", incident.status
    assert_equal %w[ resolved investigating ], incident.updates.map(&:status)
    assert_nil @monitor.reload.open_incident
    assert @monitor.up?
  end

  test "notifies confirmed subscribers only, on open and on resolve" do
    assert_enqueued_emails 1 do # only subscribers(:confirmed)
      record_checks(@monitor, false, false, false)
    end
    assert_enqueued_emails 1 do
      record_checks(@monitor, true)
    end
  end

  test "database allows only one open incident per monitor" do
    @monitor.incidents.create!(title: "first", started_at: Time.current)
    assert_raises(ActiveRecord::RecordNotUnique) do
      @monitor.incidents.create!(title: "second", started_at: Time.current)
    end
  end

  test "duration of a resolved incident" do
    assert_equal 1.hour, incidents(:website_past).duration
  end
end
