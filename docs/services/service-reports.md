# Service Reports


## Purpose

The service report workflow attaches a condition report to a completed service — a document (photos, inspection notes, or a scanned form) describing the vehicle's condition after that specific service event. Each service can have at most one report, matching how a single inspection document is produced once per service rather than accumulated over time.


## Source

- ```app/services/service_report_recorder.rb```
- ```app/models/service_report.rb```


## Components

| Component | Responsibility |
| ----------- | ----------- |
| ```ServiceReportRecorder``` | Validates input and attaches a report file to a ```ServiceRecord```. |
| ```ServiceReport``` | Holds the attachment and its file-type/size validations. |


## Starting a Report Upload

```ruby
ServiceReportRecorder.new(
    service_record_id: service_record.id,
    file: uploaded_file,
    uploader: current_user
).call
```


## Workflow

```
Validate uploader and service record
  → Reject if a report already exists for this service record
  → Reject if no file was provided
  → Attach the file to a new ServiceReport
  → Save, running the model's file-type and file-size validations
  → Return the created ServiceReport on success
```


## Validations
| Check	| Failure message |
| ----------- | ----------- |
| ```uploader``` missing | "Uploader is required" |
| ```uploader``` is not a persisted ```User``` | "Uploader does not exist" |
| ```service_record_id``` missing | "Service record is required" |
| Service record not found | "Service record does not exist" |
| A report already exists for this service record | "A report already exists for this service" |
| ```file``` missing | "A file is required" |
| File is not a PDF | "File must be a PDF" |
| File exceeds the size limit | "File must be under 10MB" |

The one-report-per-service rule is enforced both by an explicit existence check in the service (for a clean error message) and by a unique index on ```service_reports.service_record_id``` at the database level.


## File Storage

Files are stored using Active Storage's local disk service. ```ServiceReport``` declares ```has_one_attached``` :file; no separate file-path column is kept on the table, since Active Storage manages blob storage and retrieval internally.

```ruby
report = service_record.service_report
report.file.attached?
report.file.filename.to_s
report.file.byte_size
report.file.download   # raw binary content
```


## Result Data

On success, the result's data is the created ```ServiceReport``` record, with the file already attached.

| Field | Description |
| ----------- | ----------- |
| ```vehicle_id``` | The vehicle the report concerns. |
| ```service_record_id``` | The service this report was produced for. Unique — one report per service. |
| ```uploader``` | The user who uploaded the report. |
| ```uploaded_at``` | Timestamp of the upload. |
| ```file``` | The attached PDF, via Active Storage. |


## Related Workflows
- ```ServiceCompletionService``` creates the ```ServiceRecord``` that a report is later attached to. A report cannot be uploaded until a service record exists.
- ```InvoiceRecorder``` follows the same upload pattern (Active Storage, PDF-only, size-limited) for vendor invoices, but allows multiple invoices per service record rather than one.