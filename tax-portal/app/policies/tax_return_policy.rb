# frozen_string_literal: true

# A taxpayer can only see and change their own return. Examiners reach
# returns through the staff area (StaffPolicy), never through these routes.
class TaxReturnPolicy < ApplicationPolicy
  def index? = user.taxpayer?
  def create? = user.taxpayer?
  def show? = owner?
  def update? = owner? && record.in_progress?
  def summary? = show?
  def review? = update?
  def submit? = update?
  def respond? = owner? && record.submitted?

  class Scope < ApplicationPolicy::Scope
    def resolve
      user.taxpayer? ? scope.for_user(user) : scope.none
    end
  end

  private

  def owner?
    user.taxpayer? && record.user_id == user.id
  end
end
