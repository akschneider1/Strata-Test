# frozen_string_literal: true

# Estimates how many returns the automatic checks would send to an examiner.
#
# Files a made-up population through the real pipeline (tax engine,
# ReturnProcessing::Screen) inside a transaction that is rolled back, and
# counts the flags. The population comes from config/review_rate_study.yml:
# every figure there is an assumption, so the result shows how the rules
# behave, not what the Department will see. See
# docs/tax-portal/review-rate-study.md.
class ReviewRateStudy
  CONFIG_PATH = Rails.root.join("config/review_rate_study.yml")
  SINGLE_STANDARD_DEDUCTION_FOR_WITHHOLDING = 15_000
  WITHHOLDING_RATE = 0.044

  Result = Struct.new(:returns, :flagged, :by_code, :only_code, :by_household, :flagged_by_household, :seconds, keyword_init: true) do
    def share(count) = returns.zero? ? 0.0 : (count * 100.0 / returns).round(1)
    def flagged_share = share(flagged)
  end

  def initialize(returns: 500, seed: 2025, config: YAML.load_file(CONFIG_PATH))
    @count = returns
    @random = Random.new(seed)
    @config = config
    @claimed_children = []
  end

  def run
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result = nil
    ActiveRecord::Base.transaction do
      cases = Array.new(@count) { |index| file_return(index) }
      result = summarize(cases)
      raise ActiveRecord::Rollback
    end
    result.seconds = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).round
    result
  end

  private

  def summarize(cases)
    codes = cases.map { |household, kase| [ household, kase.review_flags.map(&:code).uniq ] }
    flagged = codes.reject { |_, flags| flags.empty? }
    Result.new(
      returns: cases.size,
      flagged: flagged.size,
      by_code: flagged.flat_map(&:last).tally.sort_by { |code, count| [ -count, code ] }.to_h,
      only_code: flagged.select { |_, flags| flags.size == 1 }.map { |_, flags| flags.first }.tally,
      by_household: codes.map(&:first).tally,
      flagged_by_household: flagged.map(&:first).tally
    )
  end

  def file_return(index)
    household = pick_household
    retired = household.start_with?("retired")
    joint = household.include?("couple")
    children = household.include?("children") || household == "single_parent" ? @random.rand(1..3) : 0

    filer_ssn = ssn(index, 1)
    user = User.create!(uid: "study-#{index}", provider: "study", email: "study#{index}@demo.example", full_name: "Study Person #{index}", role: :taxpayer, mfa_preference: :opt_out)
    tax_return = TaxReturn.create!(
      user: user, filer_name_first: "Study", filer_name_last: "Person#{index}", filer_date_of_birth: birth_date(retired), filer_ssn: filer_ssn,
      full_year_resident: true, marital_status: joint ? "married" : "unmarried", filing_jointly: (true if joint),
      has_dependents: children.positive?, **DemoData::ADDRESS,
      **(joint ? { spouse_name_first: "Spouse", spouse_name_last: "Person#{index}", spouse_date_of_birth: birth_date(retired), spouse_ssn: ssn(index, 2) } : {})
    )
    add_children(tax_return, index, children)
    add_records(filer_ssn, retired, earner: true)
    add_records(ssn(index, 2), retired, earner: @random.rand < @config["second_earner_share"]) if joint

    documents = RecordsOnFile.prefill(tax_return)
    documents.each(&:confirm!)
    misreport(tax_return, documents)
    tax_return.update!(
      paid_over_half_home_costs: (true if children.positive? && !joint), paid_childcare: (false if tax_return.ask_childcare?),
      income_documents_reviewed: true, has_interest_income: false, has_other_income: false, refund_method: "check"
    )
    DemoData.new.submit(tax_return)
    [ household, tax_return.tax_return_case.reload ]
  end

  def pick_household
    roll = @random.rand
    @config["households"].each do |name, share|
      return name if (roll -= share) <= 0
    end
    @config["households"].keys.last
  end

  def add_children(tax_return, index, count)
    count.times do |child|
      child_ssn = ssn(index, 3 + child)
      # Sometimes a child has already been claimed on an earlier return.
      if @claimed_children.any? && @random.rand < @config.dig("behavior", "dependent_on_another_return")
        child_ssn = @claimed_children.sample(random: @random)
      end
      tax_return.dependents.create!(
        name_first: "Child#{child}", name_last: "Person#{index}", date_of_birth: Date.new(@random.rand(2008..2024), @random.rand(1..12), 1),
        relationship: "child", ssn: child_ssn, lived_with_filer_over_half_year: true
      )
      @claimed_children << child_ssn
    end
  end

  def add_records(person_ssn, retired, earner:)
    if retired
      WageRecord.create!(ssn: person_ssn, kind: "form_1099r", payer_name: "Pension Plan", amount: between("pension"), colorado_withholding: 0, tax_year: TaxReturn::CURRENT_TAX_YEAR)
      WageRecord.create!(ssn: person_ssn, kind: "ssa_1099", payer_name: "Social Security Administration", amount: between("social_security"), colorado_withholding: 0, tax_year: TaxReturn::CURRENT_TAX_YEAR)
    elsif earner
      wages = wage
      factor = @random.rand(Range.new(*@config["withholding_factor"]))
      withheld = ([ wages - SINGLE_STANDARD_DEDUCTION_FOR_WITHHOLDING, 0 ].max * WITHHOLDING_RATE * factor).round
      WageRecord.create!(ssn: person_ssn, kind: "w2", payer_name: "Employer", amount: wages, colorado_withholding: withheld, tax_year: TaxReturn::CURRENT_TAX_YEAR)
    end
  end

  # Apply the assumed rates at which taxpayers differ from records on file.
  def misreport(tax_return, documents)
    behavior = @config["behavior"]
    document = documents.sample(random: @random)
    if document && @random.rand < behavior["overstates_withholding"]
      document.correct!(colorado_withholding: [ document.colorado_withholding + @random.rand(300..1_500), document.amount ].min)
    end
    if document && @random.rand < behavior["understates_income"]
      document.correct!(amount: [ (document.amount * @random.rand(0.6..0.95)).round, document.colorado_withholding, 1 ].max)
    end
    documents.last.dispute! if documents.size > 1 && @random.rand < behavior["disputes_a_record"]
    return unless @random.rand < behavior["adds_form_with_withholding"]

    amount = @random.rand(2_000..15_000)
    tax_return.income_documents.create!(
      kind: "w2", owner: "filer", payer_name: "Second Job", amount: amount, colorado_withholding: (amount * 0.03).round,
      source: "taxpayer", review_status: "entered"
    )
  end

  def wage
    settings = @config["wages"]
    # Box-Muller: a normal draw, turned into a log-normal wage.
    normal = Math.sqrt(-2 * Math.log(1 - @random.rand)) * Math.cos(2 * Math::PI * @random.rand)
    (settings["median"] * Math.exp(settings["sigma"] * normal)).round.clamp(settings["minimum"], settings["maximum"])
  end

  def between(key) = @random.rand(Range.new(*@config[key]))
  def birth_date(retired) = Date.new(retired ? @random.rand(1940..1959) : @random.rand(1962..2003), @random.rand(1..12), 1)

  # Made-up SSNs in area 000, which is never issued.
  def ssn(index, person) = format("000%02d%04d", 50 + person, index)
end
