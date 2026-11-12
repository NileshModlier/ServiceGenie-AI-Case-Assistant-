# Audit Model

`AI_Draft__c` is a master-detail child of Case. Sharing follows the case. The object tracks history, and `Status__c`, `Approved_By__c`, and `Approved_At__c` track field history. The permission set `ServiceGenie_AI_Draft` can create and edit drafts and cannot delete them.

## Fields

| Label | API name | What it stores |
| --- | --- | --- |
| Case | `Case__c` | Parent case. Required. |
| Original Draft | `Original_Draft__c` | Text returned by the model. Later edits do not replace it. |
| Edited Draft | `Edited_Draft__c` | Starts as a copy of the original. Approve can save the agent's edit here. |
| Approver | `Approved_By__c` | The standard user who approved or rejected. Blank while the status is Draft. |
| Approval Time | `Approved_At__c` | When that person decided. Blank while the status is Draft. |
| Prompt Version | `Prompt_Version__c` | `v1` for this milestone. |
| Model Name | `Model_Name__c` | Model label from the response, or `servicegenie-draft`. Not a secret. |
| Status | `Status__c` | `Draft`, `Approved`, or `Rejected`. |

Standard `CreatedById`, `CreatedDate`, `LastModifiedById`, and `LastModifiedDate` apply. The name is an auto-number, `DR-{0000}`.

## Status

| Status | Who sets it | Meaning |
| --- | --- | --- |
| Draft | `generateDraft`, after a 200 response | Text is stored. Nothing is sent. |
| Approved | `approveDraft` | A standard user accepted the wording. The record is still not an email. Only this status may continue to a send in a later milestone. |
| Rejected | `rejectDraft` | A standard user declined the wording. The original text stays. The row is not deleted. |

A validation rule blocks Approved or Rejected when the approver or the time is blank. Apex sets both fields in the same update. Guest and automated users are rejected by `UserInfo.getUserType()` before that update.

A second generate inserts a new row. It does not overwrite an approved or rejected row. Closing a case is the way to keep this history. Deleting a case would delete the drafts because of the master-detail.

## What is not audited here

No `EmailMessage` is created. No send action exists. Next best actions are not stored and not run.
