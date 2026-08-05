module StageStrategies
  class KmOnlyConversativeStrategy < BaseStrategy
    def compute_stage(due_km:, current_km:, interval_km:, due_date:)
      effective_interval_km = config["interval_km"] || interval_km
      
      stage = compute_km_stage(due_km, current_km, effective_interval_km)
      return { stage: stage, alert_type: 'km' }
    end
  end
end
