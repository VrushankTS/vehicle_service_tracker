module StageStrategies
  class BaseStrategy
    THRESHOLDS = Rails.application.config_for(:alert_thresholds)

    def initialize(rule_config)
      @config = rule_config || {}
    end

    def compute_stage(due_km:, current_km:, interval_km:, due_date: nil)
      raise NotImplementedError, "#{self.class} must implement compute_stage"
    end

    private

    attr_reader :config

    def compute_date_stage(due_date)
      return 0 if due_date.blank?
      days_remaining = (due_date - Date.current).to_i

      return 3 if days_remaining <= 0
      return 2 if days_remaining <= THRESHOLDS.dig(:date, :close_days)
      return 1 if days_remaining <= THRESHOLDS.dig(:date, :early_days)

      0
    end

    def compute_km_stage(due_km, current_km, interval_km)
      return 0 if due_km.blank? || interval_km.blank? || interval_km==0

      km_remaining = due_km - current_km
      percentage_remaining = km_remaining.to_f / interval_km

      return 3 if percentage_remaining <= 0
      return 2 if percentage_remaining <= THRESHOLDS.dig(:km, :close_percent)
      return 1 if percentage_remaining <= THRESHOLDS.dig(:km, :early_percent)

      0
    end
  end
end