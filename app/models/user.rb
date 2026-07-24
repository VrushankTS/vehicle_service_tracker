class User < ApplicationRecord
    has_secure_password
    validates :username, presence: true, uniqueness: true
    validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

    has_many :odometer_logs, foreign_key: :logged_by, inverse_of: :odometer_logger, dependent: :restrict_with_error
    has_many :service_records, foreign_key: :completed_by, inverse_of: :agent, dependent: :restrict_with_error
    has_many :invoices, foreign_key: :uploaded_by, inverse_of: :uploader, dependent: :restrict_with_error
    has_many :service_reports, foreign_key: :uploaded_by, inverse_of: :uploader, dependent: :restrict_with_error
end
