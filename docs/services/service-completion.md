# Service Completion


## Purpose

`ServiceCompletionService` records that a vehicle service has been completed.

It:


1. Validates the vehicle, service type, agent, odometer reading, and service schedule.
2. Checks whether the odometer reading looks suspicious.
3. Records a new odometer log.
4. Creates a service record with the next expected service date and odometer reading.
5. Resolves the related pending alert, when an alert is supplied.


## Source

`app/services/service_completion_service.rb`


## Service Class

```ruby
ServiceCompletionService
```


## Initializer

```ruby
ServiceCompletionService.new(
  regn_no:,
  service_type_id:,
  reading:,
  alert_id: nil,
  agent:,
  confirmed: false,
  notes: nil
)
```


## Input Parameters

| Parameter | Required | Description |
| ----------- | ----------- | ----------- |
| `regn_no` | Yes | Vehicle registration number. |
| `service_type_id` | Yes | ID of the completed service type. |
| `reading` | Yes | Odometer reading at the time of service. Must be zero or greater. |
| `agent` | Yes | Persisted `User` who recorded the service. |
| `alert_id` | No | ID of the pending service alert that this completion resolves. |
| `confirmed` | No | Set to true to accept an unusual odometer reading after user confirmation. Default: `false` |
| `notes` | No | Additional notes about the service. |


## Example Usage

```ruby
result = ServiceCompletionService.new(
  regn_no: "KL-07-AB-1234",
  service_type_id: 2,
  reading: 12500,
  alert_id: 8,
  agent: current_user,
  notes: "Engine oil and oil filter replaced."
).call
```


## Result Contract

The service returns a `ServiceResult` object.

| Status | Meaning | Available data |
| ----------- | ----------- | ----------- |
| `:success` | Service completion was recorded. | `ServiceRecord` in `result.data` |
| `:error` | Validation or persistence failed. | Explanation in `result.message` |
| `:needs_confirmation` | Odometer reading appears unusual and requires confirmation. | Explanation in `result.message` |


## Handling the Result

```ruby
case result.status
when :success
  service_record = result.data
when :needs_confirmation
  # Ask the user to confirm, then call the service again with confirmed: true.
when :error
  # Display or return result.message.
end
```


## Validation Rules

The operation fails when:
- The registration number is missing.
- No vehicle exists with the supplied registration number.
- The agent is missing, is not a User, or has not been saved.
- The service type is missing or does not exist.
- The odometer reading is missing or negative.
- No ServiceSchedule exists for the vehicle’s bike model and service type.
- The supplied alert does not exist.
- The supplied alert belongs to another vehicle or service type.
- The supplied alert is not in the pending state.
- The odometer log, service record, or alert update cannot be saved.


## Odometer Confirmation Rules

When a previous odometer log exists and confirmed is false, the service asks for confirmation if either rule applies:
1. The new reading is lower than the previous reading.
2. The calculated vehicle speed between the two readings exceeds ```100 km/h```.

The speed check uses:
```
(new reading − previous reading) ÷ elapsed hours
```

To proceed after the user confirms the reading, call the service again with:
```ruby
confirmed: true
```

## Records Created and Updated

A successful call performs the following changes in one database transaction.

| Record | Action |
| ----------- | ----------- |
| ```Odometer Log``` | Creates a log using the supplied odometer reading and agent. |
| ```ServiceRecord``` | Creates a record of the completed service. |
|```Alert``` | Updates the supplied alert from ```pending``` to ```resolved```, if ```alert_id``` was provided. |

If any operation fails, the transaction is rolled back.


## Next Service Calculation

The next due values are derived from the matching ```ServiceSchedule```.

```
next_due_odometer = service odometer reading + schedule interval_km
next_due_date     = current date + schedule interval_months
```

These values are stored on the created ServiceRecord and later used by the due-service alert process.


## Example Successful Result

```
result.success?
# => true

result.data
# => #<ServiceRecord id: 25, vehicle_id: 4, service_type_id: 2, ...>
```

## Related Components

- ```Vehicle```
- ```ServiceType```
- ```ServiceSchedule```
- ```OdometerLog```
- ```ServiceRecord```
- ```Alert```
- ```ServiceResult```
- ```DueServiceChecker```

