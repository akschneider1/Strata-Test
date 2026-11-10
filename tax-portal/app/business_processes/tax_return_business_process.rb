# frozen_string_literal: true

# How a Colorado individual income tax return moves from the taxpayer to a
# final outcome.
#
#   file_return ──submitted──▶ calculate_return ──▶ screen_return ─┬─cleared──▶ finalize_return ──▶ end
#                                                                  └─flagged──▶ review_return ─┬─approved──────────▶ finalize_return
#                                                                                 ▲            └─information requested─▶ provide_information
#                                                                                 └────────────────information provided──────┘
#
# A large adjustment, or a decision not to accept the return, takes two
# examiners: review_return ──second review requested──▶ second_review, where
# a different examiner confirms (──▶ finalize_return) or sends it back
# (──▶ review_return).
#
# Returns with no flags are accepted without anyone touching them. Filing
# only queues the calculation (ProcessReturnJob); the checks and acceptance
# follow in that job, usually within a second or two of filing.
class TaxReturnBusinessProcess < Strata::BusinessProcess
  applicant_task("file_return")
  system_process("calculate_return", ->(kase) { ProcessReturnJob.perform_later(kase.id) })
  system_process("screen_return", ->(kase) { ReturnProcessing::Screen.call(kase) })
  staff_task("review_return", ReviewTask)
  staff_task("second_review", SecondReviewTask)
  applicant_task("provide_information")
  system_process("finalize_return", ->(kase) { ReturnProcessing::Finalize.call(kase) })

  start_on_application_form_created("file_return")

  transition("file_return", "TaxReturnSubmitted", "calculate_return")
  transition("calculate_return", "TaxReturnCalculated", "screen_return")
  transition("screen_return", "TaxReturnCleared", "finalize_return")
  transition("screen_return", "TaxReturnFlagged", "review_return")
  transition("review_return", "TaxReturnApproved", "finalize_return")
  transition("review_return", "TaxReturnInformationRequested", "provide_information")
  transition("review_return", "TaxReturnSecondReviewRequested", "second_review")
  transition("second_review", "TaxReturnApproved", "finalize_return")
  transition("second_review", "TaxReturnSentBack", "review_return")
  transition("provide_information", "TaxReturnInformationProvided", "review_return")
  transition("finalize_return", "TaxReturnFinalized", "end")
end
