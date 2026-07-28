class DueServiceCheckJob < ApplicationJob
  queue_as :default

  def perform
    DueServiceChecker.new.call
  end
end