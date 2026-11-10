# frozen_string_literal: true

module TaxEngine
  # What the tax engine needs to know about a return, in its API's shape.
  class Facts
    # Amounts an examiner may adjust, as paths into the facts hash.
    ADJUSTABLE = {
      "filer_wages" => %w[filer wages],
      "filer_unemployment_compensation" => %w[filer unemployment_compensation],
      "filer_pension_income" => %w[filer pension_income],
      "filer_social_security" => %w[filer social_security],
      "taxable_interest" => %w[taxable_interest],
      "childcare_expenses" => %w[childcare_expenses],
      "colorado_tax_withheld" => %w[colorado_tax_withheld]
    }.freeze

    KIND_TO_FIELD = {
      "w2" => "wages",
      "form_1099g" => "unemployment_compensation",
      "form_1099r" => "pension_income",
      "ssa_1099" => "social_security"
    }.freeze

    def self.from_tax_return(tax_return)
      documents = tax_return.income_documents.included.to_a
      person = lambda do |owner, age|
        income = KIND_TO_FIELD.values.index_with { 0 }
        documents.select { |doc| doc.owner == owner }.each { |doc| income[KIND_TO_FIELD.fetch(doc.kind)] += doc.amount }
        { "age" => age }.merge(income)
      end

      new(
        "tax_year" => tax_return.tax_year,
        "filing_status" => tax_return.filing_status.code,
        "filer" => person.call("filer", tax_return.filer_age),
        "spouse" => (person.call("spouse", tax_return.spouse_age) if tax_return.joint?),
        "dependents" => tax_return.qualifying_dependents.sort_by(&:date_of_birth).map do |dependent|
          { "age" => dependent.age_at_year_end, "is_full_time_student" => dependent.full_time_student, "is_disabled" => dependent.disabled }
        end,
        "taxable_interest" => tax_return.has_interest_income ? tax_return.taxable_interest.to_i : 0,
        "childcare_expenses" => tax_return.ask_childcare? && tax_return.paid_childcare ? tax_return.childcare_expenses.to_i : 0,
        "colorado_tax_withheld" => documents.sum(&:colorado_withholding)
      )
    end

    def initialize(hash)
      @hash = hash.deep_stringify_keys
    end

    def to_h = @hash.deep_dup

    def digest
      Digest::SHA256.hexdigest(JSON.generate(@hash))
    end

    def value(field)
      @hash.dig(*ADJUSTABLE.fetch(field)).to_i
    end

    # Returns new facts with examiner adjustments applied ({ field => amount }).
    def with_adjustments(adjustments)
      hash = to_h
      adjustments.each do |field, amount|
        *parents, key = ADJUSTABLE.fetch(field)
        parents.reduce(hash) { |node, parent| node.fetch(parent) }[key] = amount
      end
      self.class.new(hash)
    end
  end
end
