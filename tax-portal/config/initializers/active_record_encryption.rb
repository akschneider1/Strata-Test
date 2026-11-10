# frozen_string_literal: true

# Keys for Active Record encryption, which protects Social Security numbers
# and bank account numbers at rest.
#
# Deployed environments must provide all three values as secrets. Local
# development and tests fall back to fixed, publicly known values so the app
# runs without setup (the image build does the same); they protect nothing and must never be used with real data.
Rails.application.configure do
  # SECRET_KEY_BASE_DUMMY is set while building the container image (asset
  # precompile), when no secrets are available and no data is touched.
  local = Rails.env.local? || ENV["SECRET_KEY_BASE_DUMMY"].present?
  fetch = lambda do |name, dev_default|
    ENV.fetch(name) do
      raise KeyError, "#{name} must be set in #{Rails.env}" unless local

      dev_default
    end
  end

  config.active_record.encryption.primary_key = fetch.call("AR_ENCRYPTION_PRIMARY_KEY", "dev-only-primary-key-not-a-secret-0001")
  config.active_record.encryption.deterministic_key = fetch.call("AR_ENCRYPTION_DETERMINISTIC_KEY", "dev-only-deterministic-key-not-secret-01")
  config.active_record.encryption.key_derivation_salt = fetch.call("AR_ENCRYPTION_KEY_DERIVATION_SALT", "dev-only-salt-not-a-secret-000000000001")
end
