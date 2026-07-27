class ServiceType < ApplicationRecord
    validates :name, presence: true, uniqueness: true

    has_many :service_schedules, dependent: :destroy
    has_many :alerts, dependent: :destroy
    has_many :service_records, dependent: :restrict_with_error
end
