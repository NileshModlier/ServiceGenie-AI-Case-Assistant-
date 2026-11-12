# Future Roadmap

v1.0 stops after rule-based recommendations and person-started summaries. These items are not in the source.

## Send, still with a person

A later version can send the edited draft of an Approved row. The agent confirms the send in a second step. Approval alone still must not send. Rejected and Draft rows stay ineligible.

## Org setup

When a Developer Edition org is authorized, an admin can create `LLM_External` and `LLM_API` from `docs/credential_architecture.md` and add the named principal to `ServiceGenie_AI_Draft`. The key is entered in Setup.

## Measurements that need an org

Run the Apex suite with coverage. The 85% goal stays a goal until that command reports a number. Capture console screenshots on the deployed Case page.

## Left out on purpose

Autonomous approvals, autonomous next actions, scheduled summary jobs, and Agentforce are not the next step. A lead that is inserted without Support and later edited to Support is still an open routing gap, separate from the model path.
