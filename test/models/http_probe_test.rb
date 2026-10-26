require "test_helper"

class HttpProbeTest < ActiveSupport::TestCase
  test "success when status matches" do
    stub_request(:get, "https://ok.test/health").to_return(status: 200)
    result = HttpProbe.call("https://ok.test/health")

    assert result.success?
    assert_equal 200, result.http_status
    assert_kind_of Integer, result.response_time_ms
    assert_nil result.error
  end

  test "failure when status does not match expectation" do
    stub_request(:get, "https://ok.test/").to_return(status: 200)
    result = HttpProbe.call("https://ok.test/", expected_status: 204)

    assert_not result.success?
    assert_equal "Expected HTTP 204, got 200", result.error
  end

  test "timeouts and connection errors are failures" do
    stub_request(:get, "https://slow.test/").to_timeout
    result = HttpProbe.call("https://slow.test/")
    assert_not result.success?
    assert_nil result.http_status
    assert_match "Net::OpenTimeout", result.error

    stub_request(:get, "https://refused.test/").to_raise(Errno::ECONNREFUSED)
    assert_match "ECONNREFUSED", HttpProbe.call("https://refused.test/").error
  end
end
