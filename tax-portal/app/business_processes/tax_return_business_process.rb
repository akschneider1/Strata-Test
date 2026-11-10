# frozen_string_literal: true

# How a Colorado individual income tax return moves from the taxpayer to a
# final outcome.
#
#   file_return ──submitted──▶ calculate_return ──▶ screen_return ─┬─cleared──▶ finalize_return ──▶ end
#                                                                  └─flagged──▶ review_return ─┬─approved──────────▶ finalize_return
#                                                                                 ▲            └─information requested─▶ provide_information
#                                                                                 └────────────────information provided──────┘
#
# Returns with no flags are accepted without anyone touching them. Events
# are delivered synchronously, so an unflagged return is accepted within the
# taxpayer's submit request.
class TaxReturnBusinessProcess < Strata::BusinessProcess
  applicant_task("file_return")
  system_process("calculate_return", ->(kase) { ReturnProcessing::Calculate.call(kase) })
  system_process("screen_return", ->(kase) { ReturnProcessing::Screen.call(kase) })
  staff_task("review_return", ReviewTask)
  applicant_task("provide_information")
  system_process("finalize_return", ->(kase) { ReturnProcessing::Finalize.call(kase) })

  start_on_application_form_created("file_return")

  transition("file_return", "TaxReturnSubmitted", "calculate_return")
  transition("calculate_return", "TaxReturnCalculated", "screen_return")
  transition("screen_return", "TaxReturnCleared", "finalize_return")
  transition("screen_return", "TaxReturnFlagged", "review_return")
  transition("review_return", "TaxReturnApproved", "finalize_return")
  transition("review_return", "TaxReturnInformationRequested", "provide_information")
  transition("provide_information", "TaxReturnInformationProvided", "review_return")
  transition("finalize_return", "TaxReturnFinalized", "end")
end
