# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit::Authorization

  around_action :switch_locale
  before_action :keep_demo_space
  before_action :back_to_demo_start
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Set the active locale based on the URL
  # For example, if the URL starts with /es-US, the locale will be set to :es-US
  def switch_locale(&action)
    # An unknown locale in the URL falls back to the default instead of an error page.
    locale = I18n.available_locales.map(&:to_s).include?(params[:locale].to_s) ? params[:locale] : I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  # After a user signs in, Devise uses this method to determine where to route them
  def after_sign_in_path_for(resource)
    unless resource.is_a?(User)
      raise "Unexpected resource type"
    end

    if resource.mfa_preference.nil?
      return users_mfa_preference_path
    end

    resource.examiner? ? staff_path : tax_returns_path
  end

  private

  # A demo person belongs to one visitor's copy of the demo. Note that the
  # copy is in use. If it has been discarded, or belongs to another visitor,
  # go back to the start.
  def keep_demo_space
    return unless current_user&.demo_space_id
    return if DemoMode.space_for(cookies)&.id == current_user.demo_space_id

    sign_out(current_user)
    redirect_to root_path
  end

  # A demo visitor whose session has ended would land on the sign-in form,
  # which they can't use. Send them to the demo's start page instead.
  def back_to_demo_start
    return unless devise_controller? && controller_name == "sessions" && action_name == "new"
    return unless DemoMode.enabled? && cookies.signed[DemoMode::COOKIE].present?

    flash.discard
    redirect_to root_path
  end

  # Send people to the part of the site their role can use instead of
  # showing an error page.
  def user_not_authorized
    if current_user
      redirect_to after_sign_in_path_for(current_user), alert: t("flash.not_authorized")
    else
      redirect_to new_user_session_path
    end
  end
end
