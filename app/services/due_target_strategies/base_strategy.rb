module DueTargetStrategies
  class BaseStrategy

    def initialize(rule)
      @rule = rule
      @config = rule.rule_config || {}
    end

    def resolve(vehicle:, service_type:, schedule: nil)
      raise NotImplementedError, "#{self.class} must implement resolve"
    end

    private

    attr_reader :rule, :config
  end
end