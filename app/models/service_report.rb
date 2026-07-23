class ServiceReport < ApplicationRecord
    belongs_to :vehicle
    belongs_to :service_record
    belongs_to :uploader, class_name: "User", foreign_key: :uploaded_by
end
