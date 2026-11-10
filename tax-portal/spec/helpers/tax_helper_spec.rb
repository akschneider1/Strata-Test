# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaxHelper do
  let(:moment) { Time.utc(2026, 11, 10, 5, 6) } # 10:06 PM the day before in Denver

  it "writes dates and times one way, in Mountain time, without leading zeros" do
    expect(helper.plain_date(Date.new(1991, 8, 2))).to eq("August 2, 1991")
    expect(helper.plain_time(moment)).to eq("November 9, 2026 at 10:06 PM, Mountain time")
    expect(helper.short_time(moment)).to eq("November 9 at 10:06 PM")
  end

  it "writes them in Spanish too" do
    I18n.with_locale(:"es-US") do
      expect(helper.plain_date(Date.new(1991, 8, 2))).to eq("2 de agosto de 1991")
      expect(helper.plain_time(moment)).to eq("9 de noviembre de 2026 a las 10:06 p. m., hora de la Montaña")
    end
  end
end
