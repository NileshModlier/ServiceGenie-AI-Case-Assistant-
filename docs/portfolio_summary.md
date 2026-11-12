# Portfolio Summary

ServiceGenie is a Salesforce Developer Edition portfolio for a support workflow. It shows bulk-safe Apex, a Service Console Lightning Web Component, a human-approved draft, rule-based recommendations, and a background summary that a person starts.

The lead path qualifies Support versus Sales. A support lead gets one intake case. Converting that lead adds one onboarding case. The console reads the case with sharing and user mode. Generate draft calls `LlmClient`, which masks emails, phone numbers, and card-like numbers before `callout:LLM_API`. The reply is an `AI_Draft__c` row until a standard user approves or rejects it. Approval stores the person and the time. It does not send email.

Next best actions are custom metadata rules. The first match supplies the rule name, the reason, and the action text. The agent reads the recommendation. The system does not perform it.

Summaries run in `SummaryQueueable` for a case the agent queues. The job writes the latest summary, the timestamp, and the model name. `SafetyFilter` drops prompt injection and unsafe replies. Failed callouts retry up to three times, in batches of five, with a single chain.

The credential that would hold a provider key is documented and not deployed. Every demo row is synthetic. Agentforce is not part of the design.

This project targets Salesforce Developer Edition only. It does not use Enterprise Edition, a sandbox, a production org, real customer data, or Agentforce.
