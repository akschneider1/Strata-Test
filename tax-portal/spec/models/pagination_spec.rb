# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Pagination do
  it "works out the pages and which items are showing" do
    pagination = described_class.new(page: 3, total: 120, per_page: 25)

    expect(pagination).to have_attributes(pages: 5, offset: 50, first_item: 51, last_item: 75, previous_page: 2, next_page: 4, needed?: true)
  end

  it "keeps the page within range" do
    expect(described_class.new(page: 0, total: 10).page).to eq(1)
    expect(described_class.new(page: "abc", total: 10).page).to eq(1)
    expect(described_class.new(page: 99, total: 60, per_page: 25)).to have_attributes(page: 3, next_page: nil, last_item: 60)
  end

  it "needs no page links for a short or empty list" do
    expect(described_class.new(page: 1, total: 0)).to have_attributes(pages: 1, needed?: false, first_item: 0, last_item: 0)
    expect(described_class.new(page: 1, total: 25)).to have_attributes(needed?: false)
  end

  it "links the first, last and nearby pages, with gaps" do
    expect(described_class.new(page: 10, total: 500, per_page: 25).series).to eq([ 1, nil, 8, 9, 10, 11, 12, nil, 20 ])
    expect(described_class.new(page: 1, total: 75, per_page: 25).series).to eq([ 1, 2, 3 ])
  end
end
