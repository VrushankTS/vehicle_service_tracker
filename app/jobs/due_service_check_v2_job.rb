class DueServiceCheckV2Job < ApplicationJob
  queue_as :default

  def perform
    DueServiceCheckerV2.new.call
  end
end