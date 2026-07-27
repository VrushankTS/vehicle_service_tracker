class ServiceReportRecorder
  attr_reader :service_record_id, :file, :uploader

  def initialize(service_record_id: nil, file: nil, uploader: nil)
    @service_record_id = service_record_id
    @file = file
    @uploader = uploader
  end

  def call
    return ServiceResult.error("Uploader is required") if uploader.blank?
    return ServiceResult.error("Uploader does not exist") unless uploader.is_a?(User) && uploader.persisted?

    return ServiceResult.error("Service record is required") if service_record_id.blank?
    service_record = ServiceRecord.find_by(id: service_record_id)
    return ServiceResult.error("Service record does not exist") if service_record.nil?

    return ServiceResult.error("A report already exists for this service") if ServiceReport.exists?(service_record_id: service_record.id)

    return ServiceResult.error("A file is required") if file.blank?

    service_report = ServiceReport.new(
      vehicle: service_record.vehicle,
      service_record: service_record,
      uploader: uploader,
      uploaded_at: Time.current
    )
    service_report.file.attach(file)

    if service_report.save
      ServiceResult.success(service_report)
    else
      ServiceResult.error(service_report.errors.full_messages.join(", "))
    end
  end
end