class AlertGenerator
  RESEND_INTERVAL_DAYS = { 1 => 7, 2 => 2, 3 => 1 }

  def initialize(vehicle:, service_type:, alert_type:, due_date:, due_odometer:, target_stage:)
    @vehicle = vehicle
    @service_type = service_type
    @alert_type = alert_type
    @due_date = due_date
    @due_odometer = due_odometer
    @target_stage = target_stage
  end

  def call
    existing_alert = Alert.find_by(vehicle: vehicle, service_type: service_type, status: 'pending')

    return unless should_notify?(existing_alert)

    alert = if existing_alert
              existing_alert.update(
                last_notified_stage: target_stage,
                alert_type: alert_type,
                sent_at: Time.current
              )
              existing_alert

            else
              Alert.create(
                vehicle: vehicle,
                service_type: service_type,
                alert_type: alert_type,
                due_date: due_date,
                due_odometer: due_odometer,
                status: "pending",
                last_notified_stage: target_stage,
                sent_at: Time.current
              )
            end

    notify(alert)
    alert

  end

  private
  
  attr_reader :vehicle, :service_type, :alert_type, :due_date, :due_odometer, :target_stage

  def should_notify?(existing_alert)
    return true if existing_alert.nil?      
    return true if target_stage > existing_alert.last_notified_stage

    if target_stage == existing_alert.last_notified_stage
      days_since_last_alert = (Date.current - existing_alert.sent_at.to_date).to_i
      return days_since_last_alert >= RESEND_INTERVAL_DAYS[target_stage]
    end

    false
  end

  def notify(alert)
    message = stage_message(alert)
    Rails.logger.info("[ALERT] #{message}")
  end

  def stage_message(alert)
    case target_stage
    when 1
      "Upcoming: " + vehicle.registration_number + " will need " + service_type.name + " soon."
    when 2
      "Reminder: " + vehicle.registration_number + " needs " + service_type.name + " very soon."
    else
      "Due: " + vehicle.registration_number + " is due for " + service_type.name + " now."
    end
  end
end
