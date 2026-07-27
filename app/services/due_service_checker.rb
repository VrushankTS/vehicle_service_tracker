class DueServiceChecker
  DATE_THRESHOLDS_DAYS = { early: 15, close: 7 }.freeze
  KM_THRESHOLD_PERCENTS = { early: 0.10, close: 0.03 }.freeze

  def call
    Vehicle.find_each do |vehicle|
      vehicle.bike_model.service_schedules.each do |schedule|
        process_schedule(vehicle, schedule)
      end
    end
  end

  private

  def process_schedule(vehicle, schedule)
    due_km, due_date = due_targets_for(vehicle, schedule)
    return if due_km.nil? && due_date.nil?

    current_km = vehicle.odometer_logs.order(recorded_at: :desc).first.reading
    
    return if current_km.nil?

    date_stage = compute_date_stage(due_date)
    km_stage = compute_km_stage(due_km, current_km, schedule.interval_km)
    target_stage = [date_stage, km_stage].max
    return if target_stage==0

    alert_type = if target_stage == km_stage && target_stage == date_stage
                  "both"
                elsif target_stage == km_stage
                  "km"
                else
                  "time"
                end

    AlertGenerator.new(
      vehicle: vehicle,
      service_type: schedule.service_type,
      alert_type: alert_type,
      due_date: due_date, 
      due_odometer: due_km,
      target_stage: target_stage
    ).call

  end

  def due_targets_for(vehicle, schedule)
    last_service = vehicle.service_records
                    .where(service_type_id: schedule.service_type_id)
                    .order(serviced_at: :desc)
                    .first

    if last_service
      return [last_service.next_due_odometer, last_service.next_due_date]

    else
      starting_log = vehicle.odometer_logs.order(recorded_at: :asc).first
      return [nil, nil] if starting_log.nil?

      due_km = starting_log.reading + schedule.interval_km
      due_date = vehicle.purchase_date + schedule.interval_months.months
      [due_km, due_date]
    end    
  end
  
  def compute_km_stage(due_km, current_km, interval_km)
    return 0 if due_km.blank? || interval_km.blank? || interval_km==0

    kms_remaining = due_km - current_km
    percent_remaining = kms_remaining.to_f / interval_km

    return 3 if kms_remaining<=0
    return 2 if percent_remaining <= KM_THRESHOLD_PERCENTS[:close]
    return 1 if percent_remaining <= KM_THRESHOLD_PERCENTS[:early]

    0
  end

  def compute_date_stage(due_date)
    return 0 if due_date.blank?

    days_remaining = (due_date - Date.current).to_i
    return 3 if days_remaining<=0
    return 2 if days_remaining <= DATE_THRESHOLDS_DAYS[:close]
    return 1 if days_remaining <= DATE_THRESHOLDS_DAYS[:early]

    0
  end
end
