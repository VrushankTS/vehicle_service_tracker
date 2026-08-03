class ServiceSchedule < ApplicationRecord
    belongs_to :bike_model
    belongs_to :service_type
    belongs_to :vehicle_type
end
