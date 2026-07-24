class OdometerLogger
    MAX_KM_PER_HOUR = 100
    attr_reader :registration_number, :reading, :confirmed

    def initialize(regn_no:, reading:, confirmed: false, logged_by:)
        @registration_number = regn_no
        @reading = reading
        @confirmed = confirmed
        @logged_by = logged_by
    end

    def call
        
        return ServiceResult.error("Registration number is required") if @registration_number.blank?

        vehicle = Vehicle.find_by(registration_number: registration_number)
        return ServiceResult.error("Vehicle does not exist") if vehicle.nil?

        return ServiceResult.error("Odometer reading must be a valid non-negative number") if reading.blank? || reading<0
    
        previous_log = vehicle.odometer_logs.order(recorded_at: :desc).first

        if previous_log.present? && !confirmed
            if reading < previous_log.reading 
                return ServiceResult.needs_confirmation(
                    "New reading (#{reading}) is lesser than the last recorded reading (#{previous_log.reading}). " \
                    "Are you sure you want to proceed?"
                )
            end
        end

        elapsed_hours = (1, (Time.current - previous_log.recorded_at) / 1.hour).max
        expected_max_increase = MAX_KM_PER_HOUR * elapsed_hours
        actual_increase = reading - previous_log.reading

        if actual_increase > expected_max_increase
            return ServiceResult.needs_confirmation(
                "Reading jumped by #{actual_increase} km since the last entry (#{elapsed_hours.round(1)} hours ago), " \
                "which is unusually high. Confirm this is correct?"
            )
        end

        odometer_log = vehicle.odometer_logs.create(logged_by: @logged_by, reading: reading, recorded_at: Time.current)
        return ServiceResult.error(odometer_log.errors.full_messages.join(", ")) unless odometer_log.persisted?
        ServiceResult.success(odometer_log)        
    end
    
    private
    
    attr_reader :logged_by
end