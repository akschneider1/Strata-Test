# frozen_string_literal: true

# Demo-only conveniences (one-click sign-in as a seeded person). Off unless
# DEMO_MODE=true, and never available in production.
module DemoMode
  def self.enabled?
    !Rails.env.production? && ENV["DEMO_MODE"] == "true"
  end

  def self.users
    User.where(provider: "demo").order(:role, :full_name)
  end
end
