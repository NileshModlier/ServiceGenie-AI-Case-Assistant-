# ServiceGenie Design

ServiceGenie AI Case Assistant is a Salesforce demo that shows how a support request becomes a Case, and how an agent reviews an AI-written draft before anything is approved. The system of record is the Salesforce org. The language model, when a later milestone adds it, only proposes text. A person decides what happens next.

This project targets Salesforce Developer Edition only. It does not use Enterprise Edition, a sandbox, a production org, real customer data, or Agentforce.

## Purpose

Show a portfolio path across Sales Cloud and Service Cloud:

1. A Lead arrives with a request type of Sales or Support.
2. A Sales lead stays on the standard sales path.
3. A Support lead is marked Routed to Support and is linked to one new Case.
4. A later milestone stores an AI draft on that Case.
5. A person approves or rejects the draft. Approval does not send a message.

Milestone 1 writes this contract down. It does not build the automation, the draft object, the console component, or the model call.

## Scope of M1

M1 delivers the Salesforce DX project, the architecture, the object model, development standards, org setup guidance, AI governance, and a test suite that checks those documents.

M1 does not deploy metadata. `manifest/package.xml` lists no types. `force-app/` contains directory markers only. No org was authorized while this repository was created.

## Lead to Case Design

Two custom fields carry the handoff: `Lead.Request_Type__c` and `Case.Source_Lead__c`. They are specified here and are not in source metadata yet.

| API name | Object | Type | Values / target | Rule |
| --- | --- | --- | --- | --- |
| `Request_Type__c` | Lead | Restricted picklist | `Sales`, `Support` | Blank on arrival. A person or a later automation sets it before routing. |
| `Source_Lead__c` | Case | Lookup to Lead | Delete constraint: Restrict | Required for cases born from a lead. Empty for cases created some other way. |

`Request_Type__c` is the only routing input. Lead Source, rating, and industry are not routing inputs.

The Lead Status value `Routed to Support` is a custom status. Its Converted flag stays unchecked. Setting that status does not convert the lead and does not create an Account, Contact, or Opportunity.

### Lead Arrival

A lead enters by manual entry in the Developer Edition org, or later by a Web-to-Lead form that posts synthetic values only. Web-to-Lead is not configured in M1.

On arrival:

- `Request_Type__c` is blank until someone qualifies the request.
- Status is the org's default open status (typically Open - Not Contacted). M1 does not change standard lead statuses.
- The record uses synthetic data only. Names, emails, and companies use reserved example domains such as `example.com`. No customer extract is imported.
- Owner is the creating user. M1 does not create a queue.

The arrival step stores the request. It does not create a Case, convert the lead, or call a model.

### Lead Qualification

Qualification sets `Request_Type__c`.

- `Sales` means the lead stays in Sales Cloud. The later path is standard lead conversion to an Account, Contact, and Opportunity. M1 does not convert leads.
- `Support` means the lead is a service request. It must not become an Opportunity as part of support routing.

A lead with a blank `Request_Type__c` is not routable. Later automation must leave it alone.

Qualification is a business decision. M1 does not add a screen flow, validation rule, or trigger to force it.

### Support Routing

When `Request_Type__c` is `Support`, the lead status becomes `Routed to Support`.

That status means:

- The lead has left the active sales path.
- `IsConverted` remains false.
- The lead is still readable, so the Case can store it in `Source_Lead__c`.
- No email alert, auto-response, or assignment rule is part of this design.

Sales leads never receive the status `Routed to Support`.

M2 adds `Routed to Support` in `standardValueSets/LeadStatus.standardValueSet-meta.xml`. The value is not converted. The file also keeps the usual open, working, converted, and not-converted statuses.

### Case Creation

`LeadToCaseService.createSupportCases` creates the intake Case. Before insert has already set Status to `Routed to Support` for a support lead.

The service creates a Case only when all of the following are true:

- `Request_Type__c` is `Support`.
- The lead has an Id.
- No intake Case already points at that lead through `Source_Lead__c`.

The Case is filled from the lead:

- `Source_Lead__c` is the lead Id.
- `Subject` and `Description` come from the lead's synthetic company, description, and name.
- `Origin` uses the existing standard value `Web`.
- `Status` is New.
- `ContactId` and `AccountId` are set when the lead email matches one existing Contact. Otherwise they stay empty. The service does not create a Contact or an Account.

The operation is idempotent. Running it again for the same lead inserts nothing if an intake Case already exists.

A batch of 200 support leads produces 200 cases, queried and inserted as lists. A sales lead in the same transaction produces no case.

The service does not send email, post to Chatter, or call an external system.

### Converted Lead Handling

Sales and support stay on different paths.

- A Sales lead uses standard lead conversion. Salesforce sets `IsConverted`, locks the lead, and fills `ConvertedAccountId`, `ConvertedContactId`, and `ConvertedOpportunityId`. M2 does not customize that conversion and does not create a Case for a Sales lead.
- Routing does not convert a Support lead. `Routed to Support` is not a converted status. `IsConverted` stays false until a person converts the lead.
- The intake Case created on insert stays in place. `Source_Lead__c` still references the lead after conversion. Conversion does not delete that Case and does not insert a second intake Case.
- When a person converts a Support lead, M2 inserts one onboarding Case for `ConvertedContactId`. A second pass does not insert another onboarding Case. The Apex rules are in `docs/apex_design.md`.
- The automation does not update a lead that is already converted. It reacts only to the update that changes `IsConverted` from false to true.
- Deleting a lead that is referenced by `Source_Lead__c` is blocked by the Restrict delete constraint, so the audit link cannot disappear silently. Converted leads are already protected by Salesforce conversion rules.

Opportunity products, quotes, and campaigns are outside this design.

## Human Approval

Draft text lives on `AI_Draft__c` as a child of the Case. A person marks it approved or rejected. The approved record is still a draft. It is not an `EmailMessage`, and nothing in this design sends it.

The approval rules are written in `docs/ai_governance.md`.

## Out of Scope for M1

- Apex triggers, handlers, services, and tests
- Lead-to-case automation and the custom fields it needs
- `AI_Draft__c` metadata and any draft records
- Lightning Web Components and the Service Console page
- Named Credentials and External Credentials
- LLM callouts, prompts, and next best actions
- Agentforce agents, topics, and actions
- Sample data loads, including Salesforce sample accounts
