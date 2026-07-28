class Alert < ApplicationRecord
    enum :alert_type, {
        km: "km",
        time: "time",
        both: "both"
    }

    enum :status, {
        pending: "pending",
        resolved: "resolved",
        dismissed: "dismissed"
    }, default: "pending"

    belongs_to :vehicle
    belongs_to :service_type
    belongs_to :dismisser, class_name: "User", foreign_key: :dismissed_by_id, optional: true

    validates :alert_type, presence: true
end
