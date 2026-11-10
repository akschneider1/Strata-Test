# frozen_string_literal: true

module TaxEngine
  # What Colorado's graduated income tax rates would mean for a household.
  #
  # Voters approved Amendment 87 in November 2026: from tax year 2027, income
  # is taxed in brackets in place of one flat rate. This asks the tax engine
  # for a 2027 return on the same facts twice, once at the flat rate and once
  # with the brackets, so the two can be shown side by side. The engine
  # projects the other 2027 amounts (such as deductions) forward.
  class RatePreview
    TAX_YEAR = 2027
    # The first graduated calculation after the engine starts can take a
    # while, as it builds that version of the rules.
    TIMEOUT = 45

    attr_reader :flat, :graduated

    def self.for(facts, client: TaxEngine.client(timeout: TIMEOUT))
      base = facts.to_h.merge("tax_year" => TAX_YEAR)
      results = Rails.cache.fetch("tax_engine/rate_preview/#{facts.digest}", expires_in: 1.day) do
        %w[flat graduated].index_with { |schedule| client.calculate(base.merge("rate_schedule" => schedule)) }
      end
      new(flat: TaxCalculation.new(results.fetch("flat")), graduated: TaxCalculation.new(results.fetch("graduated")))
    end

    def initialize(flat:, graduated:)
      @flat = flat
      @graduated = graduated
    end

    def taxable_income = graduated.amount("colorado_taxable_income")
    def flat_tax = flat.amount("tax")
    def graduated_tax = graduated.amount("tax")
    def flat_rate = flat.line("tax").facts["rate"]

    # [{ "from", "to", "rate", "income", "tax" }], from the engine.
    def brackets = graduated.line("tax").facts.fetch("brackets", [])

    # How the two results compare. Both amounts are the engine's.
    def difference = graduated_tax - flat_tax
  end
end
