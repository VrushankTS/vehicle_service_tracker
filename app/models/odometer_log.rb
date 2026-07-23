class OdometerLog < ApplicationRecord
    belongs_to :vehicle
    belongs_to :logger, class_name: "User", foreign_key: :logged_by

    validates :reading, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
