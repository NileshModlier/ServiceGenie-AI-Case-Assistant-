# Development Standards

These rules apply to every milestone that adds Apex, triggers, or tests. M2 is the first Apex in the repository. Coverage stays unclaimed until a Developer Edition org runs the suite.

This project targets Salesforce Developer Edition only. It does not use Enterprise Edition, a sandbox, a production org, real customer data, or Agentforce.

Permission sets are preferred over edits to standard profiles. When custom fields arrive, access goes in `force-app/main/default/permissionsets/`.

## One Trigger Per Object

Each object has at most one trigger. The Lead path uses one Lead trigger. A later Case path uses one Case trigger. A second trigger on the same object is a defect even if it is empty.

The trigger file delegates. It does not query, update, or decide Sales versus Support.

Lead names below are implemented in M2. The Case trigger is still unbuilt.

| Object | Trigger | Handler | Service |
| --- | --- | --- | --- |
| Lead | `LeadTrigger` | `LeadTriggerHandler` | `LeadToCaseService` |
| Case | `CaseTrigger` only if a later milestone needs one | `CaseTriggerHandler` | A case service with a single responsibility |

`AI_Draft__c` logic lives in a controller or a draft service called by that controller, not in a second hidden trigger, unless a milestone brief adds a trigger and then that trigger is the only one on the object.

## Bulk Safe

Triggers receive up to 200 records. Every handler and service accepts lists, not a single record.

- Build sets of Ids, then query once.
- Use maps keyed by Id for parent and child matching.
- DML receives a list.
- A bulk test of 200 support leads is `LeadToCaseServiceTest.bulkSupportLeadsCreateTwoHundredCases`. The mixed 200-lead test is `mixedBulkInsertOfTwoHundredLeads`.
- No hardcoded record Ids.

Helper methods that take one SObject are allowed only when the caller loops in memory over a list that was already queried and the helper performs no SOQL and no DML.

## No SOQL In Loops

SOQL belongs outside loops. Query the leads in the trigger batch, then query existing Cases for those lead Ids in one query filtered by `Source_Lead__c`. Match rows in memory.

Do not query inside `for`, `while`, or `do`. Do not query inside a trigger-handler method that itself runs once per record.

## No DML In Loops

Accumulate Cases to insert and records to update. Perform one `insert` and one `update` per object per transaction unless a real partial-success requirement is documented.

The lead-to-case service inserts the new Case list once. It does not insert inside the lead loop. It does not use email DML.

## Trigger Handler Pattern

The runtime order is fixed:

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

| Layer | Allowed work |
| --- | --- |
| Trigger | Read trigger context. Call one handler method. No SOQL. No DML. No `if` on `Request_Type__c`. |
| Handler | One class per object trigger. Methods take the batch (`beforeInsert`, `afterInsert`, `beforeUpdate`, `afterUpdate`) and the new and old lists. Filter the batch. Call the service once. No business rules beyond filtering. |
| Service | Rules, the single set of queries, and the single set of DML. Public methods take lists. |

The handler is the only class the trigger calls. Tests call the service with synthetic lists so the rule can be tested without relying on trigger order. Trigger tests still fire the trigger with `insert` and `update` of synthetic leads.

Classes that enforce sharing use `with sharing`. A later security test runs as a user who should not see another owner's Case.

## No SeeAllData=true

Tests create the synthetic rows they need. `SeeAllData=true` is forbidden, including on a single method. The platform default is isolated test data. Do not override it.

Do not depend on org data, standard price book rows that were not inserted in the test, or preloaded Accounts. `@TestSetup` methods insert synthetic leads, accounts, contacts, and cases for that test class.

Callout tests use `HttpCalloutMock` and `Test.setMock`. They do not use live credentials or `SeeAllData=true` to find a Named Credential row. The credential design is in `docs/credential_architecture.md`. The credential files are not deployed.

## Minimum 85% Coverage Goal

The coverage goal for project Apex is 85% line coverage, measured in the Developer Edition org that runs the suite. Salesforce may require 75% to deploy; this project aims higher than that floor.

The goal is met only when:

- `sf apex run test --code-coverage --result-format human` reports at least 85% for the project classes.
- Bulk tests of 200 records are included, not only single-record tests.
- Negative tests are included: sales leads create no case, a second pass creates no duplicate, a user without access cannot approve.

M2 includes the lead-to-case classes and `LeadToCaseServiceTest`. This goal is not claimed as achieved until `sf apex run test --code-coverage` is run in a Developer Edition org. A class without a test class is not done.

Use the `Assert` class for new tests.

## Secrets and Callouts

No passwords, tokens, keys, or connection strings in Apex, LWC, JSON, or scripts. Authentication for the later model call lives in an External Credential referenced by a Named Credential. That setup is M5.

Do not commit `.env` files. `.gitignore` already excludes them.

## What M1 Must Not Add

Triggers, classes, LWC, flows, named credentials, and external credentials are out of scope until their milestone. The empty folders under `force-app/main/default/` are placeholders, not a start on that code.
