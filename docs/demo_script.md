# Demo Script

Use a Developer Edition org and synthetic `@example.com` contacts. Do not paste a real customer's case. The named credential is not in source. Next best actions work without it. A live summary needs `LLM_API` configured in the org, as described in `docs/credential_architecture.md`. Until then, Queue summary fails the callout, retries, and stores nothing.

This project targets Salesforce Developer Edition only. It does not use Enterprise Edition, a sandbox, a production org, real customer data, or Agentforce.

## Setup on the org

1. Deploy `manifest/package.xml`.
2. Assign `ServiceGenie_Lead_To_Case` and `ServiceGenie_AI_Draft`.
3. Add Case Assistant to the Case record page in the Service Console.
4. Create an Account "Example Household", a Contact with email `casey.demo@example.com`, and a Case: subject "Synthetic printer issue", status New, priority High, origin Web.

## What to show

1. Open the case. The header shows the number, subject, age, priority, and status.
2. The next best action card shows rule **High Priority New**, the reason, and the action text. Point out that the card does not have a send button.
3. Generate draft. The original and edited text appear with status Draft. Edit a word if you want.
4. Approve draft. The status becomes Approved. The case status stays New. No email was sent. Reject is the other decision, and a rejected row stays on the case.
5. Queue summary only if the named credential is configured. After the job, refresh the page. The summary, timestamp, and model name appear. The case status is still unchanged.
6. Open a working email case and show **Customer Waiting**. Open a low-priority phone case older than seven days and show **Open > 7 Days**.

## What not to claim

Do not claim a measured Apex coverage percentage. Do not claim the model was called from this workspace. Do not claim a screenshot of a deployed console unless you captured one on the org.
