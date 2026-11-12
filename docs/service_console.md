# Service Console

`caseAssistant` is the agent view for one Case. Add it to the Case record page used by the Service Console. The repository does not replace the org's console app and does not deploy a named credential.

This project targets Salesforce Developer Edition only. It does not use Enterprise Edition, a sandbox, a production org, real customer data, or Agentforce.

## Placement

1. Deploy `manifest/package.xml` to the Developer Edition org.
2. Open the Case Lightning record page that the Service Console uses.
3. Add the Case Assistant component to the page.
4. Save and activate the page for the app the agent uses.

The component's targets are `lightning__RecordPage` for Case and `lightning__AppPage`. On a record page, `recordId` is the open case. On an app page there is no record id, so the component shows the empty state.

## What the agent sees

| Region | Source |
| --- | --- |
| Header | Case number and subject |
| Case age | Created date, calculated in the component |
| Priority | Case priority |
| Status | Case status |
| Customer | Contact name and email, plus account name |
| History | Recent activity summary |
| Recent cases | Other cases for the same contact or account |
| Agent workspace | Refresh context |
| AI draft | Generate draft creates an `AI_Draft__c` row. Approve draft and Reject draft record a decision. Neither sends a message. |
| Next best actions | The first matching `NBA_Rule__mdt` rule. The card shows the rule name, reason, and action text. It does not run the action. |
| Summary | Latest summary, model name, and Queue summary. The job does not approve a draft or send a message. |

Refresh calls `CaseAssistController.refreshCaseContext`. It reloads the same fields. It does not change the case, create a draft, or send a message.

## Data the controller will not return

The SOQL lists are the contract. They are Case number, subject, status, priority, created date, and the contact and account ids; contact name and email; account name; recent case number, subject, status, and created date; task subject and status. A field that is not in those lists is not sent to the component.

If the running user cannot read one of those fields, Salesforce raises a query exception in user mode. The component shows the error state instead of a partial record.

## Synthetic use

Open a case created from the lead-to-case path, or a case entered by hand with an `@example.com` contact. The page shows that synthetic context only. Do not paste a real customer's case into the org for a demo.
