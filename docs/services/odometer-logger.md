# Odometer Logging

## Purpose

The odometer logging workflow records a vehicle's current odometer reading. Every due-service calculation depends on having an accurate, chronological history of these readings, so the workflow includes checks for two kinds of suspicious input: a reading lower than the last recorded one, and a reading that implies an implausible speed since the last entry. Both checks can be bypassed with an explicit confirmation once a human has reviewed them.

## Source

- ```app/services/odometer_logger.rb```


## Components

| Component | Responsibility |
| ----------- | ----------- |
| ```OdometerLogger``` | Validates input, checks the new reading against the vehicle's last recorded reading, and creates an OdometerLog entry. |


## Starting a Log Entry

```ruby
OdometerLogger.new(
    regn_no: "KA01AB1234",
    reading: 15420,
    logged_by: current_user
).call
```

If the reading triggers an anomaly check, the caller re-submits the same request with ```confirmed: true```:

```ruby
OdometerLogger.new(
    regn_no: "KA01AB1234",
    reading: 15420,
    logged_by: current_user,
    confirmed: true
).call
```

## Workflow

```
Validate logging user, registration number, and odometer reading
  → Find the vehicle's most recent OdometerLog entry
  → If a previous entry exists and the request is not confirmed:
      → Reject with a confirmation request if the new reading is lower
      → Reject with a confirmation request if the implied speed since the
        last entry exceeds the allowed maximum
  → Create the OdometerLog entry
  → Return the created entry on success
```


## Validations
| Check | Failure message |
| ----------- | ----------- |
| ```logged_by``` missing | "Logging user is required" |
| ```logged_by``` is not a persisted ```User``` | "Logging user doesn't exist" |
| ```registration_number``` missing | "Registration number is required" |
| ```Vehicle``` not found | "Vehicle does not exist" |
| ```reading``` missing or negative | "Odometer reading must be a valid non-negative number" |


## Anomaly Checks

Both checks only run when a previous log entry exists and ```confirmed``` is ```false```. Passing ```confirmed: true``` skips both checks entirely and logs the reading as given.

### Lower Reading (Possible Reset)

If the new reading is lower than the last recorded reading, the workflow returns a ```needs_confirmation``` result rather than an error. This covers cases such as an odometer being replaced or reset after a repair.

### Implausible Jump

If the new reading is not lower, the workflow calculates the implied average speed since the last entry:
```
elapsed_hours = time since the last entry, floored at a fraction of a second to avoid division by zero
speed         = (new reading − previous reading) ÷ elapsed_hours
```

If ```speed``` exceeds ```MAX_KM_PER_HOUR``` (100 km/h), the workflow returns a ```needs_confirmation``` result describing the jump and the implied speed.

The elapsed-time floor is intentionally very small. A larger floor (such as one hour) would mask short-interval anomalies — for example, a 100 km jump recorded five minutes after the previous entry would otherwise appear survivable at an inflated one-hour baseline.

## Confirmation Flow

```needs_confirmation``` is a distinct result status, separate from error. A caller should treat it as a prompt for human judgment rather than a failure: show the returned message, and if the person confirms, repeat the same request with ```confirmed: true```. No separate endpoint or method is needed for the confirmation step — it is the same request, resent with one additional flag.

## Result Data

On success, the result's data is the created ```OdometerLog``` record.

| Field | Description | 
| ----------- | ----------- |
| ```vehicle_id``` | The vehicle this reading belongs to. |
| ```logged_by``` | The user who recorded the reading. |
| ```reading``` | The odometer reading, in kilometres. |
| ```recorded_at``` | Timestamp of the log entry. |


## Related Workflows
- ```VehicleRegistrar``` creates the first ```OdometerLog``` entry for a vehicle at registration time, using the same table but without running these anomaly checks.
- ```ServiceCompletionService``` performs the same two anomaly checks internally before recording the odometer reading taken at service time.
- ```DueServiceChecker``` reads the vehicle's most recent ```OdometerLog``` entry to determine the current odometer reading for due-service comparisons.