# AI Governance

ServiceGenie may store a model-written reply only as a draft a person can read. The model does not decide, send, or act. These rules bind every later milestone. M1 has no model integration, no draft records, and no credentials.

This project targets Salesforce Developer Edition only. It does not use Enterprise Edition, a sandbox, a production org, real customer data, or Agentforce.

## Human Approval Required

A person approves or rejects every draft before it can be treated as accepted wording.

- The approver is a Salesforce user working as themselves.
- `AI_Draft__c.Status__c` cannot be `Approved` or `Rejected` unless `Approved_By__c` is that user and `Approved_At__c` is set.
- Guest users, integration users, and automated processes are not approvers.
- The LWC, when it exists, posts the decision to the Apex controller. The component does not set the status with an unauthenticated call.
- Agentforce is not used as the approver and is not part of this project.

M1 does not enforce this in Apex because the controller does not exist yet. The rule is still binding on the milestone that adds the controller.

## No Automatic Sending

Approval records a human decision. It does not deliver a message.

- No code path may insert an `EmailMessage`, send a SingleEmailMessage, or invoke an email alert from a draft status change.
- No auto-response rule, flow, or trigger may send when a lead is routed or a draft is approved.
- No scheduled job may send drafts that are sitting in `Approved`.
- The product has no "send approved drafts" action.

If a later brief asks for send, that work needs its own design. It is not implied by approval.

## No Customer Data

The org and the repository hold synthetic demo data only.

- Do not load, paste, or attach real customer data, production exports, or personal data from a live business.
- Synthetic emails use a reserved example domain such as `example.com`.
- Prompts, when M5 adds them, may include fields already stored on the synthetic Case, Lead, Account, and Contact used in the demo. They may not include attachments, files from outside the demo, or data from another org.
- The model is not trained by this project. Nothing in the design submits a fine-tuning file.
- Logs and test assertions use the same synthetic values. Do not copy a real case into a test fixture.
- `servicegenie/` is the only place later local fixtures may live, and those fixtures must be synthetic.

Salesforce sample data is also out of scope. `config/project-scratch-def.json` sets `hasSampleData` to false so a future scratch org does not preload sample CRM rows. The working org type for this project remains a Developer Edition org, as described in `docs/org_setup.md`.

## No Secrets In Code

Secrets do not belong in source, including "temporary" keys.

- No API keys, bearer tokens, passwords, or private keys in Apex, LWC, scripts, docs, workflows, or JSON.
- No secrets in Named Credential URLs.
- The External Credential holds provider authentication. The Named Credential points at it. M5 documents both in `docs/credential_architecture.md`. They are not deployed, and the secret is not in source.
- Do not use Custom Metadata, Custom Settings, Custom Labels, or Remote Site Settings as a place to store a key.
- `.gitignore` excludes `.env`, key files, and Salesforce CLI auth folders. Do not force-add them.
- Tests mock the HTTP call. They never read a live key.

M1 contains no Named Credential metadata and no callout code. M5 adds the callout class and still does not put a secret or a credential file in source.

## Audit Trail Required

Every draft has a durable history.

- Insert the draft. Do not keep the model response only in a transient UI variable.
- Keep rejected and approved rows. Do not delete them when a newer draft is created.
- Record `Approved_By__c` and `Approved_At__c` on the decision.
- Rely on `CreatedById`, `CreatedDate`, `LastModifiedById`, and `LastModifiedDate`.
- When `AI_Draft__c` is created, turn on field history for `Status__c`.
- `Case.Source_Lead__c` uses Restrict delete so the link from Case to Lead cannot be removed by deleting the lead.
- Close Cases instead of deleting them, so master-detail drafts are not cascaded away.

There is no audit row in the org today because the object is not deployed. The trail starts when the object exists. Do not backfill it with fabricated history.

## AI Draft Only

Model output is a draft record and nothing else.

- The only write that stores model text is an insert or update of `AI_Draft__c.Original_Draft__c` and `AI_Draft__c.Edited_Draft__c`.
- The model does not update Case status, Lead status, Account, or Contact.
- The model does not assign owners, create tasks, or recommend an action that the system then executes.
- Next best actions are out of scope. A draft body is not an action list the platform runs.
- The controller may show the draft. It may not apply it automatically to an email composer send event.

Status values are `Draft`, `Approved`, and `Rejected`. None of those values means "sent". Only `Approved` may continue to a send in a later milestone, and that send is not implemented.

## Governance Checklist for Later Milestones

A change that touches drafts or callouts is incomplete unless it can answer yes to all of these:

1. A person requested the draft.
2. A person approves or rejects it before it is treated as final wording.
3. No message is sent.
4. The data in the prompt is synthetic.
5. The callout uses a Named Credential, and the secret is not in the repo.
6. The draft row, the approver, and the time are stored.
