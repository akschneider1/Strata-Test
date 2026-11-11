# frozen_string_literal: true

# The Strata SDK's memorable date field has "Month", "Day", "Year" and the
# English month names fixed in its code. This puts them in the page's
# language. Prepended to Strata::FormBuilder in
# config/initializers/strata_date_fields.rb. Drop it once the SDK translates
# them.
module LocalizedMemorableDate
  def memorable_date(attribute, options = {})
    html = super.to_str
    %w[month day year].each do |part|
      html = html.sub(">#{part.capitalize}</label>", ">#{ERB::Util.html_escape(I18n.t("shared.date_fields.#{part}"))}</label>")
    end
    names = I18n.t("date.month_names", default: Date::MONTHNAMES)
    (1..12).each do |month|
      html = html.sub(">#{Date::MONTHNAMES[month]}</option>", ">#{ERB::Util.html_escape(names[month].to_s.capitalize)}</option>")
    end
    html.html_safe # rubocop:disable Rails/OutputSafety -- SDK markup with escaped labels swapped in
  end
end
