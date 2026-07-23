class Invoice < ApplicationRecord
    belongs_to :vehicle
    belongs_to :service_record
    belongs_to :uploader, class_name: "User", foreign_key: :uploaded_by
    has_many :invoice_items, dependent: :destroy

    validates :invoice_number, uniqueness: true
    validates :amount, presence: true
end
