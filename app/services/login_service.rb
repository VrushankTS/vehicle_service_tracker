class LoginService
    attr_reader :identifier, :password

    def initialize(identifier:, password:)
        @identifier = identifier&.strip&.downcase
        @password = password
    end

    def call

        return ServiceResult.error("Username or email is required") if identifier.blank?
        return ServiceResult.error("Password is required") if password.blank?

        user = User.find_by(username: identifier) || User.find_by(email: identifier)

        if user.nil? || !user.authenticate(password)
            return ServiceResult.error("Invalid credentials")
        end

        ServiceResult.success(user)
    end
end