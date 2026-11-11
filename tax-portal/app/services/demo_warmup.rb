# frozen_string_literal: true

# Gets the demo ready before the first visitor arrives.
#
# The tax engine's first calculations after it starts are slow, and it
# remembers each household it has calculated. A visitor's first click files
# three returns, so without this the first visitor waits for all of that.
# This runs the demo households through the engine once (2025 returns and the
# 2027 rates comparison) in a copy of the demo that is then discarded.
#
# Safe to run at any time. Never runs in production.
class DemoWarmup
  Result = Struct.new(:households, :seconds)

  # Waits up to `wait` for the engine to finish loading its rules.
  def self.run(wait: 10.minutes, pause: 2)
    raise "Not available in production" if Rails.env.production?

    deadline = Time.current + wait
    until DemoMode.ready?
      raise TaxEngine::Unavailable, "The tax engine was not ready after #{wait.inspect}" if Time.current > deadline

      sleep pause
    end

    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    households = 0
    space = DemoSpace.start!
    begin
      DemoData.new(space).maya(space.person(:maya))
      TaxReturn.where(user_id: space.users.select(:id)).find_each do |tax_return|
        tax_return.calculate! unless tax_return.submitted?
        TaxEngine::RatePreview.for(TaxEngine::Facts.from_tax_return(tax_return))
        households += 1
      end
    ensure
      space.discard!
    end
    Result.new(households, (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).round(1))
  end
end
