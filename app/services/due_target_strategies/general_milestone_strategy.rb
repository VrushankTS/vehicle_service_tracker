module DueTargetStrategies
  class GeneralMilestoneStrategy < BaseStrategy
    def resolve(vehicle:, service_type:, schedule: nil)
      completed_count = vehicle.service_records.where(service_type_id: service_type.id).count

      milestones = rule.general_service_milestones.order(sequence: :asc)
      return { due_km: nil, due_date: nil, milestone: nil } if completed_count == milestones.count

      current_milestone = milestones[completed_count]
      starting_log = vehicle.odometer_logs.order(recorded_at: :asc).first
      return { due_km: nil, due_date: nil, milestone: nil } if starting_log.nil?

      {
        due_km: starting_log.reading + current_milestone.interval_km,
        due_date: vehicle.purchase_date + current_milestone.interval_months.months,
        milestone: current_milestone
      }
    end
  end
end