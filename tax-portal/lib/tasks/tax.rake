# frozen_string_literal: true

namespace :tax do
  desc "Discard every visitor's copy of the demo. Each visitor starts fresh the next time they choose a person."
  task demo_reset: :environment do
    raise "Not available in production" if Rails.env.production?

    copies = DemoSpace.count
    DemoSpace.discard_all
    puts "Discarded #{copies} copies of the demo"
  end

  desc "Process filed returns that have not been calculated yet (run on a schedule)"
  task process_pending: :environment do
    processed = ReturnProcessing.process_pending
    puts "Processed #{processed} return(s); #{ReturnProcessing.pending.count} still waiting"
  end

  desc "Get the demo ready before the first visitor: run the demo households through the tax engine once"
  task demo_warm: :environment do
    ActiveRecord::Base.logger = nil
    result = DemoWarmup.run
    puts "Demo warmed up: #{result.households} households in #{result.seconds}s"
  end

  desc "Estimate the share of returns the automatic checks would flag. Usage: tax:review_rate[500]"
  task :review_rate, [ :returns ] => :environment do |_task, args|
    ActiveRecord::Base.logger = nil
    result = ReviewRateStudy.new(returns: (args[:returns] || 500).to_i).run
    puts "Returns filed: #{result.returns} (#{result.seconds}s, tax engine: #{ENV.fetch('TAX_ENGINE_ADAPTER', 'http')})"
    puts "Sent to an examiner: #{result.flagged} (#{result.flagged_share}%)"
    puts "By reason (a return can have more than one):"
    result.by_code.each { |code, count| puts format("  %-34s %5d  %5.1f%%   only reason on %d", code, count, result.share(count), result.only_code[code].to_i) }
    puts "By household:"
    result.by_household.sort.each do |household, count|
      flagged = result.flagged_by_household[household].to_i
      puts format("  %-22s %5d returns  %5d flagged  %5.1f%%", household, count, flagged, flagged * 100.0 / count)
    end
  end
end
