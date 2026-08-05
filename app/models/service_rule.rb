class ServiceRule < ApplicationRecord
  belongs_to :vehicle_type
  has_many :general_service_milestones

  validates :name, presence: true
  validates :priority, presence: true
  validates :strategy_domain, inclusion: { in: %w[stage due_target] }
  validates :strategy_key, presence: true
  validate :priority_unique_among_date_cohort_rules

  private

  def priority_unique_among_date_cohort_rules
    return unless condition.is_a?(Hash) && condition["purchase_before_date"].present?

    conflict = ServiceRule.where(
      vehicle_type_id: vehicle_type_id,
      strategy_domain: strategy_domain,
      priority: priority
    ).where.not(id: id)
    .select { |rule| rule.condition.is_a?(Hash) && rule.condition["purchase_before_date"].present? }.any?

    errors.add(:priority, "must be unique among date-based rules for this vehicle type and domain") if conflict
  end
end