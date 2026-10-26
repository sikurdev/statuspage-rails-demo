ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"

WebMock.disable_net_connect!(allow_localhost: false)

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    fixtures :all

    # Builds an HttpProbe::Result without going over the network.
    def probe_result(success:, http_status: success ? 200 : 503, response_time_ms: 42, error: nil)
      error ||= "Expected HTTP 200, got #{http_status}" unless success
      HttpProbe::Result.new(success:, http_status:, response_time_ms:, error:)
    end

    def record_checks(monitor, *outcomes)
      outcomes.each_with_index.map do |success, i|
        monitor.record_check!(probe_result(success: success), checked_at: Time.current + i.minutes)
      end
    end
  end
end

module AdminAuthHelper
  ADMIN_PASSWORD = "test-password".freeze

  def with_admin_password(password = ADMIN_PASSWORD)
    original = ENV["ADMIN_PASSWORD"]
    ENV["ADMIN_PASSWORD"] = password
    yield
  ensure
    ENV["ADMIN_PASSWORD"] = original
  end

  def admin_headers(password = ADMIN_PASSWORD)
    { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("admin", password) }
  end
end
