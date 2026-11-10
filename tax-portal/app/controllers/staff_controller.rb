# frozen_string_literal: true

# Base controller for staff-facing pages, required by the Strata SDK's engine
# controllers (e.g. Strata::TasksController). It is not routed by default.
#
# To scaffold the Strata staff dashboard (routes, tasks UI, specs), run:
#   bin/rails generate strata:staff
# and keep authentication and Pundit authorization in place here.
class StaffController < Strata::StaffController
  before_action :authenticate_user!

  protected

  # Case models to link in the staff header, e.g. [ BenefitsCase ].
  def case_classes
    []
  end
end
