# frozen_string_literal: true

namespace :tax do
  desc "Process filed returns that have not been calculated yet (run on a schedule)"
  task process_pending: :environment do
    processed = ReturnProcessing.process_pending
    puts "Processed #{processed} return(s); #{ReturnProcessing.pending.count} still waiting"
  end
end
