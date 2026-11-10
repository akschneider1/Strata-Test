# frozen_string_literal: true

# Works out a taxpayer's filing status from plain questions, instead of
# asking them to pick one (IRS Direct File's "tell, don't ask" approach).
#
# Simplified for the prototype; the full federal rules (IRS Publication 501)
# have more conditions, e.g. for people who lived apart from a spouse. Who
# counts as a dependent is decided by Dependent#qualifies?.
class FilingStatus
  STATUSES = %w[SINGLE JOINT SEPARATE HEAD_OF_HOUSEHOLD SURVIVING_SPOUSE].freeze

  attr_reader :code, :reason

  def initialize(code, reason)
    @code = code
    @reason = reason
  end

  def self.for(tax_return)
    supports_household = tax_return.qualifying_dependents.any? && tax_return.paid_over_half_home_costs

    if tax_return.married?
      tax_return.filing_jointly ? new("JOINT", :married_joint) : new("SEPARATE", :married_separate)
    elsif tax_return.widowed? && supports_household && tax_return.qualifying_dependents.any?(&:qualifying_child?)
      new("SURVIVING_SPOUSE", :surviving_spouse)
    elsif supports_household
      new("HEAD_OF_HOUSEHOLD", :head_of_household)
    elsif tax_return.qualifying_dependents.any?
      new("SINGLE", :single_did_not_pay_home_costs)
    else
      new("SINGLE", :single)
    end
  end

  def ==(other)
    other.is_a?(FilingStatus) && other.code == code
  end
end
