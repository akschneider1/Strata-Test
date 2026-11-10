# frozen_string_literal: true

class HomeController < ApplicationController
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def index
    if current_user
      redirect_to after_sign_in_path_for(current_user)
    else
      @demo_mode = DemoMode.enabled?
      @demo_users = @demo_mode ? DemoMode.users : []
    end
  end
end
