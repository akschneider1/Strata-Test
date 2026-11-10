# frozen_string_literal: true

module TaxEngine
  # Stand-in for the tax engine in tests and offline development.
  #
  # NOT tax law: a flat standard deduction, the 4.4% rate and one made-up
  # child credit, just enough to exercise the portal's screens and workflow
  # with predictable numbers.
  class FakeClient
    STANDARD_DEDUCTION = { "SINGLE" => 15_750, "SEPARATE" => 15_750, "HEAD_OF_HOUSEHOLD" => 23_625, "JOINT" => 31_500, "SURVIVING_SPOUSE" => 31_500 }.freeze
    RATE = 0.044
    CREDIT_PER_CHILD = 1_000
    GRADUATED_FROM = 2027
    BRACKETS = [ [ 0, 0.037 ], [ 25_000, 0.042 ], [ 100_000, 0.044 ], [ 500_000, 0.074 ], [ 750_000, 0.079 ], [ 1_000_000, 0.084 ] ].freeze

    def calculate(facts)
      facts = facts.deep_stringify_keys
      people = [ facts["filer"], facts["spouse"] ].compact
      income = people.sum { |person| person.values_at("wages", "unemployment_compensation", "pension_income", "social_security").sum(&:to_i) } + facts["taxable_interest"].to_i
      deduction = STANDARD_DEDUCTION.fetch(facts["filing_status"])
      taxable = [ income - deduction, 0 ].max
      graduated = facts["tax_year"].to_i >= GRADUATED_FROM && facts["rate_schedule"] != "flat"
      brackets = graduated ? by_bracket(taxable) : nil
      tax = graduated ? brackets.sum { |bracket| bracket["tax"] } : (taxable * RATE).round
      tax_facts = graduated ? { "rate_schedule" => "graduated", "brackets" => brackets } : { "rate" => RATE, "rate_schedule" => "flat" }
      children = facts["dependents"].count { |dependent| dependent["age"] < 17 }
      credits = children * CREDIT_PER_CHILD
      withheld = facts["colorado_tax_withheld"].to_i
      balance = tax - credits - withheld

      lines = [
        line("total_income", "federal", income),
        line("federal_agi", "federal", income),
        line("federal_deductions", "federal", deduction, "standard_deduction" => deduction),
        line("federal_taxable_income", "federal", taxable),
        line("additions", "colorado_income", 0),
        line("subtractions", "colorado_income", 0),
        line("colorado_taxable_income", "colorado_income", taxable),
        line("tax", "tax", tax, tax_facts),
        line("net_tax", "tax", tax),
        line("child_tax_credit", "credits", credits, "qualifying_children" => children),
        line("refundable_credits", "credits", credits),
        line("colorado_tax_withheld", "payments", withheld),
        line("refund", "result", [ -balance, 0 ].max),
        line("amount_owed", "result", [ balance, 0 ].max)
      ]

      {
        "tax_year" => facts["tax_year"], "filing_status" => facts["filing_status"], "lines" => lines,
        "refund" => [ -balance, 0 ].max, "amount_owed" => [ balance, 0 ].max,
        "engine" => "fake", "engine_version" => "0", "rate_schedule" => graduated ? "graduated" : "flat"
      }
    end

    def status
      { "engine" => "fake", "engine_version" => "0", "ready" => true, "qualifying_relative_income_limits" => { "2025" => 5_200 } }
    end

    private

    def by_bracket(taxable)
      BRACKETS.each_with_index.map do |(from, rate), index|
        to = BRACKETS[index + 1]&.first
        income = [ [ taxable, to || taxable ].min - from, 0 ].max
        { "from" => from, "to" => to, "rate" => rate, "income" => income, "tax" => (income * rate).round }
      end
    end

    def line(id, section, amount, facts = {})
      { "id" => id, "section" => section, "amount" => amount, "facts" => facts, "source_title" => nil, "source_url" => nil }
    end
  end
end
