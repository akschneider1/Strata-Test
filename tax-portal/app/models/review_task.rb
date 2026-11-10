# frozen_string_literal: true

# Work item for an examiner: review a return that the automatic checks flagged.
class ReviewTask < Strata::Task
  DAYS_TO_REVIEW = 7

  before_validation(on: :create) { self.due_on ||= DAYS_TO_REVIEW.days.from_now.to_date }
end
