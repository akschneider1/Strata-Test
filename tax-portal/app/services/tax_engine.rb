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

  def self.client
    case ENV.fetch("TAX_ENGINE_ADAPTER", "http")
    when "fake" then FakeClient.new
    else HttpClient.new
    end
  end
end
