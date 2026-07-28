# Invoices


## Purpose

The invoice workflow records a vendor-issued invoice against a completed service. Invoices are uploaded by staff for reference after a vehicle has been serviced externally — the system does not generate invoices or apply charges itself. A service can have multiple invoices (for example, separate bills for parts and labor from different vendors), and each invoice can optionally be broken down into line items for internal cost tracking.


## Source

- ```app/services/invoice_recorder.rb```
- ```app/models/invoice.rb```
- ```app/models/invoice_item.rb```


## Components
| Component | Responsibility |
| ----------- | ----------- |
| ```InvoiceRecorder``` | Validates input, creates the ```Invoice``` record with its attached file, and creates any associated ```InvoiceItem``` records. |
| ```Invoice``` | Holds the file attachment and its file-type/size validations. |
| ```InvoiceItem``` | An optional cost breakdown line belonging to one invoice. |


## Starting an Invoice Upload

```ruby
InvoiceRecorder.new(
    service_record_id: service_record.id,
    invoice_number: "INV-2026-0001",
    amount: 1500,
    issued_at: Date.new(2026, 7, 20),
    file: uploaded_file,
    items: [
        { description: "Oil filter", item_type: "parts", amount: 300 },
        { description: "Labor charge", item_type: "labor", amount: 1200 }
    ],
    uploader: current_user
).call
```

```items``` is optional. If the vendor's invoice states only a single total, ```items``` can be omitted entirely.


## Workflow

```
Validate uploader, service record, invoice number, amount, and issued date
  → Reject if the invoice number is already recorded
  → Start a transaction
    → Build the Invoice, attach the file if provided
    → Save, running the model's file-type and file-size validations
    → Create each InvoiceItem, if any were provided
  → Roll back and return the underlying error if any step fails
  → Return the created Invoice on success
```


## Validations
| Check | Failure message |
| ----------- | ----------- |
| ```uploader``` missing | "Uploader is required" |
| ```uploader``` is not a persisted User | "Uploader does not exist" |
| ```service_record_id``` missing | "Service record is required" |
| Service record not found | "Service record does not exist" |
| ```invoice_number``` missing | "Invoice number is required" |
| ```invoice_number``` already recorded | "Invoice number already exists" |
| amount missing or not positive | "Amount should be a valid positive number" |
| ```issued_at``` missing or in the future | "Issued date must be a valid date not in the future" |
| File is not a PDF | "File must be a PDF" |
| File exceeds the size limit | "File must be under 10MB" |
| An invoice item fails to save (for example, missing amount) | The item's underlying validation error |


## Multiple Invoices per Service

Unlike service reports, ```invoices.service_record_id``` is a plain foreign key, not unique. A single service can have several invoices attached, reflecting that repair costs are often billed by more than one vendor for one visit. ```invoice_number``` remains globally unique across all invoices, since no two vendor invoices should share a number.


## Invoice Items

```InvoiceItem``` records are optional and exist purely for internal cost tracking — nothing in the system requires a vendor invoice to be broken down. Each item has a ```description```, an ```item_type``` (```service```, ```labor```, ```parts```, or ```discount```), and an amount. A discount is recorded as a line item with a negative amount rather than through a separate mechanism.


## Atomicity

The invoice, its file attachment, and all of its invoice items are created inside a single transaction. If any invoice item fails to save, the invoice itself is rolled back as well — an invoice is never left in a partially
itemized state.


## File Storage

Files are stored using Active Storage's local disk service. Invoice declares ```has_one_attached :file```; no separate file-path column is kept on the table.

```ruby
invoice = service_record.invoices.first
invoice.file.attached?
invoice.file.filename.to_s
invoice.file.download
```


## Result Data

On success, the result's ```data``` is the created ```Invoice``` record, with its file attached and its invoice items created.

| Field | Description |
| ----------- | ----------- |
| vehicle_id | The vehicle the invoice concerns. |
| service_record_id | The service this invoice was issued for. Not unique — a service may have several invoices. |
| uploader | The user who recorded the invoice. |
| invoice_number | Globally unique identifier from the vendor's invoice. |
| amount | Total invoice amount. |
| issued_at | Date printed on the physical invoice, not the upload date. |
| invoice_items | Optional cost breakdown lines. |


## Related Workflows
- ```ServiceCompletionService``` creates the ```ServiceRecord``` that an invoice is later attached to. An invoice cannot be uploaded until a service record exists.
- ```ServiceReportRecorder``` follows the same upload pattern (Active Storage, PDF-only, size-limited) for condition reports, but restricts uploads to one per service record rather than allowing several.