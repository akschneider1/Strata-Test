# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Home page" do
  include Devise::Test::IntegrationHelpers

  context "when it is a demo" do
    before { allow(DemoMode).to receive(:enabled?).and_return(true) }

    it "lists the demo people in the order of the demo story, before anything is in the database" do
      get root_path

      body = response.body
      expect(User.count).to eq(0)
      expect(body).to include("Try the demo", "How the demo works", "You don&#39;t need a password", "Start here to file a return from beginning to end.", "You get your own copy")
      order = %w[Maya Daniela Walter Elena Jordan Priya Marcus].map { |name| body.index("Continue as #{name}") }
      expect(order).to eq(order.compact.sort)
      # The demo comes before the description of the service.
      expect(body.index("Try the demo")).to be < body.index("How this is different")
    end

    it "does not offer the sign-in form, which would create an empty account" do
      get root_path

      expect(response.body).not_to include(new_user_session_path)
    end

    it "says the demo is getting ready, and checks again, while the tax engine loads" do
      allow(DemoMode).to receive(:ready?).and_return(false)

      get root_path

      expect(response.body).to include("The demo is getting ready", 'http-equiv="refresh"', "Maya Torres")
      expect(response.body).not_to include("Continue as")
    end

    it "says so when a person is chosen before the tax engine is ready" do
      allow(DemoData).to receive(:new).and_raise(TaxEngine::Unavailable)

      post demo_sign_in_path(person: "maya")
      follow_redirect!

      expect(response.body).to include("The demo isn&#39;t ready yet")
      expect(DemoSpace.count).to eq(0)
    end

    it "does not sign in as someone who isn't a demo person" do
      post demo_sign_in_path(person: "nobody")

      expect(response).to have_http_status(:not_found)
    end

    it "offers to start over only once the visitor has a copy" do
      get root_path
      expect(response.body).not_to include("Reset the demo")

      post demo_sign_in_path(person: "maya")
      delete demo_sign_out_path
      get root_path
      expect(response.body).to include("Start the demo over", "Reset the demo")
    end

    it "shows someone who owes tax" do
      post demo_sign_in_path(person: "elena")

      elena = DemoSpace.sole.person(:elena).tax_returns.sole
      expect(elena.tax_return_case).to have_attributes(outcome: "accepted", step: "end")
      expect(elena.tax_return_case.current_calculation.owes?).to be(true)

      get tax_return_path(elena)
      expect(response.body).to include("You owe", "can&#39;t take payments yet")
    end

    it "keeps Spanish when a visitor chooses a person, and when they switch" do
      get "/es-us"
      expect(response.body).to include("/demo/sign_in?locale=es-US")

      post demo_sign_in_path(person: "maya", locale: "es-US")
      expect(response.location).to include("/es-us/")

      delete demo_sign_out_path(locale: "es-US")
      expect(response.location).to end_with("/es-us")
    end

    it "falls back to English for a language it doesn't have" do
      get "/about", params: { locale: "zz" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('lang="en"')
    end

    it "is available in Spanish" do
      get "/es-us"

      expect(response.body).to include("Cómo funciona la demostración", "No necesita contraseña", "Aún no ha presentado su declaración", "Acerca de este prototipo")
    end
  end

  context "when it is not a demo" do
    before { allow(DemoMode).to receive(:enabled?).and_return(false) }

    it "has no demo sign-in and no way to reset anything" do
      post demo_sign_in_path(person: "maya")
      expect(response).to have_http_status(:not_found)

      post demo_reset_path
      expect(response).to have_http_status(:not_found)
      expect(DemoSpace.count).to eq(0)
    end

    it "offers sign-in and no demo people" do
      get root_path

      expect(response.body).to include("Sign in", "How this is different")
      expect(response.body).not_to include("Try the demo", "The demo is getting ready")
    end
  end

  describe "About this prototype" do
    it "says what is real and what is made up, in English and Spanish" do
      get about_path
      expect(response.body).to include("About this prototype", "What is real", "What is made up or left out", "Nobody here is real", "Who it doesn&#39;t cover yet")

      get "/es-us/about"
      expect(response.body).to include("Acerca de este prototipo", "Lo que es real", "Nadie aquí es real")
    end
  end
end
