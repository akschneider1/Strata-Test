# frozen_string_literal: true

# One-click sign-in as a demo person, in the visitor's own copy of the demo.
# Only available in demo mode.
class DemoSessionsController < ApplicationController
  skip_after_action :verify_authorized
  before_action :require_demo_mode, except: :destroy

  # Sign in as the chosen person. The visitor's first choice creates their
  # copy of the demo.
  def create
    person = DemoMode.roster.find { |candidate| candidate.key == params[:person] }
    raise ActionController::RoutingError, "Not Found" unless person

    space = DemoMode.space_for(cookies) || start_space
    user = space.person(person.key)
    sign_out(current_user) if current_user
    sign_in(user)
    redirect_to after_sign_in_path_for(user)
  rescue TaxEngine::Error, RuntimeError => error
    Rails.logger.warn("Demo could not be started: #{error.class.name}")
    redirect_to root_path, alert: t("home.index.demo_not_ready")
  end

  # Throw away the visitor's copy. Their next choice starts a fresh one.
  # Nobody else's copy is touched.
  def reset
    space = DemoMode.space_for(cookies)
    sign_out(current_user) if current_user
    space&.discard!
    cookies.delete(DemoMode::COOKIE)
    redirect_to root_path, notice: t("home.index.demo_reset_done")
  end

  def destroy
    sign_out(current_user) if current_user
    redirect_to root_path
  end

  private

  def require_demo_mode
    raise ActionController::RoutingError, "Not Found" unless DemoMode.enabled?
  end

  def start_space
    DemoSpace.start!.tap do |space|
      cookies.signed[DemoMode::COOKIE] = { value: space.id, httponly: true, same_site: :lax, expires: 1.day }
    end
  end
end
