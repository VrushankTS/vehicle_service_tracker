# Alerts


## Alert Dismissal

### Purpose

The alert dismissal workflow closes a pending alert without a service being performed — for example, when staff have decided to delay a service, or a vehicle has been taken out of service. It is the second way a pending alert can reach a terminal state, alongside automatic resolution when a service is completed.

### Source
- ```app/services/alert_dismisser.rb```

### Components
| Component	| Responsibility |
| --- | --- |
| ```AlertDismisser``` | Validates input and changes a pending alert's status to dismissed. |

### Starting a Dismissal

```ruby
AlertDismisser.new(
    alert_id: alert.id,
    dismissed_by: current_user
).call
```

### Workflow

```
Validate dismissing user and alert
  → Reject if the alert is not currently pending
  → Update the alert's status to dismissed, recording who dismissed it
  → Return the updated Alert on success
```

### Validations

| Check | Failure message |
| --- | --- |
| ```dismissed_by``` missing | "Dismissing user is required" |
| ```dismissed_by``` is not a persisted ```User``` | "Dismissing user does not exist" |
| ```alert_id``` missing | "Alert is required" |
| Alert not found | "Alert not found" |
| Alert is not currently ```pending``` | "Alert is not in a pending state" |

A dismissed or already-resolved alert cannot be dismissed again — the pending-state check is the same guard used by ```ServiceCompletionService``` before resolving an alert.

### Result Data

On success, the result's ```data``` is the updated ```Alert``` record.

| Field | Description |
| --- | --- |
| ```status``` | Set to dismissed. |
| ```dismissed_by``` | The user who dismissed the alert. |


### Related Workflows
- ```AlertGenerator``` creates and escalates the pending alert that this workflow closes.
- ```ServiceCompletionService``` is the other path to closing a ```pending``` alert — it sets the status to resolved instead, as part of completing the associated service.
