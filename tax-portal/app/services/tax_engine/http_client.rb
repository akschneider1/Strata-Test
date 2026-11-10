# frozen_string_literal: true

module TaxEngine
  # Calls the tax-engine app. Facts and results are never logged.
  class HttpClient
    # Local development falls back to the engine started by bin/demo. A
    # deployed portal must be told where the engine is and given its token.
    LOCAL_URL = "http://127.0.0.1:3200"
    LOCAL_TOKEN = "LOCAL_AUTH_12345678"

    def self.setting(name, local_default)
      Rails.env.local? ? ENV.fetch(name, local_default) : ENV.fetch(name)
    end

    def initialize(url: self.class.setting("TAX_ENGINE_URL", LOCAL_URL), token: self.class.setting("TAX_ENGINE_API_TOKEN", LOCAL_TOKEN))
      @connection = Faraday.new(url: url, headers: { "X-Auth" => token }) do |faraday|
        faraday.request :json
        faraday.response :json
        # The first calculation after the engine starts can take ~30 seconds
        # while it loads the tax rules.
        faraday.options.timeout = 90
        faraday.options.open_timeout = 5
      end
    end

    def calculate(facts)
      response = @connection.post("/v1/returns/calculate", facts)
      case response.status
      when 200 then response.body.fetch("data")
      when 422 then raise Rejected, response.body.is_a?(Hash) ? response.body["message"].to_s : "The return could not be calculated"
      else raise Unavailable, "Tax engine returned HTTP #{response.status}"
      end
    rescue Faraday::Error => error
      raise Unavailable, "Tax engine is not reachable (#{error.class.name})"
    end

    def status
      response = @connection.get("/v1/engine")
      response.status == 200 ? response.body.fetch("data") : nil
    rescue Faraday::Error
      nil
    end
  end
end
