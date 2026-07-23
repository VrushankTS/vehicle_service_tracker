class ServiceRecord < ApplicationRecord
    belongs_to :vehicle
    belongs_to :service_type
    belongs_to :agent, class_name: "User", foreign_key: "completed_by"
    has_many :invoices, dependent: :restrict_with_error
    has_one :service_report, dependent: :restrict_with_error

    validates :odometer_at_service, presence: true
    validates :serviced_at, presence: true
end
