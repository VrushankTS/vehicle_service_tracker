# Service Due Alerts

## Purpose

The service-due alert workflow identifies services that are approaching or have
passed their due date or odometer target. It creates or updates a pending
`Alert` record so the application can show a reminder to its users.

The current implementation records the notification in the Rails log. It does
not yet send email, SMS, push, or other external notifications.

## Source

- `app/services/due_service_checker.rb`
- `app/services/alert_generator.rb`
- `app/jobs/due_service_check_job.rb`

## Components

| Component | Responsibility |
| --- | --- |
| `DueServiceCheckJob` | Background-job entry point that starts a due-service check. |
| `DueServiceChecker` | Iterates through vehicles and their model-specific service schedules, then determines whether an alert is needed. |
| `AlertGenerator` | Creates a pending alert or updates an existing one, subject to notification-stage and resend rules. |

## Starting a Check

The checker has no input parameters. It evaluates every vehicle in the system.

```ruby
DueServiceChecker.new.call
```

It can also be run through the background job:

```ruby
DueServiceCheckJob.perform_later
```

## Workflow

```text
For each vehicle
  → Load service schedules for the vehicle's bike model
  → Calculate the service's next due date and odometer reading
  → Compare them with today's date and the latest odometer log
  → Determine the highest alert stage
  → Create or update one pending alert for that vehicle and service type
  → Write an alert message to the Rails log
```

## Due Target Calculation

The target depends on whether the vehicle has a previous record for the same
service type.

| Situation | Due odometer | Due date |
| --- | --- | --- |
| Previous service record exists | `last_service.next_due_odometer` | `last_service.next_due_date` |
| No previous service record exists | First odometer reading + `interval_km` | Vehicle purchase date + `interval_months` |

The previous service record is the most recently serviced record for the same
vehicle and service type.

If a vehicle has never had that service and has no odometer logs, the schedule
is skipped because a due odometer target cannot be calculated.

## Alert Stages

The workflow calculates a stage for both the date target and odometer target,
then uses the higher stage.

| Stage | Meaning | Date rule | Odometer rule |
| ---: | --- | --- | --- |
| `0` | Not due | More than 15 days remain | More than 10% of the service interval remains |
| `1` | Upcoming | 15 days or fewer remain | 10% or less of the interval remains |
| `2` | Very soon | 7 days or fewer remain | 3% or less of the interval remains |
| `3` | Due now | Due date is today or earlier | Due odometer reading has been reached or exceeded |

For odometer-based checks, the percentage remaining is calculated as:

```text
(due odometer − current odometer) ÷ service interval in km
```

An odometer stage is `0` if the due odometer or interval is missing, or if the
interval is zero.

## Alert Type

The `alert_type` describes why the current alert was raised.

| Value | Meaning |
| --- | --- |
| `time` | The date-based stage is higher than the odometer-based stage. |
| `km` | The odometer-based stage is higher than the date-based stage. |
| `both` | Both checks reached the same non-zero stage. |

## Pending-Alert and Resend Rules

Only one pending alert is maintained for each vehicle and service type.

When no pending alert exists, the workflow creates one with status `pending`.
When one already exists, it sends a new notification only when one of these
conditions is true:

| Condition | Result |
| --- | --- |
| The newly calculated stage is higher than `last_notified_stage` | Update the existing alert and notify immediately. |
| The stage is unchanged and enough time has passed | Update the existing alert and notify again. |
| The new stage is lower | Do not notify or change the pending alert. |

The resend interval for an unchanged stage is:

| Stage | Resend interval |
| ---: | --- |
| `1` | 7 days |
| `2` | 2 days |
| `3` | 1 day |

When an existing alert is updated, its `alert_type`, `last_notified_stage`, and
`sent_at` timestamp are updated. Its original `due_date` and `due_odometer`
remain unchanged.

## Alert Data

| Field | Description |
| --- | --- |
| `vehicle_id` | Vehicle that requires the service. |
| `service_type_id` | Type of service that is due. |
| `alert_type` | `km`, `time`, or `both`. |
| `due_date` | Calculated due date, if available. |
| `due_odometer` | Calculated due odometer reading, if available. |
| `status` | `pending`, `resolved`, or `dismissed`. New alerts are `pending`. |
| `last_notified_stage` | Last stage for which a notification was issued. |
| `sent_at` | Time at which the latest notification was issued. |

## Notification Behaviour

`AlertGenerator` currently calls `Rails.logger.info` with one of these messages:

| Stage | Log message intent |
| ---: | --- |
| `1` | The vehicle will need the service soon. |
| `2` | The vehicle needs the service very soon. |
| `3` | The vehicle is due for the service now. |

To add a real delivery channel later, replace or extend the private `notify`
method in `AlertGenerator`. The alert creation and resend logic can remain the
same.

## Related Workflows

- `ServiceCompletionService` resolves a linked pending alert by changing its
  status to `resolved` after a service is completed.
- `ServiceSchedule` defines the per-bike-model interval in kilometres and/or
  months used for the calculation.
- `OdometerLogger` and `ServiceCompletionService` create the odometer logs used
  by this workflow.

