class VehicleRegistrar
    attr_reader :model_id, :registration_number, :reading, :purchase_date, :registered_by

    def initialize(model_id:, regn_no:, reading:, purchase_date:, registered_by:)
        @model_id = model_id
        @registration_number = regn_no
        @reading = reading
        @purchase_date = purchase_date
        @registered_by = registered_by
    end

    def call
        return ServiceResult.error("Bike model is required") if model_id.blank?
        bike_model = BikeModel.find_by(id: model_id)
        return ServiceResult.error("Unknown vehicle model") if bike_model.nil?

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
                registration_number: registration_number,
                purchase_date: purchase_date
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