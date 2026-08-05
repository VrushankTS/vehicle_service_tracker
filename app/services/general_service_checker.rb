class GeneralServiceChecker

  def call
    general_type = ServiceType.find_by!(name: "General Checkup")

    Vehicle.find_each do |vehicle|
      process_vehicle(vehicle, general_type)
    end
  end

  private

  def process_vehicle(vehicle, general_type)
    due_target_rule = ServiceRuleResolver.new.call(vehicle: vehicle, service_type: general_type, domain: "due_target")
    due_target_strategy = DueTargetStrategyRegistry.resolve(due_target_rule.strategy_key).new(due_target_rule)

    result = due_target_strategy.resolve(vehicle: vehicle, service_type: general_type)
    due_km = result[:due_km]
    due_date = result[:due_date]
    milestone = result[:milestone]

    return if due_km.nil? && due_date.nil?   # no baseline yet, or all milestones completed

    current_km = vehicle.odometer_logs.order(recorded_at: :desc).first&.reading
    return if current_km.nil?

    stage_rule = ServiceRuleResolver.new.call(vehicle: vehicle, service_type: general_type, domain: "stage")
    stage_strategy = StageStrategyRegistry.resolve(stage_rule.strategy_key).new(stage_rule.rule_config)

    stage_result = stage_strategy.compute_stage(
      due_km: due_km,
      current_km: current_km,
      due_date: due_date,
      interval_km: milestone&.interval_km
    )

    return if stage_result[:stage].zero?

    AlertGenerator.new(
      vehicle: vehicle,
      service_type: general_type,
      alert_type: stage_result[:alert_type],
      due_date: due_date,
      due_odometer: due_km,
      target_stage: stage_result[:stage]
    ).call
  end
end