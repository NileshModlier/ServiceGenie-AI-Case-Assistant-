# NBA Rules

Next best actions are rules. `NbaService` reads `NBA_Rule__mdt`, returns the first match, and stops. The console shows the rule name, the reason, and the action text. It does not run the action, change the case status, approve a draft, or send a message. The model is not called for this card.

## Match fields

| Field | Match |
| --- | --- |
| Priority | Equals the case priority. Blank matches any priority. |
| Status | Equals the case status. Blank matches any status. |
| Origin | Equals the case origin. Blank matches any origin. |
| Case age | `Minimum_Case_Age_Days__c` matches when the case is older than that many days. `Maximum_Case_Age_Days__c` matches when it is that age or newer. |
| Prior closed case | `Requires_Prior_Closed_Case__c` matches when the same contact has another closed case. |

A closed case does not match a rule whose status is blank. Lower `Sort_Order__c` wins.

## Rules in source

| Sort | Rule name | Match | Action text, in short |
| --- | --- | --- | --- |
| 10 | High Priority New | Priority High, status New | Prepare a draft a person approves. |
| 15 | Escalated + Waiting | Status Escalated | A person reviews the escalation. |
| 25 | Recently Reopened | Status Working, age 30 days or less, prior closed case | A person confirms whether the issue returned. |
| 35 | Customer Waiting | Status Working, origin Email | Draft a reply for a person to approve. |
| 45 | Open > 7 Days | Older than 7 days, and the case is open | A person decides whether to follow up. |
| 55 | Web New | Status New, origin Web | Confirm the web request and draft a response. |
| 65 | Phone High | Priority High, origin Phone | Return the call with a draft a person approves. |
| 80 | Working Case | Status Working | Continue the case. Updates wait for an approved draft. |

"Escalated + Waiting" matches the standard status Escalated. It means a person is waiting to review the escalation. It does not require a separate Waiting status, because this project does not replace the org's case statuses.

"Customer Waiting" matches a working case that arrived by email. "Recently Reopened" matches a working case whose contact already has a closed case. Both are rules over standard fields.
