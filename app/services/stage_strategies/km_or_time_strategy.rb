module StageStrategies
  class KmOrTimeStrategy < BaseStrategy

    def compute_stage(due_km:, current_km:, interval_km:, due_date:)
      date_stage = compute_date_stage(due_date)
      km_stage = compute_km_stage(due_km, current_km, interval_km)

      if date_stage > km_stage
        return { stage: date_stage, alert_type: 'time' }
      elsif km_stage > date_stage
        return { stage: km_stage, alert_type: 'km' }
      else
        return { km_stage, alert_type: 'both'}
      end

    end
  end
end