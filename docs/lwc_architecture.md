# LWC Architecture

`caseAssistant` is the Service Console component. It reads a Case through `CaseAssistController` and renders that context for an agent. It does not call a language model, save an AI draft, or run a next best action.

```
Case
↓
caseAssistant
↓
CaseAssistController
```

The named-credential and model steps in `docs/architecture.md` stay unwired. M5 is the first milestone that may connect them.

## Read path

The component is placed on a Case record page. Salesforce sets `recordId`. A `@wire` to `getCaseContext` passes that id as `caseId`. The method is `cacheable=true`, so the console can reuse the response while the agent stays on the record.

The controller runs `with sharing` and every query uses `WITH USER_MODE`. The wire receives a `CaseContext` wrapper:

| Property | Contents |
| --- | --- |
| `caseRecord` | Id, CaseNumber, Subject, Status, Priority, CreatedDate, ContactId, AccountId |
| `contact` | Id, Name, Email, or null |
| `account` | Id, Name, or null |
| `recentCases` | Up to five other cases for the same contact or account |
| `recentActivitySummary` | A short sentence built from task subject and status |
| `found` | False when there is no id or no visible case |

Case age is calculated in the component from `CreatedDate`. The controller does not add a formula field.

## Action path

Refresh calls `refreshCaseContext` imperatively. Generate draft calls `generateDraft`. Approve draft and Reject draft call `approveDraft` and `rejectDraft`. Queue summary calls `queueSummary`. Those actions are not cacheable. `@wire` also reads `getNextBestAction` and `getLatestSummary`. The next best action card has no run button.

Generate shows the returned draft on the card. Approve and Reject appear only while the status is Draft. Approving records the decision. It does not send a message.

## Security

- Sharing: `with sharing` on the controller. A case the user cannot see is not returned.
- Field security: `WITH USER_MODE` enforces field access on Case, Contact, Account, and Task. A query the user cannot run raises `QueryException`, which the controller turns into `You do not have access to this case.` The task query failure becomes the sentence `Recent activity is not available for this user.`
- Field set: the queries list only the fields drawn on the page. Description, comments, and draft text are not queried.
- The component does not contain a secret, an endpoint, or a callout.

## What the console does not do

- Send a message
- Approve a draft or a summary by itself
- Run a next best action
- Deploy Named Credential or External Credential metadata
