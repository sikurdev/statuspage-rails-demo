require "net/http"

# Performs a single HTTP GET and reports whether the response matched the
# monitor's expected status. Network errors and timeouts count as failures.
class HttpProbe
  Result = Data.define(:success, :http_status, :response_time_ms, :error) do
    alias_method :success?, :success
  end

  TIMEOUT = 10.seconds
  USER_AGENT = "StatuspageRailsDemo/1.0 (+uptime check)".freeze

  def self.call(...) = new(...).call

  def initialize(url, expected_status: 200, timeout: TIMEOUT)
    @uri = URI.parse(url)
    @expected_status = expected_status
    @timeout = timeout
  end

  def call
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    response = request
    elapsed = elapsed_ms(started)
    status = response.code.to_i

    if status == @expected_status
      Result.new(success: true, http_status: status, response_time_ms: elapsed, error: nil)
    else
      Result.new(success: false, http_status: status, response_time_ms: elapsed,
        error: "Expected HTTP #{@expected_status}, got #{status}")
    end
  rescue Timeout::Error, SystemCallError, SocketError, OpenSSL::SSL::SSLError, IOError, URI::Error, Net::HTTPBadResponse => e
    Result.new(success: false, http_status: nil, response_time_ms: started && elapsed_ms(started),
      error: "#{e.class.name}: #{e.message}".truncate(250))
  end

  private
    def request
      Net::HTTP.start(@uri.host, @uri.port, use_ssl: @uri.scheme == "https",
        open_timeout: @timeout, read_timeout: @timeout, write_timeout: @timeout) do |http|
        http.request(Net::HTTP::Get.new(@uri, "User-Agent" => USER_AGENT))
      end
    end

    def elapsed_ms(started)
      ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round
    end
end
