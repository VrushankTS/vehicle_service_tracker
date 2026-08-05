module StageStrategies
  class KmOnlyStrategy < BaseStrategy
    def compute_stage(due_km:, current_km:, interval_km:, due_date:)
      stage = compute_km_stage(due_km, current_km, interval_km)
      return { stage: stage, alert_type: 'km' }
    end
  end
end