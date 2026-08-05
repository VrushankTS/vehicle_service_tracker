class DueTargetStrategyRegistry
  STRATEGIES = {
    "model_schedule"      => DueTargetStrategies::ModelScheduleStrategy,
    "general_milestone"   => DueTargetStrategies::GeneralMilestoneStrategy
  }.freeze

  def self.resolve(strategy_key)
    STRATEGIES.fetch(strategy_key) { raise "Unknown due_target_strategy: #{strategy_key.inspect}" }
  end
end