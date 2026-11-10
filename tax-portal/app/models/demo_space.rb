# frozen_string_literal: true

# One visitor's private copy of the demo: its own Maya, Daniela, Jordan,
# Priya and the rest, with their returns and records on file. Visitors can't
# see or change each other's copies, so the demo is fresh for everyone and
# several people can use it at once.
#
# A copy is thrown away when its visitor starts over, or after IDLE_LIMIT
# without use.
class DemoSpace < ApplicationRecord
  IDLE_LIMIT = 2.hours
  # Don't write "last used" more often than this.
  TOUCH_EVERY = 1.minute

  # Not `has_many`: removing people through an association would only
  # unlink them from the copy.
  def users = User.where(demo_space_id: id)

  scope :idle, -> { where(last_used_at: ...IDLE_LIMIT.ago) }

  # Creates a copy with all the demo people in their starting state. Needs
  # the tax engine, to file the returns that start out filed. All or nothing.
  def self.start!
    discard_idle
    transaction do
      space = create!(last_used_at: Time.current)
      DemoData.new(space).load!
      space
    end
  end

  def self.discard_idle
    idle.find_each(&:discard!)
  end

  # Removes every copy, for a clean start. Also removes demo people left
  # from before visitors had their own copies.
  def self.discard_all
    find_each(&:discard!)
    return if User.where(provider: "demo").none?

    transaction do
      remove(User.where(provider: "demo"))
      WageRecord.where(demo_space_id: nil).delete_all
    end
  end

  # Deletes these people and everything that hangs off their returns.
  def self.remove(people)
    returns = TaxReturn.where(user_id: people.select(:id))
    cases = TaxReturnCase.unscope(:includes).where(application_form_id: returns.select(:id))
    [ CaseNote, ReturnAdjustment, InformationRequest, ReviewFlag ].each { |model| model.where(tax_return_case_id: cases.select(:id)).delete_all }
    Strata::Task.where(case_id: cases.select(:id)).delete_all
    Strata::AuditLine.where(subject_id: cases.select(:id)).or(Strata::AuditLine.where(subject_id: returns.select(:id))).delete_all
    [ IncomeDocument, Dependent ].each { |model| model.where(tax_return_id: returns.select(:id)).delete_all }
    cases.delete_all
    returns.delete_all
    people.delete_all
  end

  def idle? = last_used_at < IDLE_LIMIT.ago

  def person(key)
    users.find_by!(uid: DemoData.uid(key, self))
  end

  def used!
    update_column(:last_used_at, Time.current) if last_used_at < TOUCH_EVERY.ago
  end

  # Removes the copy and everything in it.
  def discard!
    transaction do
      self.class.remove(users)
      WageRecord.where(demo_space_id: id).delete_all
      delete
    end
  end
end
