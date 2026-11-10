# frozen_string_literal: true

# A second examiner confirms, or sends back, what the first examiner
# proposed: a large adjustment, or not accepting the return.
class SecondReviewTask < Strata::Task
  DAYS_TO_CONFIRM = 3

  before_validation(on: :create) { self.due_on ||= DAYS_TO_CONFIRM.days.from_now.to_date }
end
