# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Home page" do
  include Devise::Test::IntegrationHelpers

  def demo_user(key, name, role)
    User.create!(uid: "demo-#{key}", provider: "demo", email: "#{key}@demo.example", full_name: name, role: role, mfa_preference: :opt_out)
  end

  context "when it is a demo" do
    before { allow(DemoMode).to receive(:enabled?).and_return(true) }

    it "lists the demo people in the order of the demo story, with plain descriptions" do
      demo_user(:examiner2, "Marcus Reed", :examiner)
      demo_user(:jordan, "Jordan Lee", :taxpayer)
      demo_user(:examiner, "Priya Shah", :examiner)
      demo_user(:maya, "Maya Torres", :taxpayer)

      get root_path

      body = response.body
      expect(body).to include("Try the demo", "How the demo works", "You don&#39;t need a password", "Start here to file a return from beginning to end.")
      expect(body.index("Continue as Maya")).to be < body.index("Continue as Jordan")
      expect(body.index("Continue as Jordan")).to be < body.index("Continue as Priya")
      expect(body.index("Continue as Priya")).to be < body.index("Continue as Marcus")
      # The demo comes before the description of the service.
      expect(body.index("Try the demo")).to be < body.index("How this is different")
    end

    it "does not offer the sign-in form, which would create an empty account" do
      demo_user(:maya, "Maya Torres", :taxpayer)

      get root_path

      expect(response.body).not_to include(new_user_session_path)
    end

    it "says the demo is getting ready, and checks again, while there are no demo people yet" do
      get root_path

      expect(response.body).to include("The demo is getting ready", 'http-equiv="refresh"')
      expect(response.body).not_to include("Continue as")
    end

    it "signs in as the chosen demo person" do
      maya = demo_user(:maya, "Maya Torres", :taxpayer)

      post demo_sign_in_path(user_id: maya.id)

      expect(response).to redirect_to(tax_returns_path)
    end

    it "can be started over, since a shared demo gets used up" do
      demo_user(:maya, "Maya Torres", :taxpayer)
      allow(DemoData).to receive(:load!)

      get root_path
      expect(response.body).to include("Start the demo over", "Reset the demo")

      post demo_reset_path
      expect(DemoData).to have_received(:load!)
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("The demo is back to the start.")
    end

    it "says so when it can't be started over" do
      allow(DemoData).to receive(:load!).and_raise(TaxEngine::Unavailable)

      post demo_reset_path
      follow_redirect!

      expect(response.body).to include("couldn&#39;t be reset just now")
    end

    it "loads the demo people, including one who owes tax" do
      DemoData.load!

      names = DemoMode.users.map(&:full_name)
      expect(names).to eq([ "Maya Torres", "Daniela Ruiz", "Walter Bennett", "Elena Park", "Jordan Lee", "Priya Shah", "Marcus Reed" ])

      elena = User.find_by!(uid: "demo-elena").tax_returns.sole
      expect(elena.tax_return_case).to have_attributes(outcome: "accepted", step: "end")
      expect(elena.tax_return_case.current_calculation.owes?).to be(true)

      sign_in elena.user
      get tax_return_path(elena)
      expect(response.body).to include("You owe", "can&#39;t take payments yet")
    end

    it "is available in Spanish" do
      demo_user(:maya, "Maya Torres", :taxpayer)

      get "/es-us"

      expect(response.body).to include("Cómo funciona la demostración", "No necesita contraseña", "Aún no ha presentado su declaración")
    end
  end

  context "when it is not a demo" do
    before { allow(DemoMode).to receive(:enabled?).and_return(false) }

    it "has no way to reset anything" do
      allow(DemoData).to receive(:load!)

      post demo_reset_path

      expect(response).to have_http_status(:not_found)
      expect(DemoData).not_to have_received(:load!)
    end

    it "offers sign-in and no demo people" do
      get root_path

      expect(response.body).to include("Sign in", "How this is different")
      expect(response.body).not_to include("Try the demo", "The demo is getting ready")
    end
  end
end
