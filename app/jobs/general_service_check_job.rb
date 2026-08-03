class GeneralServiceCheckJob < ApplicationJob
  queue_as :default

  def perform
    GeneralServiceChecker.new.call
  end
end