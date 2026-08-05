class StageStrategyRegistry
  STRATEGIES = {
    "km_or_time"              => StageStrategies::KmOrTimeStrictStrategy,
    "km_or_time_strict"       => StageStrategies::KmOrTimeStrictStrategy,
    "km_only"                 => StageStrategies::KmOnlyStrategy,
    "km_only_conservative"    => StageStrategies::KmOnlyConversativeStrategy
  }.freeze

  def self.resolve(strategy_key)
    STRATEGIES.fetch(strategy_key) { raise "Unknown stage strategy_key: #{strategy_key.inspect}" }
  end
end