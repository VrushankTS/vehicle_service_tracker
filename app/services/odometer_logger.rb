class OdometerLogger
    MAX_KM_PER_HOUR = 100
    MIN_ELAPSED_HOURS = 1.0 / 3600  # 1 second — prevents literal division-by-zero only

    attr_reader :registration_number, :reading, :confirmed, :logged_by

    def initialize(regn_no: nil, reading: nil, confirmed: false, logged_by: nil)
        @registration_number = regn_no
        @reading = reading
        @confirmed = confirmed
        @logged_by = logged_by
    end

    def call
        return ServiceResult.error("Logging user is required") if logged_by.nil?
        return ServiceResult.error("Logging user doesn't exist") unless logged_by.is_a?(User) && logged_by.persisted?

        return ServiceResult.error("Registration number is required") if registration_number.blank?

        vehicle = Vehicle.find_by(registration_number: registration_number)
        return ServiceResult.error("Vehicle does not exist") if vehicle.nil?

        return ServiceResult.error("Odometer reading must be a valid non-negative number") if reading.blank? || reading < 0

        previous_log = vehicle.odometer_logs.order(recorded_at: :desc).first

        if previous_log.present? && !confirmed
            if reading < previous_log.reading
                return ServiceResult.needs_confirmation(
                    "New reading (#{reading}) is lower than the last recorded reading (#{previous_log.reading}). " \
                    "Was the odometer reset or replaced? Confirm to proceed."
                )
            end

            elapsed_hours = [(Time.current - previous_log.recorded_at) / 1.hour, MIN_ELAPSED_HOURS].max
            actual_increase = reading - previous_log.reading
            speed = actual_increase / elapsed_hours

            if speed > MAX_KM_PER_HOUR
                return ServiceResult.needs_confirmation(
                    "Reading jumped by #{actual_increase} km in #{elapsed_hours.round(2)} hours " \
                    "(~#{speed.round(1)} km/h), which is unusually high. Confirm this is correct?"
                )
            end
        end

        odometer_log = vehicle.odometer_logs.create(odometer_logger: logged_by, reading: reading, recorded_at: Time.current)
        return ServiceResult.error(odometer_log.errors.full_messages.join(", ")) unless odometer_log.persisted?

        ServiceResult.success(odometer_log)
    end
end
