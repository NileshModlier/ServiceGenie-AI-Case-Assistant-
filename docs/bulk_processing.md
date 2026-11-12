# Bulk Processing

`LeadToCaseService` handles a trigger batch with sets, maps, one contact query at most, one existing-case query, and one case insert. It does not query or insert inside a loop over leads.

Counts below are the automation's own statements. A Developer Edition org that already has lead flows, assignment rules, or duplicate rules can add more. The bulk test allows a small amount of extra org work and fails if the count climbs toward one query or one DML statement per lead.

## Expected Query Count

| Path | Case query | Contact query | Total from this service |
| --- | --- | --- | --- |
| Before insert, any batch | 0 | 0 | 0 |
| After insert, support leads that all have email | 1 | 1 | 2 |
| After insert, support leads with no email | 1 | 0 | 1 |
| After insert, sales leads only | 0 | 0 | 0 |
| After update, newly converted support leads | 1 | 0 | 1 |
| After update, no newly converted support lead | 0 | 0 | 0 |

The contact query is one `Contact` query filtered by `Email IN :emails`. The case query is one `Case` query filtered by `Source_Lead__c IN :leadIds`. Both filters use sets built from the batch. Results are stored in maps: email to contact, and lead Id to the list of cases.

A batch of 200 support leads with email is the same 2 queries as a batch of 1. The 200-lead test records `Limits.getQueries()` and `Limits.getDmlStatements()` for that transaction.

## Expected DML Count

| Path | DML inside the service | DML in the whole test transaction |
| --- | --- | --- |
| Before insert | 0. Status is set on `Trigger.new`. | The caller's lead insert, which is 1 |
| After insert of one or 200 support leads | 1 `insert` of the case list | 2: the lead insert plus the case insert |
| After insert when every support lead already has an intake case | 0 | The caller's lead insert only |
| After update conversion of support leads | 1 `insert` of the onboarding list | The platform conversion, plus 1 case insert |
| Second pass of either insert method | 0 | 0 from the service |

Sales leads add no case DML. A support lead without an email still costs one case insert, not one insert per missing contact.

## Expected Batch Behavior

Salesforce calls the trigger once per chunk of 200 records. Each chunk is one handler call and one service call.

- 1 to 200 support leads in one insert: one chunk, 2 SOQL queries when those leads have email, 1 case insert.
- 400 support leads in one Apex `insert`: the platform runs the trigger twice in that same transaction. Each chunk repeats the 2 queries and the 1 case insert. Query total from this service is 4, not 400.
- Mixed chunks: sales leads are skipped in memory. They do not add a query. The support leads in that chunk still share the one case query, the one contact query, and the one insert.
- The before-insert chunk and the after-insert chunk are the same records. Before insert only writes `Status` in memory. After insert performs the queries and the insert.
- Conversion is a later transaction. Its after-update chunk loads existing cases once, skips leads that are not a new support conversion, and inserts the onboarding list once.
- Re-entering either method for leads that already have the matching case performs the case query and then inserts nothing.

The maps keep the work off the governor ceiling. Matching a contact is a map lookup. Deciding that a lead already has an intake case or an onboarding case is a scan of that lead's short case list, not another query.

## What the Bulk Test Checks

`LeadToCaseServiceTest.bulkSupportLeadsCreateTwoHundredCases` inserts 200 synthetic support leads in one transaction and asserts:

- 200 leads in status `Routed to Support`
- 200 cases in status `New`
- 200 distinct `Source_Lead__c` values
- no contact link, because the test does not create contacts
- at least 2 and at most 10 SOQL queries
- at least 2 and at most 10 DML statements

The expected service numbers for that test are 2 queries and 1 case insert. Together with the test's lead insert, the transaction is 2 DML statements when the org adds no automation of its own. The ceiling of 10 exists so a Developer Edition org with a small amount of existing lead automation does not fail a correct implementation. A query or DML statement inside the lead loop would land near 200 and fail the ceiling.

`LeadToCaseServiceTest.mixedBulkInsertOfTwoHundredLeads` inserts 120 support leads and 80 sales leads, 200 records in one transaction.

| Measure | Queries used | DML statements used | Cases |
| --- | --- | --- | --- |
| Expected when the org adds no automation | 2 | 2 | 120 |
| Asserted ceiling | 10 | 10 | 120 exactly |

The 2 queries are the same case query and contact query. Sales rows are filtered out before those queries, so they do not add a query or a case insert. The 2 DML statements are the lead insert and the one insert of 120 cases. Each support case is status `New`, with `Source_Lead__c` set and `ContactId` and `AccountId` null. Each sales lead stays `Open - Not Contacted` and has no case.
