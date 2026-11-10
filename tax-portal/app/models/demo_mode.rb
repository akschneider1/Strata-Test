# frozen_string_literal: true

# Demo-only conveniences (one-click sign-in as a seeded person). Off unless
# DEMO_MODE=true, and never available in production.
module DemoMode
  def self.enabled?
    !Rails.env.production? && ENV["DEMO_MODE"] == "true"
  end

  # The order the demo guide tells the story in.
  STORY_ORDER = %w[demo-maya demo-daniela demo-walter demo-elena demo-jordan demo-examiner demo-examiner2].freeze

  def self.scope
    User.where(provider: "demo")
  end

  # Demo people in story order, for the home page.
  def self.users
    scope.sort_by { |user| [ STORY_ORDER.index(user.uid) || STORY_ORDER.size, user.full_name ] }
  end
end
