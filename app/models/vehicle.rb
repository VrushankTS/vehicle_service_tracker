class Vehicle < ApplicationRecord
    validates :registration_number, presence: true, uniqueness: true
    validates :purchase_date, presence: true
    
    belongs_to :bike_model
    has_many :odometer_logs, dependent: :destroy
    has_many :invoices, dependent: :restrict_with_error
    has_many :alerts, dependent: :destroy
    has_many :service_records, dependent: :restrict_with_error
    has_many :service_reports, dependent: :restrict_with_error
end
