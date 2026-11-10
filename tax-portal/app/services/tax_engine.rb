# frozen_string_literal: true

# Access to the tax engine: the service that applies Colorado tax law to a
# return. The portal never does tax math itself.
#
# TAX_ENGINE_ADAPTER selects the implementation:
#   "http" - the tax-engine app (PolicyEngine US), the default
#   "fake" - simplified in-process math, for tests and offline work only
module TaxEngine
  class Error < StandardError; end
  class Unavailable < Error; end
  class Rejected < Error; end

  PARAMETERS_TTL = 1.hour

  # The most income a person can have and still be claimed as a qualifying
  # relative. A tax figure, so it comes from the engine, not the portal.
  def self.qualifying_relative_income_limit(tax_year)
    limits = Rails.cache.fetch("tax_engine/qualifying_relative_income_limits", expires_in: PARAMETERS_TTL) do
      client.status&.fetch("qualifying_relative_income_limits", nil)
    end
    limits&.fetch(tax_year.to_s, nil) || raise(Unavailable, "Tax engine did not provide the income limit for #{tax_year}")
  end

  # How long a page a taxpayer or examiner is waiting on may wait for the
  # engine, in seconds. Background processing passes a longer timeout.
  INTERACTIVE_TIMEOUT = 10

  def self.client(timeout: INTERACTIVE_TIMEOUT)
    case ENV.fetch("TAX_ENGINE_ADAPTER", "http")
    when "fake" then FakeClient.new
    else HttpClient.new(timeout: timeout)
    end
  end
end
