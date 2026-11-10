# frozen_string_literal: true

class InformationRequest < ApplicationRecord
  belongs_to :tax_return_case
  belongs_to :requested_by, class_name: "User"

  validates :question, presence: true, length: { maximum: 2000 }
  validates :response, presence: true, length: { maximum: 4000 }, on: :respond

  def answered? = responded_at.present?
end
