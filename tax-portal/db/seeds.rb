# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Load seeds per Rails environment.
seed_filename = "#{ENV["SEED_FILENAME"] || Rails.env.downcase}.rb"
seed_path = Rails.root.join('db', 'seeds', seed_filename)

if File.file?(seed_path)
  puts "🌱 Seeding the database with #{seed_filename}"
  load(seed_path)
  puts "🪴 Done seeding"
else
  puts "🌲 No seeding necessary"
end

# Demo people for the tax prototype (see app/services/demo_data.rb).
# Only on request (bin/demo sets SEED_DEMO_DATA): loading them wipes existing
# tax data and submits returns, which needs the tax engine to be running
# (or TAX_ENGINE_ADAPTER=fake).
if ENV["SEED_DEMO_DATA"] == "true"
  DemoData.load!
  puts "Loaded demo data: #{User.where(provider: 'demo').count} people, #{TaxReturn.count} returns"
end
