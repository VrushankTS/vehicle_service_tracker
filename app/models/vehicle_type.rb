class VehicleType < ApplicationRecord
  validates :code, presence: true, uniqueness: true
  validates :name, presence: true, uniqueness: true

  has_many :vehicles
  has_many :service_schedules
  has_many :service_rules
end