# frozen_string_literal: true

# Subscribe business processes to the events that move cases along.
# Runs again after each code reload in development, so drop the previous
# subscriptions first to avoid handling an event twice.
Rails.application.config.to_prepare do
  Strata::EventManager.unsubscribe_all
  TaxReturnBusinessProcess.start_listening_for_events
end
