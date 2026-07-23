class InvoiceItem < ApplicationRecord
    enum :item_type, {
        service: "service",
        labor: "labor",
        parts: "parts",
        discount: "discount"
    }

    belongs_to :invoice
    
    validates :description, presence: true
    validates :item_type, presence: true
    validates :amount, presence: true
end
