# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit::Authorization

  around_action :switch_locale
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Set the active locale based on the URL
  # For example, if the URL starts with /es-US, the locale will be set to :es-US
  def switch_locale(&action)
    locale = params[:locale] || I18n.default_locale
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
