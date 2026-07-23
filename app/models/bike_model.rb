class BikeModel < ApplicationRecord
    validates :brand, presence: true
    validates :name, presence: true
    validates :name, uniqueness: { scope: :brand }

    has_many :vehicles, dependent: :restrict_with_error
    has_many :service_schedules, dependent: :destroy
end
