# frozen_string_literal: true

# Access to the examiner (staff) area.
class StaffPolicy < ApplicationPolicy
  def access? = user.examiner?
end
