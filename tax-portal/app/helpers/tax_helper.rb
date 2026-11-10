# frozen_string_literal: true

# View helpers shared by the taxpayer and examiner portals.
module TaxHelper
  # Text for the current interview page. Lazy lookups (t(".key")) don't work
  # inside the shared question layout, and the page is re-rendered from the
  # update action when validation fails.
  def page_t(key, **options)
    t("tax_returns.#{action_name.sub(/\Aupdate_/, 'edit_')}.#{key}", **options)
  end

  # Whole-dollar amounts, as on the Colorado return.
  def money(amount)
    number_to_currency(amount.to_i, precision: 0)
  end

  # Colorado Design System in-page alert. Initial-render alerts carry no
  # live-region role (see the CoDS in-page-alert fixture).
  def cods_alert(type, heading: nil, **options, &block)
    cods_type = { error: "urgent" }.fetch(type, type.to_s)
    classes = class_names("usa-alert", "usa-alert--#{type}", "cods-in-page-alert", "cods-in-page-alert--#{cods_type}", options.delete(:class))
    content_tag(:div, class: classes, **options) do
      content_tag(:div, class: "usa-alert__body cods-in-page-alert__body") do
        safe_join([
          (content_tag(:h2, heading, class: "usa-alert__heading cods-in-page-alert__heading") if heading),
          content_tag(:div, capture(&block), class: "usa-alert__text cods-in-page-alert__text")
        ].compact)
      end
    end
  end

  def cods_tag(text, color = nil)
    content_tag(:span, text, class: class_names("usa-tag", "cods-tags", ("cods-tags--#{color}" if color)))
  end

  # Show only the last four digits of an SSN or account number.
  def masked(value, visible: 4)
    return "" if value.blank?

    "•••• #{value.to_s.last(visible)}"
  end

  def calculation_line_label(line)
    t("tax_calculation.lines.#{line.id}.label")
  end

  # Plain-language reason for a line, with the facts behind it filled in.
  def calculation_line_explanation(line, tax_year:)
    facts = line.facts.symbolize_keys
    facts[:rate] = number_to_percentage(facts[:rate].to_f * 100, precision: 1, strip_insignificant_zeros: true) if facts.key?(:rate)
    %i[standard_deduction federal_eitc childcare_expenses].each { |key| facts[key] = money(facts[key]) if facts.key?(key) }
    key = "tax_calculation.lines.#{line.id}.explanation"
    key += line.amount.positive? ? "_yes" : "_no" if TaxCalculation::CREDIT_IDS.include?(line.id)
    t(key, **facts, tax_year: tax_year, default: "")
  end

  def income_kind_label(kind)
    t("income_documents.kinds.#{kind}.name")
  end

  def stage_tag(stage)
    color = { received: "blue", in_review: "yellow", needs_information: "red", accepted: "green", not_accepted: "red" }[stage]
    cods_tag(t("tax_returns.stages.#{stage}.tag"), color)
  end
end
