class ServiceSchedule < ApplicationRecord
    belongs_to :bike_model
    belongs_to :service_type
    
    validates :bike_model_id, uniqueness: { scope: :service_type_id } 
end
