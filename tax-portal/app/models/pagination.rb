# frozen_string_literal: true

# Which page of a long list is showing. Used by the examiner portal's lists.
class Pagination
  PER_PAGE = 25
  # Page links shown either side of the current page.
  WINDOW = 2

  attr_reader :page, :total, :per_page

  def initialize(page:, total:, per_page: PER_PAGE)
    @total = total
    @per_page = per_page
    @page = page.to_i.clamp(1, pages)
  end

  def pages = [ (total / per_page.to_f).ceil, 1 ].max
  def offset = (page - 1) * per_page
  def first_item = total.zero? ? 0 : offset + 1
  def last_item = [ offset + per_page, total ].min
  def previous_page = (page - 1 if page > 1)
  def next_page = (page + 1 if page < pages)
  def needed? = pages > 1

  # Page numbers to link, with nil where pages are skipped: 1 … 4 5 6 … 20
  def series
    numbers = ([ 1, pages ] + ((page - WINDOW)..(page + WINDOW)).to_a).select { |n| n.between?(1, pages) }.uniq.sort
    numbers.each_with_object([]) do |number, list|
      list << nil if list.last && number > list.last + 1
      list << number
    end
  end

  def apply(scope) = scope.limit(per_page).offset(offset)
end
