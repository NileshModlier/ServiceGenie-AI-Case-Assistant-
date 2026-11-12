# Queueable Architecture

`SummaryQueueable` implements `Queueable` and `Database.AllowsCallouts`. A person starts it from the Queue summary button, which calls `CaseAssistController.queueSummary` for the open case. Nothing on a trigger, schedule, or draft approval starts it.

## What one job does

1. Take at most 5 case ids, and never more than the remaining callout room.
2. `SummaryService.summarize` reads those cases in one query, calls `LlmClient.complete` once per case, and updates only `Latest_Summary__c`, `Summary_Timestamp__c`, and `Summary_Model_Name__c`.
3. If ids remain, or a callout failed and the attempt is below 3, the job enqueues one next job. A queueable can chain once.
4. A blocked prompt or a blocked model reply is not stored and is not retried. A 500, an empty body, or a timeout is retried until the third attempt.

Urgent selection for a future explicit admin call is `SummaryService.urgentIds`: open cases whose priority is High or whose status is Escalated, capped at 50. The console button queues the current case only. Neither path approves a draft, changes case status, or sends email.

## Stored summary

The summary is information for the agent. `SafetyFilter` blocks prompt injection and unsafe requests before storage. `LlmClient.maskSensitiveData` runs on the way out and again on the text that is saved. The model name stored with the summary is the label from the response, or `servicegenie-draft`.

The named credential is still `callout:LLM_API`. It is not deployed. Without that org setup, the job fails the callout, retries, and then stops with no summary row.
