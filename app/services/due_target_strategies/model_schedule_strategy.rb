module DueTargetStrategies
  class ModelScheduleStrategy < BaseStrategy

    def resolve(vehicle:, service_type:, schedule:)
      last_service = vehicle.service_records
                    .where(service_type_id: service_type.id)
                    .order(created_at: :desc)
                    .first

      if last_service
        { due_km: last_service.next_due_odometer, due_date: last_service.next_due_date }
      
      else
        starting_log = vehicle.odometer_logs.order(recorded_at: :asc).first
        return { due_km: nil, due_date: nil } if starting_log.nil?

        effective_interval_km = config["interval_km"] || schedule.interval_km
        effective_interval_months = config["interval_months"] || schedule.interval_months

        { 
          due_km: starting_log.reading + effective_interval_km, 
          due_date: vehicle.purchase_date + effective_interval_months.months 
        }
      end
    end
    
  end
end