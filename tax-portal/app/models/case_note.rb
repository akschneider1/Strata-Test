# frozen_string_literal: true

class CaseNote < ApplicationRecord
  belongs_to :tax_return_case
  belongs_to :author, class_name: "User"

  validates :body, presence: true, length: { maximum: 4000 }
end
