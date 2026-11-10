# frozen_string_literal: true

# Read-only view of a result from the tax engine.
class TaxCalculation
  Line = Struct.new(:id, :section, :amount, :facts, :source_title, :source_url, keyword_init: true)

  SECTIONS = %w[federal colorado_income tax credits payments result].freeze
  CREDIT_IDS = %w[earned_income_credit child_tax_credit family_affordability_credit child_care_credit tabor_sales_tax_refund care_worker_credit].freeze

  attr_reader :data

  def initialize(data)
    @data = data.deep_stringify_keys
  end

  def lines
    @lines ||= data.fetch("lines", []).map do |line|
      Line.new(
        id: line["id"], section: line["section"], amount: line["amount"].to_i,
        facts: line["facts"] || {}, source_title: line["source_title"], source_url: line["source_url"]
      )
    end
  end

  def line(id) = lines.find { |line| line.id == id.to_s }
  def amount(id) = line(id)&.amount || 0
  def section(name) = lines.select { |line| line.section == name.to_s }

  def credits = lines.select { |line| CREDIT_IDS.include?(line.id) }
  def credits_received = credits.select { |line| line.amount.positive? }

  def refund = data["refund"].to_i
  def amount_owed = data["amount_owed"].to_i
  def refund? = refund.positive?
  def owes? = amount_owed.positive?
  def filing_status = data["filing_status"]
  def engine = data["engine"]
  def engine_version = data["engine_version"]
end
