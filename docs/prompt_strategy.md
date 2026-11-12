# Prompt Strategy

Prompt version `v1` is a fixed instruction plus the case context the agent is already allowed to see. The version label is stored on `AI_Draft__c.Prompt_Version__c`. The prompt text itself is not saved.

## What goes in

`DraftService` reads the case through `CaseAssistController.getCaseContext`, then adds the contact phone with a separate user-mode query. The prompt lines are:

- Prompt version
- Case number, subject, status, and priority
- Customer name, email, and phone
- Account name
- Recent activity summary
- One instruction: write a short reply the agent can edit, and do not send it

Case description, comments, attachments, and files are not included.

## Masking

`LlmClient.complete` masks the assembled text before the request is built. The callout body can contain `[email]`, `[phone]`, and `[card]`. It must not contain the original email address, phone number, or card-like number. The case number stays so the model can refer to the case.

Masking is a guard on the way out. It is not a promise that the org holds real customer data. Demo rows still use `@example.com` and fictional numbers.

## What the model is asked to do

Return reply text. It is not asked to change the case, assign an owner, create a task, or send a message. The Apex parser keeps only the message content. A status other than 200 does not become a draft.

## What a person does next

The stored text is a draft. The agent can edit the edited-draft field and then approve or reject. The original draft stays the model text. Approval does not send the reply. A later send, if a future milestone adds one, can start only from an approved row and still needs a person to send it.
