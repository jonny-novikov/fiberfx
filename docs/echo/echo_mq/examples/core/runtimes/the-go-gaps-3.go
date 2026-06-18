// queue_impl.go ~102 — WRITE the hash field as "atm"
"atm": job.AttemptsMade,

// script_runner.go ~160 — READ the hash field "atm" back
if attemptsMade, ok := data["atm"]; ok {
  fmt.Sscanf(attemptsMade, "%d", &job.AttemptsMade)
}
