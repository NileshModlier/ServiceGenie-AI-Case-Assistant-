# Test Strategy

Tests prove the lead-to-case rules, the approval rules, and the callout boundary with synthetic data. The repository checks live in `tests/`. The Apex checks live in `LeadToCaseServiceTest`. Neither suite calls a model.

This project targets Salesforce Developer Edition only. It does not use Enterprise Edition, a sandbox, a production org, real customer data, or Agentforce.

Apex tests ship in the same milestone as the Apex they cover. M2 adds `LeadToCaseServiceTest`. A coverage percentage is reported only after that class runs in a Developer Edition org.

## Unit Tests

Unit tests call a service or controller method with synthetic lists built in the test.

- Assert that a Support lead is eligible for one Case and a Sales lead is not.
- Assert that a blank `Request_Type__c` is not routable.
- Assert that an approved draft still has no send side effect. The method under test returns the draft record and does not construct an email.
- Use the `Assert` class.
- Do not use `SeeAllData=true`.

`LeadToCaseServiceTest` covers the lead-to-case rules with synthetic leads from `TestDataFactory`. The factory builds support leads, sales leads, unqualified leads, mixed batches, contacts, cases, and converted leads. `tests/test_apex_layer.py` checks that those methods exist and that the lead-to-case Apex does not use `SeeAllData=true`, callouts, credentials, or `AI_Draft__c`.

## Bulk Tests

Every trigger and service ships with a 200-record test.

- Insert or update 200 synthetic support leads in one transaction and assert 200 Cases, each with `Source_Lead__c` set.
- Mix sales and support leads in one transaction and assert cases exist only for support.
- Run the operation twice and assert the Case count does not change the second time.
- Governor-limit failure is a test failure. The implementation must stay on the bulk rules in `docs/development_standards.md`: no SOQL in loops, no DML in loops.

`bulkSupportLeadsCreateTwoHundredCases` inserts 200 synthetic support leads and records the queries used and the DML statements used. `mixedBulkInsertOfTwoHundredLeads` inserts 120 support leads and 80 sales leads and records the same limits. `duplicatePassDoesNotCreateAnotherCase` runs the service a second time and asserts the case count does not change.

## Callout Tests

Callout tests use `HttpCalloutMock` and `Test.setMock`. They never reach a network and never read a secret.

- Mock a successful model response and assert one `AI_Draft__c` row in status `Draft` with the mocked body.
- Mock a non-success status and assert no draft body is stored, and no email is sent.
- Assert the request endpoint is a Named Credential callout (`callout:LLM_API`), not an absolute URL with a key.
- `LlmClientTest` and `DraftServiceTest` cover 200, 429, 500, timeout, masking, approval, and rejection. Do not point tests at a live provider.

## LWC Tests

The Case review component, when a later milestone adds it, uses Jest tests next to the bundle.

- Render a draft in `Draft` status and assert the approve and reject actions are present.
- Assert the component does not contain an endpoint, token, or provider key.
- Assert a successful approve action calls the Apex controller and shows the returned status.
- Assert the template has no send button.

M1 has no Lightning Web Component and no Jest config. Do not add a placeholder bundle to host an empty test.

## Security Tests

Security tests run as a user who is not the system administrator.

- A user who cannot read a Case cannot read its drafts once `AI_Draft__c` is a master-detail child.
- A user who can read but not edit cannot move `Status__c` to `Approved`.
- Service classes use `with sharing`.
- Field access for `Request_Type__c`, `Source_Lead__c`, and the draft fields is granted with a permission set, then asserted with that user.
- Tests do not use `SeeAllData=true` to borrow an existing user. Create a synthetic user with a profile or permission set the test controls, within Developer Edition license limits.

M1 deploys no profiles, permission sets, or sharing rules. These tests start when the fields and classes exist.

## Smoke Tests

Smoke tests check that the foundation and, later, the org path still hold together.

M1 smoke is local and does not need an org:

```bash
python -m unittest discover -s tests -v
```

On Windows:

```powershell
powershell -File scripts/validate-foundation.ps1
```

The smoke checks document presence, architecture presence, object model coverage, and development rules. It also fails if `force-app` contains Apex, LWC, or credential metadata.

A later org smoke, run by a person against their own Developer Edition org, is limited to:

1. Confirm Organization Edition is Developer Edition.
2. Deploy the milestone's source.
3. Insert one synthetic support lead and confirm one Case.
4. Confirm no email was sent.

That org smoke is not part of M1. This repository does not store an org alias as proof that it was run.

## Coverage Reporting

The coverage goal is the Minimum 85% Coverage Goal in `docs/development_standards.md`. Report it from the Developer Edition org under test:

```bash
sf apex run test --code-coverage --result-format human --wait 30
```

Read the org-wide figure and the per-class figure. A green deploy at Salesforce's 75% floor does not meet this project's goal.

How to report:

| Milestone | What to publish |
| --- | --- |
| M1 | Output of `python -m unittest discover -s tests -v`. |
| M2 and M3 | `sf apex run test --tests LeadToCaseServiceTest --code-coverage --result-format human --wait 30` in a Developer Edition org. Publish the org-wide percentage and the percentages for `LeadTrigger`, `LeadTriggerHandler`, and `LeadToCaseService`. Do not invent the percentage before that run. |
| Later milestones | The same command, plus the callout and security tests when those classes exist. |

Do not paste coverage from a different org and do not invent a percentage. CI in `.github/workflows/foundation.yml` runs the repository checks, including `tests/test_apex_layer.py`. It does not log in with a Salesforce secret, so it does not publish an Apex coverage percentage.

## Traceability

| Rule | Where it is tested |
| --- | --- |
| Support lead creates one Case | `LeadToCaseServiceTest.singleSupportLeadCreatesOneCase` |
| 200 support leads | `LeadToCaseServiceTest.bulkSupportLeadsCreateTwoHundredCases` |
| Sales lead creates no Case | `LeadToCaseServiceTest.salesLeadsAreIgnored` |
| Lead without email | `LeadToCaseServiceTest.supportLeadWithoutEmailCreatesUnlinkedCase` |
| Existing contact | `LeadToCaseServiceTest.supportLeadMatchesExistingContact` |
| Converted support lead | `LeadToCaseServiceTest.convertedSupportLeadCreatesOnboardingCase` |
| Mixed batch | `mixedBatchCreatesCasesOnlyForSupport` and `mixedBulkInsertOfTwoHundredLeads` |
| Duplicate prevention | `duplicatePassDoesNotCreateAnotherCase` and `onboardingRecordDoesNotBlockIntakeCase` |
| Empty inputs and null handling | `emptyInputsDoNotCreateCases` and `nullInputsHaveZeroSideEffects` |
| Blank request type | `blankRequestTypeHasZeroSideEffects` |
| No `SeeAllData=true` | `tests/test_apex_layer.py` scans the Apex |
| No secrets in source | M1 scope guard plus review |
| Draft is not sent | Later controller unit test |
| Person must approve | Later security and unit tests |
| Docs stay present | `tests/test_foundation.py` |
