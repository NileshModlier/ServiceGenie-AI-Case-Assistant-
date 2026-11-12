# LLM Design

`LlmClient` is the only class that calls the model. `DraftService` builds the prompt from the case context, asks `LlmClient` for text, and stores an `AI_Draft__c` row. The Lightning component never sees the endpoint.

```
Case
↓
Context retrieval
↓
Prompt assembly
↓
Masking
↓
callout:LLM_API
↓
Draft returned
```

No email is sent on any branch.

## complete

`complete(String prompt)` masks the prompt, then sends one POST to `callout:LLM_API/v1/chat/completions`. The body is JSON with the model label `servicegenie-draft` and one user message. Apex sets `Content-Type` only. It does not set `Authorization`. The timeout is 10 seconds. A platform timeout throws `CalloutException`, which `DraftService` turns into "The model request timed out."

## parseResponse

`parseResponse` reads the HTTP status and does not insert a record.

| Status | Result |
| --- | --- |
| 200 with `choices[0].message.content` | Success. The text is the original draft. `model` from the body is the model name. |
| 200 without that text | Failure. No draft row. |
| 429 | "The model is busy. Try again later." No draft row. |
| 500 and other 5xx | "The model could not generate a draft." No draft row. |
| Anything else | "The model request failed." No draft row. |

## maskSensitiveData

Masking runs inside `complete` before `setBody`. Emails become `[email]`. Phone numbers become `[phone]`. Card-like runs of 13 to 19 digits become `[card]`. An 8-digit case number is left as-is. Null and blank input are returned unchanged.

## Draft generation

`DraftService.generateDraft` calls `CaseAssistController.getCaseContext`. A missing case stops before the callout. The prompt uses the case number, subject, status, priority, customer, email, phone, account, and activity summary, plus prompt version `v1`. The insert sets status `Draft`, copies the model text into both Original Draft and Edited Draft, and stores the prompt version and model name. Approver and approval time stay blank. The case is not updated.

## What this class does not do

It does not send email, enqueue work, start a batch, or choose a next best action. The named credential is a name in the callout URL. The secret stays in the org, and this repository does not contain one.
