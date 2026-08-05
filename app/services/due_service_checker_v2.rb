class DueServiceCheckerV2
  def call

    Vehicle.find_each do |vehicle|
      ServiceSchedule.where(vehicle_type: vehicle.vehicle_type, bike_model: vehicle.bike_model)
                      .each { |schedule| process_schedule(vehicle, schedule) }
    end
  end

  private

  def process_schedule(vehicle, schedule)
    service_type = schedule.service_type

    due_target_rule = ServiceRuleResolver.new.call(vehicle: vehicle, service_type: service_type, domain: "due_target")
    due_target_strategy = DueTargetStrategyRegistry.resolve(due_target_rule.strategy_key).new(due_target_rule)

    result = due_target_strategy.resolve(vehicle: vehicle, service_type: service_type, schedule: schedule)
    due_km = result[:due_km]
    due_date = result[:due_date]

    return if due_km.nil? && due_date.nil?

    current_km = vehicle.odometer_logs.order(recorded_at: :desc).first.reading
    return if current_km.nil?

    stage_rule = ServiceRuleResolver.new.call(vehicle: vehicle, service_type: service_type, domain: "stage")
    stage_strategy = StageStrategyRegistry.resolve(stage_rule.strategy_key).new(stage_rule.rule_config)

    stage_result = stage_strategy.compute_stage(
      due_km: due_km, 
      current_km: current_km, 
      interval_km: schedule.interval_km, 
      due_date: due_date
    )

    return if stage_result[:stage] == 0

    AlertGenerator.new(
      vehicle: vehicle,
      service_type: schedule.service_type,
      alert_type: stage_result[:alert_type],
      due_date: due_date, 
      due_odometer: due_km,
      target_stage: stage_result[:stage]
    ).call

  end
end