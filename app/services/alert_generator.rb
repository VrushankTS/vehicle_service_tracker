class AlertGenerator
  RESEND_INTERVAL_DAYS = { 1 => 7, 2 => 2, 3 => 1 }.freeze

  def initialize(vehicle:, service_type:, alert_type:, due_date:, due_odometer:, target_stage:)
    @vehicle = vehicle
    @service_type = service_type
    @alert_type = alert_type
    @due_date = due_date
    @due_odometer = due_odometer
    @target_stage = target_stage
  end

  def call
    latest_alert = Alert.where(vehicle: vehicle, service_type: service_type).order(created_at: :desc).first
    existing_alert = same_cycle?(latest_alert) ? latest_alert : nil

    return unless should_notify?(existing_alert)

    alert = if existing_alert
              existing_alert.update(
                status: "pending",
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

  def same_cycle?(alert)
    return false if alert.nil?
    alert.due_date == due_date && alert.due_odometer == due_odometer
  end

  def should_notify?(existing_alert)
    return true if existing_alert.nil?

    case existing_alert.status
    when "resolved"
      false   
      
    when "dismissed"
      target_stage > existing_alert.last_notified_stage  

    else 
      return true if target_stage > existing_alert.last_notified_stage
      if target_stage == existing_alert.last_notified_stage
          days_since_last_sent = (Date.current - existing_alert.sent_at.to_date).to_i
          return days_since_last_sent >= RESEND_INTERVAL_DAYS[target_stage]
      end

      false
    end
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
