class ServiceRuleResolver
  def call(vehicle:, service_type:, domain:)
    candidate_rules = ServiceRule.where(vehicle_type: vehicle.vehicle_type, strategy_domain: domain, active: true)

    # service_type-based conditions checked first, regardless of priority
    service_type_match = candidate_rules.find do |rule|
      next false unless rule.condition.is_a?(Hash) && rule.condition["service_type_name"] == service_type&.name
      cutoff_satisfies?(vehicle, rule.condition)
    end
    
    # service_type_match = candidate_rules.find do |rule|
    #   rule.condition.present? && rule.condition["service_type_name"].present? && 
    #   rule.condition["service_type_name"] == service_type&.name
    # end

    return service_type_match if service_type_match

    # then date-based conditions, tightest cutoff (highest priority) first
    date_match = candidate_rules.where.not(condition: nil)
                .order(priority: :desc)
                .find { |rule| condition_matches?(rule.condition, vehicle, service_type) }
    
    return date_match if date_match

    fallback_rule = candidate_rules.find { |r| r.condition.nil? }
    raise "No applicable service rule..." if fallback_rule.nil?

    fallback_rule
  end

  private

  def condition_matches?(condition, vehicle, service_type)
    if condition.key?("purchase_date_before")
      threshold_date = Date.parse(condition["purchase_date_before"])
      return vehicle.purchase_date < threshold_date
    end
  end

  def cutoff_satisfies?(vehicle, condition)
    cutoff = condition["purchase_date_on_or_after"]
    return true if cutoff.blank?

    vehicle.purchase_date >= Date.parse(cutoff)
  end

end