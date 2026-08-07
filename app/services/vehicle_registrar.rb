class VehicleRegistrar
    attr_reader :model_id, :registration_number, :vehicle_type_id, :reading, :purchase_date, :registered_by

    def initialize(model_id: nil, regn_no: nil, type_id: nil, reading: nil, purchase_date: nil, registered_by: nil)
        @model_id = model_id
        @registration_number = regn_no
        @vehicle_type_id = type_id
        @reading = reading
        @purchase_date = purchase_date
        @registered_by = registered_by
    end

    def call
        return ServiceResult.error("Registering user is required") if registered_by.nil?
        return ServiceResult.error("Registering user doesn't exist") unless registered_by.is_a?(User) && registered_by.persisted?

        return ServiceResult.error("Bike model is required") if model_id.blank?
        bike_model = BikeModel.find_by(id: model_id)
        return ServiceResult.error("Unknown vehicle model") if bike_model.nil?

        return ServiceResult.error("Vehicle type is required") if vehicle_type_id.blank?
        vehicle_type = VehicleType.find_by(id: vehicle_type_id)
        return ServiceResult.error("Unknown vehicle type") if vehicle_type.nil?

        return ServiceResult.error("Vehicle registration number is required") if registration_number.blank?
        return ServiceResult.error("Odometer reading must be a valid non-negative integer") if reading.blank? || reading < 0
        return ServiceResult.error("Purchase date must be a valid date not in the future") if purchase_date.blank? || purchase_date > Date.current

        if Vehicle.exists?(registration_number: registration_number)
            return ServiceResult.error("Vehicle already exists")
        end

        vehicle = nil
        error_message = nil

        ActiveRecord::Base.transaction do
            vehicle = Vehicle.create(
                bike_model: bike_model,
                vehicle_type: vehicle_type,
                registration_number: registration_number,
                purchase_date: purchase_date,
                odometer_reading: reading
            )
            unless vehicle.persisted?
                error_message = vehicle.errors.full_messages.join(", ")
                raise ActiveRecord::Rollback
            end

            odometer_log = OdometerLog.create(
                vehicle: vehicle,
                odometer_logger: registered_by,
                reading: reading,
                recorded_at: Time.current
            )
            unless odometer_log.persisted?
                error_message = odometer_log.errors.full_messages.join(", ")
                raise ActiveRecord::Rollback
            end
        end

        if vehicle.persisted?
            ServiceResult.success(vehicle)
        else
            ServiceResult.error(error_message || "Could not register vehicle")
        end
    end
end