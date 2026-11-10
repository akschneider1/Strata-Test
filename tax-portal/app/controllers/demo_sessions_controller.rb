# frozen_string_literal: true

# One-click sign-in as a seeded demo person. Only routed in demo mode.
class DemoSessionsController < ApplicationController
  skip_after_action :verify_authorized

  def create
    raise ActionController::RoutingError, "Not Found" unless DemoMode.enabled?

    user = DemoMode.scope.find(params[:user_id])
    sign_out(current_user) if current_user
    sign_in(user)
    redirect_to after_sign_in_path_for(user)
  end

  def destroy
    sign_out(current_user) if current_user
    redirect_to root_path
  end
end
