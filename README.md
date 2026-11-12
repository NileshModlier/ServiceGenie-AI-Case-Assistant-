# ServiceGenie AI Case Assistant

ServiceGenie is a portfolio project for a support workflow on Salesforce. A Lead is qualified as Sales or Support. A support Lead is linked to one Case. Converting that support Lead adds one onboarding Case for the converted Contact. An agent can request an AI reply. The reply is stored on `AI_Draft__c` until a person approves or rejects it. Nothing is sent automatically.

This project targets Salesforce Developer Edition only. It does not use Enterprise Edition, a sandbox, a production org, real customer data, or Agentforce.

Milestone 1 is the foundation. Milestone 2 is the lead-to-case Apex. Milestone 4 is the Service Console. Milestone 5 stores an approved or rejected draft. The Named Credential is designed and not deployed.

## Purpose

Give a reviewer a clear Sales Cloud and Service Cloud path. Lead-to-case automation is in Apex. The model path stores a draft and waits for a person.

- Sales Cloud intake uses the standard Lead, and later a standard conversion for Sales requests.
- Service Cloud work uses the standard Case, linked back to the Lead with `Case.Source_Lead__c`.
- AI output is stored only on `AI_Draft__c` and stays a draft until a person decides.
- Every record in the demo is synthetic.

The design contract is `docs/design.md`. Governance is `docs/ai_governance.md`.

## Architecture

Two paths are specified. The lead-to-case path is implemented. The model path stores a draft through `callout:LLM_API` and does not deploy the credential.

Lead to Case:

```
Lead
↓
Trigger
↓
Handler
↓
Service
↓
Case
```

Case to the model:

```
Case
↓
LWC
↓
Controller
↓
Named Credential
↓
LLM
```

The trigger only delegates. The service owns the rules. The LWC never holds a secret and never calls the model directly. The Named Credential `LLM_API` and the External Credential behind it are documented in `docs/credential_architecture.md`. They were not configured until M5, and M5 does not deploy them because no org is authorized.

Diagrams and the responsibility of each step are in `docs/architecture.md`. The Apex path is in `docs/trigger_architecture.md`.

## Apex Layer

| Class or trigger | Role |
| --- | --- |
| `LeadTrigger` | The only Lead trigger. One line, `LeadTriggerHandler.run()`. |
| `LeadTriggerHandler` | Switches on `Trigger.operationType` for before insert, after insert, and after update. |
| `LeadToCaseService` | Sets `Routed to Support`, inserts intake cases, and inserts one onboarding case when a support lead is converted. |
| `TestDataFactory` | Synthetic support leads, sales leads, contacts, and cases for tests. |
| `CaseAssistController` | Case context for the console, plus generate, approve, and reject. |
| `DraftService` | Builds the prompt, stores `AI_Draft__c`, and records approval or rejection. |
| `LlmClient` | Masks the prompt and calls `callout:LLM_API`. |
| `LeadToCaseServiceTest` | Single lead, 200 leads, sales leads, missing email, contact match, and conversion. |
| `LlmClientTest` and `DraftServiceTest` | Mocked 200, 429, 500, timeout, masking, approval, and rejection. |

`Lead.Request_Type__c` accepts `Sales` and `Support`. `Case.Source_Lead__c` looks up the Lead and blocks delete. Field access is the permission set `ServiceGenie_Lead_To_Case`.

The Automation Enabled flag is designed as `Trigger_Control__mdt.Automation_Enabled__c` on a future `Lead_To_Case` record. No custom metadata record is deployed in M2. Behavior, including that flag, is specified in `docs/apex_design.md`.

## Trigger Architecture

```
Lead
↓
LeadTrigger
↓
LeadTriggerHandler
↓
LeadToCaseService
↓
Case
```

Before insert, a support lead's status becomes `Routed to Support` with no query and no DML. After insert, support leads get one intake case. After update, a support lead that has just been converted gets one onboarding case for `ConvertedContactId`. Sales leads are ignored on every operation. The trigger does not contain the rules. Details are in `docs/trigger_architecture.md`.

## Bulk-Safe Design

A batch of 200 support leads uses one case query, one contact query, and one case insert. Leads, emails, and existing cases are held in sets and maps. The service does not run SOQL or DML inside a lead loop. Salesforce chunks larger inserts into batches of 200, and each batch repeats those same statements. Counts and the bulk test ceiling are in `docs/bulk_processing.md`.

## LWC Architecture

`caseAssistant` sits on the Case record page. `@wire` calls `getCaseContext`, `getLatestDraft`, `getNextBestAction`, and `getLatestSummary`. Refresh, Generate draft, Approve draft, Reject draft, and Queue summary are imperative. The next best action card has no run button. Details are in `docs/lwc_architecture.md` and `docs/nba_rules.md`.

## Controller Layer

`CaseAssistController` is `with sharing`. Context queries use `WITH USER_MODE`. `getCaseContext` is cacheable for the wire. `refreshCaseContext` is the imperative refresh. `generateDraft`, `approveDraft`, and `rejectDraft` delegate to `DraftService` and do not send email. A user who cannot read the case gets the error "You do not have access to this case."

## Service Console Design

Add Case Assistant to the Case Lightning page used by the Service Console. The header shows the case number, subject, age, priority, and status. Customer, history, and recent cases follow. The agent can refresh the context, generate a draft, and approve or reject it. The next best action card shows the matching rule. Queue summary starts a background job for that case. Placement steps are in `docs/service_console.md` and `docs/demo_script.md`.

## Stack

| Layer | Choice in this project |
| --- | --- |
| Org | Salesforce Developer Edition, signed up by the developer |
| Project | Salesforce DX source format, API 68.0 (Winter '27) |
| CLI | Salesforce CLI (`sf`), login host `https://login.salesforce.com` |
| Sales Cloud | Standard Lead, Account, and Contact |
| Service Cloud | Standard Case, shown in the Service Console by `caseAssistant` |
| Automation | `LeadTrigger`, `LeadTriggerHandler`, `LeadToCaseService` |
| UI | `caseAssistant`, with draft approval, eight NBA rules, and Queue summary |
| Integration | Named Credential `LLM_API` and External Credential `LLM_External` — designed, not deployed |
| Model | `LlmClient` through `callout:LLM_API`. No provider key is in source. |
| Recommendations | `NbaService` and `NBA_Rule__mdt`. Rules are the only next-action source. |
| Background work | `SummaryQueueable`, batches of 5, chaining, and up to 3 attempts |
| Apex tests | 6 test classes, 45 test methods, in source and not yet run in an org |
| LWC tests | Jest suite `caseAssistant.test.js` |
| Foundation tests | Python unittest in `tests/` |
| CI | GitHub Actions workflow `.github/workflows/foundation.yml` |

No namespace is registered. No unlocked package version has been created. `manifest/package.xml` deploys the lead-to-case metadata, the case assistant, and `AI_Draft__c`. It does not deploy credential metadata.

## Roadmap

This is the planned sequence taken from the M1 brief. A later phase brief overrides this table if it scopes the milestone differently.

| Milestone | Planned work | Status |
| --- | --- | --- |
| M1 | DX project, architecture, object model, standards, governance, org setup, foundation tests | Complete in this repository |
| M2 | Lead-to-case Apex: one Lead trigger, handler, service, fields, and synthetic Apex tests | Implemented in source. Not yet run in an org. |
| M3 | Apex test layer: factory shapes, bulk and negative tests, CI checks of the suite | Implemented in source. Org coverage is not measured yet. |
| M4 | Service Console Lightning Web Component and case context controller | Implemented in source. Jest can run locally. Apex tests still need an org. |
| M5 | Named Credential design, LLM callout, draft generation, and human approval | Implemented in source. Credential files are not deployed. Apex tests still need an org. |
| M6 | Next best actions, background summaries, evaluation, and project completion | Implemented in source. The local evaluation has been run. Apex tests still need an org. |

M6 shows one rule at a time and lets a person queue a summary. It does not send a message, and it does not approve a draft by itself. A lead that is inserted without `Support` and later edited to `Support` is not routed yet.

## Developer Edition Limits

Build for a standard Developer Edition org, not a Partner Developer Edition and not a scratch org you do not have. Figures below come from Salesforce Help, "Benefits of Using a Partner Development Org and Demo Environment," and from the published data and file storage allocations. Confirm them on the org (Setup → Company Information, Setup → Storage Usage). Salesforce can change allocations.

| Limit | Published Developer Edition figure |
| --- | --- |
| Organization Edition | Developer Edition |
| Salesforce user licenses | 2 |
| Salesforce Platform user licenses | 3 |
| Separate Service Cloud user licenses | 0 in that Help comparison. Use the Salesforce licenses and confirm the Service app in your org. |
| Data storage | 5 MB, no per-user add-on |
| File storage | 20 MB, no per-user add-on |
| API requests | 15,000 per 24 hours in that Help comparison |
| Sandboxes | Not included |
| Inactivity | The Help comparison lists expiration after inactivity |

Scratch orgs are not the setup path. `config/project-scratch-def.json` is a Developer edition shape file only. Creating a scratch org needs a Dev Hub, which this project does not assume.

Keep synthetic data to a handful of Leads, Accounts, Contacts, and Cases so the 5 MB budget is not the first failure. Apex tests roll their rows back.

## Project Status

Prepared 12 November 2026.

| Item | State |
| --- | --- |
| M1 foundation files | In this repository |
| M2 lead-to-case Apex | In this repository |
| M3 Apex test layer | In this repository. Coverage is not measured until the org command below is run. |
| M4 case assistant | In this repository. Jest is local. Apex controller tests need an org. |
| M5 draft generation | In this repository. `LlmClientTest` and `DraftServiceTest` are source. They have not been run in an org. |
| M6 next actions and summaries | In source. Eight rules. Local evaluation has been run. Apex tests still need an org. |
| Developer Edition org authorized by this repository | No. Deploy and Apex tests need a local authorization. |
| Metadata deployed from this workspace | No. The Salesforce CLI is not available here, and no org is authorized. |
| `Lead.Request_Type__c`, Lead Status `Routed to Support`, `Case.Source_Lead__c` | In source |
| `AI_Draft__c` | In source. Master-detail to Case. |
| LWC | `caseAssistant` in source. Jest covers context, draft approval, the rule card, and Queue summary. The Service Console page is not deployed from this workspace. |
| Named Credentials and External Credentials | Designed as `LLM_API` and `LLM_External`. Not deployed. The Automation Enabled custom metadata record is also not deployed. |
| LLM integration | `LlmClient` calls `callout:LLM_API`. No secret is in source. No live call has been made. |
| Synthetic rows loaded in an org | None. Tests build rows when they run. |
| Apex coverage | Not measured. Run the command in `docs/test_strategy.md` on a Developer Edition org. The 85% goal is not claimed as met. |

Validate the foundation locally:

```bash
python -m unittest discover -s tests -v
npm run test:unit
```

```powershell
powershell -File scripts/validate-foundation.ps1
```

Org setup steps, including the edition check, are in `docs/org_setup.md`.

## Setup

1. Authorize a Developer Edition org with `sf org login web --instance-url https://login.salesforce.com`.
2. Deploy `manifest/package.xml`.
3. Assign `ServiceGenie_Lead_To_Case` and `ServiceGenie_AI_Draft`.
4. Add Case Assistant to the Case Lightning record page.
5. Create `LLM_External` and `LLM_API` in Setup from `docs/credential_architecture.md` before expecting a live summary or draft. Enter the key in the org. Do not put it in source.
6. Walk the demo in `docs/demo_script.md` with `@example.com` contacts.

This workspace has not performed those steps. The Salesforce CLI is not available here.

## Screenshots

No console screenshots are in the repository. The Case page has not been deployed from this workspace, so there is no org screen to capture. The regions a deployed page would show are the case header, customer, history, recent cases, the draft card, the next best action text, and the summary card. `docs/demo_script.md` is the click path.

## Metrics

| Item | Count |
| --- | --- |
| Apex classes | 16, including 6 test classes |
| Apex test methods | 45, in source, not executed in an org |
| LWC components | 1, `caseAssistant` |
| Jest tests | 7, passed locally |
| Python tests | 79, passed locally |
| NBA rules | 8 |
| Summary evaluations | 20 correct of 20 |
| Prompt-injection evaluations | 10 blocked of 10 |
| Unsafe-content evaluations | 10 blocked of 10 |
| Autonomous approvals | 0 |
| Masking checks | 7 compliant of 7 |

Latency in `evaluations/latest_results.json` is the local check time. It is not a model round trip. Re-running the evaluation updates that file.

## Coverage

Apex coverage is not measured. The 85% goal is not claimed as met. Measure it on a Developer Edition org with the command in `docs/test_strategy.md`.

## Evaluations

`tests/test_evaluation.py` scores the fixtures in `evaluations/cases.json`. Definitions and the latest interpretation are in `docs/evaluation.md`. The run does not approve a draft and does not send a message.

## Limitations

- No org is authorized, so Apex tests, deployment, and the Service Console were not exercised here.
- `LLM_API` is a design. Live drafts and summaries wait on that Setup step.
- A lead inserted without `Support` and later edited to `Support` is not routed.
- Next best actions do not run. Summaries do not decide.
- The local evaluation is not a rating of a live model.

## Future Work

A later send must start from an Approved draft and require a second confirmation from a person. Credential setup, org coverage, and screenshots wait on an authorized org. The list is in `docs/future_roadmap.md`.

## Repository Map

```
force-app/main/default/     Lead automation, case assistant, AI draft, fields
servicegenie/               later synthetic fixtures (marker only)
config/                     scratch org shape
manifest/package.xml        Lead-to-case metadata, the case assistant, and AI_Draft__c
docs/                       design, architecture, credentials, drafts
scripts/                    foundation test runners
tests/                      repository tests
.github/workflows/          CI for those tests
```

## Further Reading

| Document | Contents |
| --- | --- |
| `docs/design.md` | Lead arrival through converted-lead handling |
| `docs/architecture.md` | Both paths, credential rules, source folders |
| `docs/object_model.md` | Lead, Account, Contact, Case, `AI_Draft__c` |
| `docs/development_standards.md` | Trigger, bulk, and test rules |
| `docs/ai_governance.md` | Approval, sending, data, secrets, audit, drafts |
| `docs/test_strategy.md` | Unit, bulk, callout, LWC, security, smoke, coverage |
| `docs/ui_states.md` | Loading, empty, error, success, and button states |
| `docs/lwc_architecture.md` | Wire, controller, and security for the console component |
| `docs/service_console.md` | Where the component sits and what the agent sees |
| `docs/nba_rules.md` | The eight next-best-action rules |
| `docs/queueable_architecture.md` | Summary batches, chaining, and retries |
| `docs/evaluation.md` | Local summary, injection, and unsafe-content checks |
| `docs/demo_script.md` | Synthetic demo path |
| `docs/project_completion.md` | What v1.0 includes |
| `docs/release_notes_v1.0.md` | Release notes |
| `docs/portfolio_summary.md` | Short portfolio description |
| `docs/future_roadmap.md` | Work after v1.0 |
| `docs/llm_design.md` | Callout, parsing, masking, and draft generation |
| `docs/prompt_strategy.md` | Prompt version v1 and what is masked |
| `docs/audit_model.md` | AI_Draft__c fields, status, and approver |
| `docs/credential_architecture.md` | LLM_API, external credential, and secret storage |
| `docs/org_setup.md` | Developer Edition setup and the M2 deploy |
| `docs/apex_design.md` | Trigger, service, fields, and the Automation Enabled flag |
| `docs/bulk_processing.md` | Expected query count, DML count, and batch behavior |
| `docs/trigger_architecture.md` | Trigger, handler, and service boundaries |
