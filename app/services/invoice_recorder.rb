class InvoiceRecorder
    attr_reader :service_record_id, :invoice_number, :amount, :issued_at, :file, :items, :uploader

    def initialize(service_record_id: nil, invoice_number: nil, amount: nil, issued_at: nil,
        file: nil, items: [], uploader: nil)
      @service_record_id = service_record_id
      @invoice_number = invoice_number
      @amount = amount
      @issued_at = issued_at
      @file = file
      @items = items || []
      @uploader = uploader
    end

    def call
      return ServiceResult.error("Uploader is required") if uploader.blank?
      return ServiceResult.error("Uploader does not exist") unless uploader.is_a?(User) && uploader.persisted?

      return ServiceResult.error("Service record is required") if service_record_id.blank?
      service_record = ServiceRecord.find_by(id: service_record_id)
      return ServiceResult.error("Service record does not exist") if service_record.nil?

      return ServiceResult.error("Invoice number is required") if invoice_number.blank?
      return ServiceResult.error("Invoice number already exists") if Invoice.exists?(invoice_number: invoice_number)

      return ServiceResult.error("Amount should be a valid positive number") if amount.blank? || amount <= 0
      return ServiceResult.error("Issued date must be a valid date not in the future") if issued_at.blank? || issued_at > Date.current

      invoice = nil
      error_message = nil

      ActiveRecord::Base.transaction do
        invoice = Invoice.new(
          vehicle: service_record.vehicle,
          service_record: service_record,
          uploader: uploader,
          invoice_number: invoice_number,
          amount: amount,
          issued_at: issued_at
        )
        invoice.file.attach(file) if file.present?

        unless invoice.save
          error_message = invoice.errors.full_messages.join(", ")
          raise ActiveRecord::Rollback
        end 

        items.each do |item|
          invoice_item = InvoiceItem.create(
              invoice: invoice,
              description: item[:description],
              item_type: item[:item_type],
              amount: item[:amount]
          )

          unless invoice_item.persisted?
              error_message = invoice_item.errors.full_messages.join(", ")
              raise ActiveRecord::Rollback
          end
        end
      end

      if invoice&.persisted?
        ServiceResult.success(invoice)
      else
        ServiceResult.error(error_message || "Could not create invoice")
      end
  end
end