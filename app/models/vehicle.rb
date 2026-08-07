class Vehicle < ApplicationRecord
    before_validation :normalize_registration_number

    validates :registration_number,
                presence: true, uniqueness: true,
                format: {
                    with: /\A[A-Z]{2}\s?\d{2}\s?[A-Z]{1,2}\s?\d{4}\z/,
                    message: "Must be in the format KA01AB1234 or KA 01 AB 1234"
                }
    validates :registration_number, presence: true, uniqueness: true
    validates :purchase_date, presence: true
    validates :odometer_reading, presence: true
    
    belongs_to :bike_model
    belongs_to :vehicle_type
    has_many :odometer_logs, dependent: :destroy
    has_many :invoices, dependent: :restrict_with_error
    has_many :alerts, dependent: :destroy
    has_many :service_records, dependent: :restrict_with_error
    has_many :service_reports, dependent: :restrict_with_error

    private

    def normalize_registration_number
        self.registration_number = registration_number&.upcase&.gsub(/\s+/, "")
    end
end
