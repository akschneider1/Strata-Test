# frozen_string_literal: true

# Show the SDK's date fields in the page's language (see LocalizedMemorableDate).
Rails.application.config.to_prepare do
  Strata::FormBuilder.prepend(LocalizedMemorableDate)
end
