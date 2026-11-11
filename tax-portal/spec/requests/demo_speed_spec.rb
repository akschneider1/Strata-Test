# frozen_string_literal: true

require 'rails_helper'

# What keeps a hosted demo fast, and how to see when it isn't.
RSpec.describe "Demo speed" do
  describe DemoWarmup do
    it "runs every demo household through the tax engine and leaves nothing behind" do
      result = described_class.run(pause: 0)

      expect(result.households).to eq(5)
      [ DemoSpace, User, TaxReturn, TaxReturnCase, Strata::Task, WageRecord, IncomeDocument, Dependent ].each do |model|
        expect(model.unscoped.count).to eq(0), "#{model} rows were left behind"
      end
    end

    it "gives up when the tax engine never becomes ready" do
      allow(DemoMode).to receive(:ready?).and_return(false)

      expect { described_class.run(wait: 0.seconds, pause: 0) }.to raise_error(TaxEngine::Unavailable)
      expect(DemoSpace.count).to eq(0)
    end
  end

  describe "the diagnostics page", type: :request do
    it "shows timings and no personal data" do
      allow(DemoMode).to receive(:enabled?).and_return(true)
      post demo_sign_in_path(person: "maya")
      delete demo_sign_out_path

      get demo_diagnostics_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("How fast is this demo?", "One trip to the database", "One new tax calculation", "On this machine", "milliseconds")
      expect(response.body).not_to include("Maya", "000001001", "@demo.example")
    end

    it "is in Spanish too" do
      allow(DemoMode).to receive(:enabled?).and_return(true)

      get demo_diagnostics_path(locale: "es-US")

      expect(response.body).to include("¿Qué tan rápida es esta demostración?")
    end

    it "does not exist outside a demo" do
      allow(DemoMode).to receive(:enabled?).and_return(false)

      get demo_diagnostics_path

      expect(response).to have_http_status(:not_found)
    end
  end
end
