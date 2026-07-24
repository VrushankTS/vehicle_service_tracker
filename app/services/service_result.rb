class ServiceResult
    attr_reader :status, :data, :message

    def initialize(status:, data: nil, message: nil)
        @status = status    # :success, :error, :needs_confirmation
        @data = data
        @message = message
    end

    def success?
        status == :success
    end

    def self.success(data)
        new(status: :success, data: data)
    end

    def self.error(message)
        new(status: :error, message: message)
    end

    def self.needs_confirmation(message)
        new(status: :needs_confirmation, message: message)
    end
end