class ServiceCompletionService
  MAX_KM_PER_HOUR = 100
  MIN_ELAPSED_HOURS = 1.0 / 3600

  attr_reader :registration_number, :service_type_id, :odometer_reading, :alert_id, :agent, :confirmed, :notes

  def initialize(regn_no: nil, service_type_id: nil, reading: nil, alert_id: nil, agent: nil, confirmed: false, notes: nil)
    @registration_number = regn_no
    @service_type_id = service_type_id
    @odometer_reading = reading
    @alert_id = alert_id
    @agent = agent
    @confirmed = confirmed
    @notes = notes
  end

  def call
    return ServiceResult.error("Registration number is required") if registration_number.blank?

    vehicle = Vehicle.find_by(registration_number: registration_number)
    return ServiceResult.error("Vehicle does not exist") if vehicle.nil?

    return ServiceResult.error("Agent is required") if agent.nil?
    return ServiceResult.error("Agent does not exist") unless agent.is_a?(User) && agent.persisted?

    return ServiceResult.error("Service type is required") if service_type_id.blank?
    service_type = ServiceType.find_by(id: service_type_id)
    return ServiceResult.error("Service type doesn't exist") if service_type.nil?

    return ServiceResult.error("Odometer reading must be a valid non-negative number") if odometer_reading.blank? || odometer_reading < 0

    previous_log = vehicle.odometer_logs.order(recorded_at: :desc).first

    if previous_log.present? && !confirmed
      if odometer_reading < previous_log.reading
        return ServiceResult.needs_confirmation(
          "New reading (#{odometer_reading}) is lower than the last recorded reading (#{previous_log.reading}). " \
          "Was the odometer reset or replaced? Confirm to proceed."
        )
      end

      elapsed_hours = [(Time.current - previous_log.recorded_at) / 1.hour, MIN_ELAPSED_HOURS].max
      actual_increase = odometer_reading - previous_log.reading
      speed = actual_increase / elapsed_hours

      if speed > MAX_KM_PER_HOUR
        return ServiceResult.needs_confirmation(
          "Reading jumped by #{actual_increase} km in #{elapsed_hours.round(2)} hours " \
          "(~#{speed.round(1)} km/h), which is unusually high. Confirm this is correct?"
        )
      end
    end

    alert = nil
    if alert_id.present?
      alert = Alert.find_by(id: alert_id)
      return ServiceResult.error("Alert not found") if alert.nil?

      if alert.vehicle_id != vehicle.id || alert.service_type_id != service_type.id
        return ServiceResult.error("Alert does not match this vehicle and service type")
      end

      return ServiceResult.error("Alert is not in a pending state") unless alert.status == 'pending'
    end

    # --- Compute next due targets ---
    due_target_rule = ServiceRuleResolver.new.call(vehicle: vehicle, service_type: service_type, domain: "due_target")
    
    next_due_odometer = nil
    next_due_date = nil

    if due_target_rule.strategy_key == 'general_milestone'
      completed_count = vehicle.service_records.where(service_type_id: service_type.id).count
      milestones = due_target_rule.general_service_milestones.order(sequence: :asc)

      starting_log = vehicle.odometer_logs.order(recorded_at: :asc).first
      next_milestone = milestones[completed_count+1]

      unless next_milestone.nil?
        next_due_odometer = starting_log.reading + next_milestone.interval_km
        next_due_date = vehicle.purchase_date + next_milestone.interval_months.months
      end

    else
      service_schedule = ServiceSchedule.find_by(
        service_type_id: service_type.id, bike_model_id: vehicle.bike_model_id,
        vehicle_type_id: vehicle.vehicle_type_id
      )
      return ServiceResult.error("No service schedule defined for this vehicle type, model and service type") if service_schedule.nil?

      stage_rule = ServiceRuleResolver.new.call(vehicle: vehicle, service_type: service_type, domain: "stage")
      config = stage_rule.rule_config
      
      effective_interval_km = config["interval_km"] || service_schedule.interval_km
      effective_interval_months = config["interval_months"] || service_schedule.interval_months

      next_due_odometer = odometer_reading + effective_interval_km
      next_due_date = Date.current + effective_interval_months.months
    end

    next_due_date = nil if vehicle.vehicle_type == VehicleType.find_by(code: "MBS")

    service_record = nil
    error_message = nil

    ActiveRecord::Base.transaction do
      odometer_log = OdometerLog.create(
        vehicle: vehicle,
        odometer_logger: agent,
        reading: odometer_reading,
        recorded_at: Time.current
      )
      unless odometer_log.persisted?
        error_message = odometer_log.errors.full_messages.join(", ")
        raise ActiveRecord::Rollback
      end

      service_record = ServiceRecord.create(
        vehicle: vehicle,
        service_type: service_type,
        agent: agent,
        odometer_at_service: odometer_reading,
        serviced_at: Time.current,
        next_due_odometer: next_due_odometer,
        next_due_date: next_due_date,
        notes: notes
      )
      unless service_record.persisted?
        error_message = service_record.errors.full_messages.join(", ")
        raise ActiveRecord::Rollback
      end

      if alert
        unless alert.update(status: "resolved")
          error_message = alert.errors.full_messages.join(", ")
          raise ActiveRecord::Rollback
        end
      end
    end

    if service_record&.persisted?
      ServiceResult.success(service_record)
    else
      ServiceResult.error(error_message || "Could not complete the service")
    end
  end
end