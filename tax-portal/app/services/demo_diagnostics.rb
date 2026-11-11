# frozen_string_literal: true

# Timings that show where a hosted demo is slow: the database, the tax
# engine, or the machine. Shown on /demo/diagnostics. Holds no personal data.
class DemoDiagnostics
  LOCAL_HOSTS = [ nil, "", "localhost", "127.0.0.1", "::1" ].freeze

  def self.ms
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round(1)
  end

  # Median of five trivial queries: the cost of one trip to the database.
  def database_round_trip_ms
    Array.new(5) { self.class.ms { ActiveRecord::Base.connection.select_value("SELECT 1") } }.sort[2]
  end

  def database_on_this_machine?
    host = ActiveRecord::Base.connection_db_config.configuration_hash[:host].to_s
    LOCAL_HOSTS.include?(host) || host.start_with?("/")
  end

  # One trip to the tax engine, with no calculation.
  def engine_round_trip_ms
    self.class.ms { @engine_status = TaxEngine.client(timeout: 5).status }
  rescue TaxEngine::Error
    nil
  end

  def engine_ready? = @engine_status&.fetch("ready", false) == true

  # A household the engine has not seen, so it can't answer from memory.
  def new_calculation_ms
    facts = {
      "tax_year" => TaxReturn::CURRENT_TAX_YEAR, "filing_status" => "SINGLE",
      "filer" => { "age" => 40, "wages" => 30_000 + SecureRandom.random_number(40_000), "unemployment_compensation" => 0, "pension_income" => 0, "social_security" => 0 },
      "spouse" => nil, "dependents" => [], "taxable_interest" => 0, "childcare_expenses" => 0, "colorado_tax_withheld" => 1_000
    }
    self.class.ms { TaxEngine.client(timeout: 60).calculate(facts) }
  rescue TaxEngine::Error
    nil
  end

  def processors = Etc.nprocessors

  # [total, available] in GB, where the system reports it.
  def memory_gb
    info = File.read("/proc/meminfo")
    %w[MemTotal MemAvailable].map { |key| (info[/^#{key}:\s+(\d+)/, 1].to_f / 1_048_576).round(1) }
  rescue SystemCallError
    nil
  end

  def demo_copies = DemoSpace.count
end
