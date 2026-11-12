# Release Notes v1.0

ServiceGenie AI Case Assistant v1.0 is the portfolio source release. It is a Developer Edition project. It is not an installed package and it has not been deployed from this workspace.

## Added

- Lead trigger, handler, and `LeadToCaseService`, including intake and onboarding cases.
- `caseAssistant` for the Service Console, with case context, history, and recent cases.
- Draft generation through `callout:LLM_API`, masking, and human approve or reject on `AI_Draft__c`.
- Eight next-best-action rules. The console displays the matching rule and does not execute it.
- A queueable summary job with batches of 5, one chain at a time, and up to 3 attempts.
- Local evaluations for summaries, prompt injection, and unsafe content.

## Unchanged limits

- No automatic sending.
- No autonomous approval.
- No autonomous next action.
- Secrets stay out of source. `LLM_API` and `LLM_External` are design only until an org is authorized.
- A lead inserted as Sales or blank, then edited to Support, is still not routed.

## Verification in this workspace

Python repository tests and the Jest suite were run. Apex tests were not run. The 85% coverage goal is not claimed as met.
