# Apex Design

M2 implements lead-to-case automation in Apex. The trigger delegates. The handler selects the operation. `LeadToCaseService` owns the rules. Synthetic tests live in `LeadToCaseServiceTest`. No Lightning Web Component, Named Credential, External Credential, LLM call, `AI_Draft__c` object, or next best action is part of this milestone.

This project targets Salesforce Developer Edition only. It does not use Enterprise Edition, a sandbox, a production org, real customer data, or Agentforce.

## Components

| Piece | Type | Responsibility |
| --- | --- | --- |
| `LeadTrigger` | Trigger, the only one on Lead | Calls `LeadTriggerHandler.run()`. |
| `LeadTriggerHandler` | Apex class | Switches on `Trigger.operationType`. |
| `LeadToCaseService` | Apex class, `with sharing` | Routes support leads and inserts cases in bulk. |
| `TestDataFactory` | Apex test class | Builds synthetic support leads, sales leads, contacts, and cases. |
| `ServiceGenie_Lead_To_Case` | Permission set | Read and edit `Lead.Request_Type__c` and `Case.Source_Lead__c`. |

## Fields

| API name | Implementation |
| --- | --- |
| `Lead.Request_Type__c` | Restricted picklist: `Sales`, `Support`. Not required, so a blank lead is not routed. |
| Lead Status `Routed to Support` | Standard value. `converted` is false. The file also keeps the four usual Developer Edition statuses so a deploy does not drop them. |
| `Case.Source_Lead__c` | Lookup to Lead. Delete constraint Restrict. Relationship name `Cases`. |

Deploying `LeadStatus` replaces the org's lead status list with the values in source. If your Developer Edition org has extra statuses, add those values to `standardValueSets/LeadStatus.standardValueSet-meta.xml` before deploying. Do not remove `Closed - Converted`, and do not mark `Routed to Support` as converted.

## Before Insert

A new lead with `Request_Type__c` = `Support` gets Status `Routed to Support`.

The change is made on `Trigger.new`. There is no SOQL and no DML. Sales leads and leads with a blank request type keep the status the caller set.

This step does not convert the lead. `Routed to Support` is not a converted status. A lead inserted as Sales or blank, and later edited to Support, is not routed by this milestone. M2 handles Support on insert, and conversion on update.

## After Insert

Each support lead in the batch gets one intake case when it does not already have one.

| Case field | Value |
| --- | --- |
| `Source_Lead__c` | The lead Id |
| `Status` | `New` |
| `Origin` | `Web` |
| `Subject` | `Support: ` plus the company, or the last name when the company is blank |
| `Description` | The lead description when it has one, otherwise a synthetic sentence from the lead name and company |
| `ContactId` | The matched contact, or null |
| `AccountId` | That contact's account, or null |

Sales leads are ignored. A support lead with no email still gets a case, with `ContactId` and `AccountId` left null. The service does not create a contact or an account.

### Contact match

When any support lead in the batch has an email, the service runs one contact query:

```sql
SELECT Id, Email, AccountId FROM Contact WHERE Email IN :emails
```

Emails are matched after trim and lowercasing. If several contacts share an email, the contact with the lowest Id is used. Leads in the batch that have a blank email do not add a value to the set. When the set is empty, the contact query is skipped.

## After Update

When a support lead changes from not converted to converted, and `ConvertedContactId` is populated, the service inserts one onboarding case.

| Case field | Value |
| --- | --- |
| `Subject` | `Onboarding: ` plus the lead name |
| `ContactId` | `ConvertedContactId` |
| `AccountId` | `ConvertedAccountId` |
| `Source_Lead__c` | The lead Id |
| `Status` | `New` |
| `Origin` | `Web` |

The intake case from insert stays as it is. Conversion does not clear `Source_Lead__c` and does not insert a second intake case. A sales conversion inserts no case. A support lead that converts without a contact inserts no onboarding case.

The service does not call `Database.convertLead`. A person, or a test, performs the conversion. The automation does not send email.

## Idempotency

Before inserting, the service loads existing cases for the lead Ids in one query and groups them in a map.

- An intake case is any case for that lead whose subject does not start with `Onboarding: `.
- An onboarding case is a case whose subject starts with `Onboarding: `.
- A second pass for the same lead inserts nothing.

## Trigger Control

Purpose: a custom metadata flag so an administrator can pause lead-to-case automation without editing or deploying Apex.

| Item | Planned value |
| --- | --- |
| Custom metadata type | `Trigger_Control__mdt` |
| Checkbox field | `Automation_Enabled__c` |
| Record full name | `Trigger_Control__mdt.Lead_To_Case` |
| Record label | Lead to Case |

Future implementation, when a later change is allowed to add the type and the record:

```apex
Trigger_Control__mdt control = Trigger_Control__mdt.getInstance('Lead_To_Case');
return control == null || control.Automation_Enabled__c;
```

`getInstance` does not add a SOQL query, so the bulk counts in `docs/bulk_processing.md` stay the same. A missing record means the automation stays enabled. Unchecking `Automation_Enabled__c` on that record pauses routing and both case inserts.

No custom metadata record is deployed in M2. The type is not in source either. `LeadToCaseService.isAutomationEnabled` returns true until that record exists.

## Out of Scope

- Lightning Web Components and the Service Console page
- Named Credentials and External Credentials
- LLM callouts and next best actions
- `AI_Draft__c` and any draft rows
- A second Lead trigger, a Case trigger, or a trigger on `AI_Draft__c`
