class SignupService
    attr_reader :username, :email, :password, :phone

    def initialize(username: nil, email: nil, password: nil, phone: nil)
        @username = username&.strip&.downcase
        @email = email&.strip&.downcase
        @password = password
        @phone = phone
    end

    def call
        return ServiceResult.error("Username is required") if username.blank?
        return ServiceResult.error("A valid email is required") if email.blank? || !valid_email?
        return ServiceResult.error("Password is required") if password.blank?
        return ServiceResult.error("Password doesn't match the requirements") unless valid_password?
        return ServiceResult.error("Username already taken") if User.exists?(username: username)
        return ServiceResult.error("Email already registered") if User.exists?(email: email)

        if phone.present? && !valid_phone?
            return ServiceResult.error("Invalid phone number")
        end

        user = User.create(username: username, email: email, password: password, phone: phone)

        if user.persisted?
            ServiceResult.success(user)
        else
            ServiceResult.error(user.errors.full_messages.join(", "))
        end
    end

    private

    def valid_email?
        email.match?(URI::MailTo::EMAIL_REGEXP)
    end

    def valid_password?
        password.length >= 8
    end

    def valid_phone?
        phone.match?(/\A\d{10}\z/)
    end
end