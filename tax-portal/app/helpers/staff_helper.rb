# frozen_string_literal: true

module StaffHelper
  STEP_COLORS = { "review_return" => "yellow", "second_review" => "yellow", "provide_information" => "red", "end" => "green" }.freeze

  def case_step_tag(kase)
    cods_tag(t("staff.steps.#{kase.step}"), STEP_COLORS[kase.step])
  end

  # The outcome of a closed return, or where an open one stands.
  def case_status_tag(kase)
    return case_step_tag(kase) unless kase.outcome

    cods_tag(t("staff.outcomes.#{kase.outcome}"), kase.accepted? ? "green" : "red")
  end

  # One sentence explaining why the automatic checks raised a flag.
  def flag_description(flag)
    details = flag.details.symbolize_keys
    %i[reported on_file on_file_amount refund total_income].each { |key| details[key] = money(details[key]) if details.key?(key) }
    details[:kind] = income_kind_label(details[:kind]) if details.key?(:kind)
    t("staff.flags.#{flag.code}.description", **details)
  end

  # "Difference: $1,000." for a flag that compares a reported amount with
  # the amount on file. Nil for flags that don't.
  def flag_difference(flag)
    details = flag.details.symbolize_keys
    return unless details[:reported] && details[:on_file]

    t("staff.flags.difference", amount: money((details[:reported].to_i - details[:on_file].to_i).abs))
  end

  # "Refund $1,705" where the result stands alone (a table cell, a fact).
  def result_label(refund, amount_owed)
    result_phrase(refund, amount_owed).upcase_first
  end

  # One way to write a time in the examiner portal: "Nov 10, 8:26 PM".
  def staff_time(time)
    time.in_time_zone("America/Denver").strftime("%b %-d, %-l:%M %p")
  end

  # A headline number in a card. Cards in one `usa-card-group` share a height.
  def stat_card(label, value, note: nil, testid: nil)
    content_tag(:li, class: "usa-card cods-card tablet:grid-col-6 desktop:grid-col-3") do
      content_tag(:div, class: "usa-card__container cods-card__container", data: { testid: testid }) do
        content_tag(:div, class: "usa-card__body cods-card__body padding-y-2") do
          safe_join([
            content_tag(:p, label, class: "margin-0 text-bold"),
            content_tag(:p, value, class: "margin-0 margin-top-05 font-heading-2xl text-bold line-height-heading-1"),
            (content_tag(:p, note, class: "margin-0 margin-top-05 font-body-2xs text-base-dark") if note)
          ].compact)
        end
      end
    end
  end

  def audit_line_summary(line)
    data = line.data.symbolize_keys
    case line.action
    when "return.calculated"
      t("staff.history.calculated", engine: data[:engine], version: data[:engine_version], result: result_phrase(data[:refund], data[:amount_owed]))
    when "return.screened"
      data[:flags].present? ? t("staff.history.flagged", count: data[:flags].size) : t("staff.history.cleared")
    when "review.adjusted"
      t("staff.history.adjusted", field: t("adjustable_fields.#{data[:field]}"), from: money(data[:from]), to: money(data[:to]),
        before: result_phrase(data[:refund_before], data[:amount_owed_before]), after: result_phrase(data[:refund_after], data[:amount_owed_after]))
    when "review.second_approval_requested", "review.confirmed"
      t("staff.history.#{line.action.tr('.', '_')}", proposed: t("staff.outcomes.#{data[:proposed_outcome]}").downcase)
    when "review.assigned"
      t(data[:taken_over] ? "staff.history.review_taken_over" : "staff.history.review_assigned")
    when "return.accepted", "return.accepted_with_adjustments"
      t("staff.history.#{line.action.delete_prefix('return.')}", result: result_phrase(data[:refund], data[:amount_owed]),
        how: data[:automatic] ? t("staff.history.automatically") : "")
    else
      t("staff.history.#{line.action.tr('.', '_')}", default: line.action)
    end
  end

  def result_phrase(refund, amount_owed)
    amount_owed.to_i.positive? ? t("staff.result.owes", amount: money(amount_owed)) : t("staff.result.refund", amount: money(refund))
  end

  # A length of time in the largest sensible unit, for the measures page.
  def measure_duration(seconds)
    return t("staff.measures.not_yet") if seconds.nil?
    return t("staff.measures.under_a_minute") if seconds < 60

    distance_of_time_in_words(seconds)
  end

  # Total effect of examiner adjustments on what taxpayers receive.
  def measure_net_change(amount)
    if amount.zero? then t("staff.measures.adjustments.no_change")
    elsif amount.negative? then t("staff.measures.adjustments.less", amount: money(amount.abs))
    else t("staff.measures.adjustments.more", amount: money(amount))
    end
  end

  def actor_name(line)
    line.actor.is_a?(User) ? "#{line.actor.display_name} (#{t("staff.roles.#{line.actor.role}")})" : t("staff.roles.system")
  end
end
