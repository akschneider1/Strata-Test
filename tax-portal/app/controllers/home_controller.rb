# frozen_string_literal: true

class HomeController < ApplicationController
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  # What the prototype is, and what in it is real or made up. For someone
  # who opens the demo with nobody there to explain it.
  def about
  end

  def index
    if current_user
      redirect_to after_sign_in_path_for(current_user)
    else
      @demo_mode = DemoMode.enabled?
      return unless @demo_mode

      @people = DemoMode.roster
      @demo_ready = DemoMode.ready?
      @has_space = DemoMode.space_for(cookies).present?
    end
  end
end
