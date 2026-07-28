# Vehicle Registration


## Purpose

The vehicle registration workflow adds a new vehicle to the fleet and records its starting odometer reading in a single step. Every vehicle must have an initial reading captured at the moment it enters the system, since later due-service calculations rely on it as a fallback baseline when no service history exists yet.

## Source

- ```app/services/vehicle_registrar.rb```


## Components

| Component | Responsibility |
| ----------- | ----------- |
| ```VehicleRegistrar``` | Validates input, creates the ```Vehicle``` record, and creates its first ```OdometerLog``` entry in one transaction. |


##  Starting a Registration

```ruby
VehicleRegistrar.new(
  model_id: bike_model.id,
  regn_no: "KA01AB1234",
  reading: 0,
  purchase_date: Date.new(2026, 1, 15),
  registered_by: current_user
).call
```


## Workflow

```
Validate bike model, registering user, registration number, odometer reading,
and purchase date
  → Reject if the registration number is already in use
  → Start a transaction
    → Create the Vehicle record
    → Create the first OdometerLog record for that vehicle
  → Roll back and return the underlying error if either creation fails
  → Return the created Vehicle on success
```


## Validations

| Check	| Failure message |
| ----------- | ----------- |
| ```model_id``` missing | "Bike model is required" |
| Bike model not found | "Unknown vehicle model" |
| ```registered_by``` missing | "Registering user is required" |
| ```registered_by``` is not a persisted User | "Registering user does not exist" |
| ```registration_number``` missing | "Vehicle registration number is required" |
| ```reading``` missing or negative | "Odometer reading must be a valid non-negative integer" |
| ```purchase_date``` missing or in the future | "Purchase date must be a valid date not in the future" |
| ```registration_number``` already exists | "Vehicle already exists" |

Errors that occur inside the transaction (for example, a validation failure on the ```OdometerLog``` record) are captured from the failing record's ```errors``` and returned as the result message, rather than a generic failure string.


## Atomicity

The ```Vehicle``` and its first ```OdometerLog``` are created together inside a single transaction. If either creation fails, both are rolled back — a vehicle is never left without a starting odometer reading, and an odometer log is never created without a vehicle to attach to.


## Result Data

On success, the result's ```data``` is the created ```Vehicle``` record. The first ```OdometerLog``` is accessible through ```vehicle.odometer_logs.first``` or ```vehicle.odometer_logs.order(:recorded_at).first```.

| Field | Description |
| ----------- | ----------- |
| ```bike_model_id``` | The vehicle's model, used to resolve applicable service schedules. |
| ```registration_number``` | Unique plate/registration identifier. |
| ```purchase_date``` | Used as the time-based fallback baseline for due-service calculation when no service history exists. |


## Related Workflows
- ```OdometerLogger``` handles all odometer readings recorded after the initial one created here.
- ```DueServiceChecker``` uses the vehicle's earliest ```OdometerLog``` and ```purchase_date``` as the due-service baseline until the vehicle's first ```ServiceRecord``` exists.
- ```ServiceSchedule``` defines the per-bike-model service intervals that apply to a vehicle once registered.