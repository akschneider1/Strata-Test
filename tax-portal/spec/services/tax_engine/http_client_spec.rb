# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaxEngine::HttpClient do
  it "accepts an engine address given as a bare host and port" do
    stub = Faraday::Adapter::Test::Stubs.new { |stubs| stubs.get("/v1/engine") { [ 200, { "Content-Type" => "application/json" }, '{"data":{"ready":true}}' ] } }
    client = described_class.new(url: "tax-engine:3200", token: "t")
    connection = client.instance_variable_get(:@connection)
    connection.adapter(:test, stub)

    expect(connection.url_prefix.to_s).to eq("http://tax-engine:3200/")
    expect(client.status).to eq("ready" => true)
  end

  describe ".setting" do
    around do |example|
      saved = ENV.to_h.slice("TAX_ENGINE_URL")
      ENV.delete("TAX_ENGINE_URL")
      example.run
    ensure
      ENV.update(saved)
    end

    it "falls back to the local engine in development and test" do
      expect(described_class.setting("TAX_ENGINE_URL", described_class::LOCAL_URL)).to eq("http://127.0.0.1:3200")
    end

    it "refuses to guess where the engine is, or its token, once deployed" do
      allow(Rails.env).to receive(:local?).and_return(false)

      expect { described_class.setting("TAX_ENGINE_URL", described_class::LOCAL_URL) }.to raise_error(KeyError)
    end
  end
end
