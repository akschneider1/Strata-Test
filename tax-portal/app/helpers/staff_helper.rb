# frozen_string_literal: true

module StaffHelper
  STEP_COLORS = { "review_return" => "yellow", "provide_information" => "red", "end" => "green" }.freeze

  def case_step_tag(kase)
    cods_tag(t("staff.steps.#{kase.step}"), STEP_COLORS[kase.step])
  end

  # One sentence explaining why the automatic checks raised a flag.
  def flag_description(flag)
    details = flag.details.symbolize_keys
    %i[reported on_file on_file_amount refund total_income].each { |key| details[key] = money(details[key]) if details.key?(key) }
    details[:kind] = income_kind_label(details[:kind]) if details.key?(:kind)
    t("staff.flags.#{flag.code}.description", **details)
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

  def actor_name(line)
    line.actor.is_a?(User) ? "#{line.actor.display_name} (#{t("staff.roles.#{line.actor.role}")})" : t("staff.roles.system")
  end
end
