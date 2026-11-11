# frozen_string_literal: true

# Shows where a hosted demo spends its time. Demo mode only.
class DemoDiagnosticsController < ApplicationController
  skip_after_action :verify_authorized

  def show
    raise ActionController::RoutingError, "Not Found" unless DemoMode.enabled?

    @diagnostics = DemoDiagnostics.new
  end
end
