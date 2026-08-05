class GeneralServiceMilestone < ApplicationRecord
  belongs_to :service_rule

  validates :interval_km, presence: true
  validates :interval_months, presence: true
  validates :service_rule, uniqueness: { scope: :sequence }

end