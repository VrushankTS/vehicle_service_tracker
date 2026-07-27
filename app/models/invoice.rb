class Invoice < ApplicationRecord
    belongs_to :vehicle
    belongs_to :service_record
    belongs_to :uploader, class_name: "User", foreign_key: :uploaded_by
    has_many :invoice_items, dependent: :destroy
    has_one_attached :file

    validates :invoice_number, uniqueness: true
    validates :amount, presence: true
    validate :file_is_pdf
    validate :file_within_size_limit

    private

    def file_is_pdf
        return unless file.attached?
        errors.add(:file, "must be a PDF") unless file.content_type == "application/pdf"
    end

    def file_within_size_limit
        return unless file.attached?
        errors.add(:file, "must be under 10MB") if file.byte_size > 10.megabytes
    end
end