public with sharing class DraftService {
    public static final String STATUS_DRAFT = 'Draft';
    public static final String STATUS_APPROVED = 'Approved';
    public static final String STATUS_REJECTED = 'Rejected';

    public static AI_Draft__c generateDraft(Id caseId) {
        CaseAssistController.CaseContext context = CaseAssistController.getCaseContext(caseId);
        if (context == null || context.found != true) {
            throw handled('Open a case before generating a draft.');
        }
        String prompt = assemblePrompt(context);
        LlmClient.LlmCompletion completion;
        try {
            completion = LlmClient.complete(prompt);
        } catch (CalloutException ex) {
            throw handled('The model request timed out.');
        }
        if (completion == null || completion.success != true) {
            throw handled(
                completion == null || String.isBlank(completion.errorMessage)
                    ? 'The model request failed.'
                    : completion.errorMessage
            );
        }
        AI_Draft__c draft = new AI_Draft__c();
        draft.Case__c = caseId;
        draft.Status__c = STATUS_DRAFT;
        draft.Original_Draft__c = completion.text;
        draft.Edited_Draft__c = completion.text;
        draft.Prompt_Version__c = LlmClient.PROMPT_VERSION;
        draft.Model_Name__c = String.isBlank(completion.modelName)
            ? LlmClient.DEFAULT_MODEL
            : completion.modelName;
        insert as user draft;
        return draft;
    }

    public static AI_Draft__c approveDraft(Id draftId, String editedBody) {
        requireStandardUser();
        AI_Draft__c draft = loadDraft(draftId);
        if (draft.Status__c != STATUS_DRAFT) {
            throw handled('Only a draft can be approved.');
        }
        if (editedBody != null) {
            draft.Edited_Draft__c = editedBody;
        }
        draft.Status__c = STATUS_APPROVED;
        draft.Approved_By__c = UserInfo.getUserId();
        draft.Approved_At__c = System.now();
        update as user draft;
        return draft;
    }

    public static AI_Draft__c rejectDraft(Id draftId) {
        requireStandardUser();
        AI_Draft__c draft = loadDraft(draftId);
        if (draft.Status__c != STATUS_DRAFT) {
            throw handled('Only a draft can be rejected.');
        }
        draft.Status__c = STATUS_REJECTED;
        draft.Approved_By__c = UserInfo.getUserId();
        draft.Approved_At__c = System.now();
        update as user draft;
        return draft;
    }

    public static AI_Draft__c latestDraft(Id caseId) {
        if (caseId == null) {
            return null;
        }
        List<AI_Draft__c> rows = [
            SELECT Id, Status__c, Original_Draft__c, Edited_Draft__c,
                Approved_By__c, Approved_At__c, Prompt_Version__c, Model_Name__c, Case__c
            FROM AI_Draft__c
            WHERE Case__c = :caseId
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }

    private static String assemblePrompt(CaseAssistController.CaseContext context) {
        String email = context.contact == null ? '' : context.contact.Email;
        String name = context.contact == null ? '' : context.contact.Name;
        String accountName = context.account == null ? '' : context.account.Name;
        String phone = phoneFor(context.contact);
        return 'Prompt version ' + LlmClient.PROMPT_VERSION
            + '\nCase ' + context.caseRecord.CaseNumber
            + '\nSubject ' + context.caseRecord.Subject
            + '\nStatus ' + context.caseRecord.Status
            + '\nPriority ' + context.caseRecord.Priority
            + '\nCustomer ' + name
            + '\nEmail ' + email
            + '\nPhone ' + phone
            + '\nAccount ' + accountName
            + '\nActivity ' + context.recentActivitySummary
            + '\nWrite a short reply the agent can edit. Do not send it.';
    }

    private static String phoneFor(Contact contact) {
        if (contact == null || contact.Id == null) {
            return '';
        }
        List<Contact> rows = [
            SELECT Phone
            FROM Contact
            WHERE Id = :contact.Id
            WITH USER_MODE
            LIMIT 1
        ];
        if (rows.isEmpty() || String.isBlank(rows[0].Phone)) {
            return '';
        }
        return rows[0].Phone;
    }

    private static AI_Draft__c loadDraft(Id draftId) {
        if (draftId == null) {
            throw handled('The draft is not available.');
        }
        List<AI_Draft__c> rows = [
            SELECT Id, Status__c, Original_Draft__c, Edited_Draft__c,
                Approved_By__c, Approved_At__c, Prompt_Version__c, Model_Name__c, Case__c
            FROM AI_Draft__c
            WHERE Id = :draftId
            WITH USER_MODE
            LIMIT 1
        ];
        if (rows.isEmpty()) {
            throw handled('The draft is not available.');
        }
        return rows[0];
    }

    private static void requireStandardUser() {
        if (UserInfo.getUserType() != 'Standard') {
            throw handled('A standard user must approve or reject the draft.');
        }
    }

    private static AuraHandledException handled(String message) {
        AuraHandledException error = new AuraHandledException(message);
        error.setMessage(message);
        return error;
    }
}
