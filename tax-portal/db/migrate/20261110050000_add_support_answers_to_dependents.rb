# frozen_string_literal: true

# Answers to the two extra questions asked about a dependent who is not a
# qualifying child (see Dependent#qualifying_relative?).
class AddSupportAnswersToDependents < ActiveRecord::Migration[8.0]
  def change
    add_column :dependents, :income_under_limit, :boolean
    add_column :dependents, :supported_by_filer, :boolean
  end
end
