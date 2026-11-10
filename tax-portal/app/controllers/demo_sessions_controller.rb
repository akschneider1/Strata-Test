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

  # Put every demo person back to where they started. A shared demo gets
  # used up: once someone files as Maya, the next visitor can't.
  def reset
    raise ActionController::RoutingError, "Not Found" unless DemoMode.enabled?

    sign_out(current_user) if current_user
    DemoData.load!
    redirect_to root_path, notice: t("home.index.demo_reset_done")
  rescue TaxEngine::Error, RuntimeError => error
    Rails.logger.warn("Demo reset failed: #{error.class.name}")
    redirect_to root_path, alert: t("home.index.demo_reset_failed")
  end

  def destroy
    sign_out(current_user) if current_user
    redirect_to root_path
  end
end
