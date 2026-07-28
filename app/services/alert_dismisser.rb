class AlertDismisser
  attr_reader :alert_id, :dismissed_by

  def initialize(alert_id: nil, dismissed_by: nil)
    @alert_id = alert_id
    @dismissed_by = dismissed_by
  end

  def call
    
    return ServiceResult.error("Dismissing user is required") if dismissed_by.blank?
    return ServiceResult.error("Dismissing user does not exist") unless dismissed_by.is_a?(User) && dismissed_by.persisted?

    return ServiceResult.error("Alert is required") if alert_id.blank?
    
    alert = Alert.find_by(id: alert_id)
    return ServiceResult.error("Alert does not exist") if alert.nil?
    
    return ServiceResult.error("Alert is not in pending state") unless alert.status == 'pending'

    if alert.update(status: 'dismissed', dismisser: dismissed_by)
      return ServiceResult.success(alert)
    else
      return ServiceResult.error(alert.errors.full_messages.join(", "))
    end

  end
end