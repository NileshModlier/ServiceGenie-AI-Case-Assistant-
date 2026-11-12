# UI States

`caseAssistant` shows one of four states. The Jest suite in `force-app/main/default/lwc/caseAssistant/__tests__/caseAssistant.test.js` covers each one.

## Loading

The record id is set and the wire has not returned data or an error. The component shows a spinner with the text "Loading case". The case fields and the action buttons are not rendered yet.

## Empty

There is no record id, or the controller returns `found = false`. The message is "Open a case to see the assistant." This is the app-page state and the state after a case id does not match a visible case. It is not an error.

## Error

The wire or the refresh call fails. The component shows the message from the Apex error, or "The case could not be loaded." when the failure has no message. A user without access sees "You do not have access to this case."

## Success

`found` is true. The header, case age, priority, status, customer, history, recent cases, draft card, next best action, and summary render from the context.

## Button state

| Button | Success | While refresh or generate is in flight | Loading, empty, and error |
| --- | --- | --- | --- |
| Refresh context | Enabled | Disabled | Not shown |
| Generate draft | Enabled | Disabled | Not shown |
| Approve draft | Shown when the latest draft status is Draft | Hidden while generate is in flight | Not shown |
| Reject draft | Shown when the latest draft status is Draft | Hidden while generate is in flight | Not shown |
| Next best action | Shown when a rule matches | Shown as text. There is no run button | Not shown |
| Queue summary | Enabled | Disabled | Not shown |

Refresh and generate stay on the success view while their promises run, and both buttons disable until the promise finishes. Approve does not send a message. Queue summary starts a background job and does not approve a draft. The next best action is text. It has no run button.
