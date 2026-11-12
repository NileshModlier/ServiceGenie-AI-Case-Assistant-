public with sharing class SummaryService {
    public static final Integer BATCH_SIZE = 5;
    public static final Integer MAX_URGENT = 50;

    public static List<Id> urgentIds() {
        List<Id> ids = new List<Id>();
        for (Case current : [
            SELECT Id
            FROM Case
            WHERE IsClosed = false
            AND (Priority = 'High' OR Status = 'Escalated')
            WITH USER_MODE
            ORDER BY CreatedDate ASC
            LIMIT :MAX_URGENT
        ]) {
            ids.add(current.Id);
        }
        return ids;
    }

    public static List<Id> summarize(List<Id> caseIds) {
        List<Id> retry = new List<Id>();
        if (caseIds == null || caseIds.isEmpty()) {
            return retry;
        }
        Map<Id, Case> rows = new Map<Id, Case>([
            SELECT Id, CaseNumber, Subject, Status, Priority, CreatedDate, IsClosed
            FROM Case
            WHERE Id IN :caseIds
            WITH USER_MODE
        ]);
        List<Case> updates = new List<Case>();
        for (Id caseId : caseIds) {
            Case current = rows.get(caseId);
            if (current == null) {
                continue;
            }
            String prompt = promptFor(current);
            if (SafetyFilter.blockReason(prompt) != null) {
                continue;
            }
            try {
                LlmClient.LlmCompletion completion = LlmClient.complete(prompt);
                if (completion == null || completion.success != true || String.isBlank(completion.text)) {
                    retry.add(caseId);
                    continue;
                }
                if (SafetyFilter.blockReason(completion.text) != null) {
                    continue;
                }
                updates.add(new Case(
                    Id = current.Id,
                    Latest_Summary__c = LlmClient.maskSensitiveData(completion.text),
                    Summary_Timestamp__c = System.now(),
                    Summary_Model_Name__c = String.isBlank(completion.modelName)
                        ? LlmClient.DEFAULT_MODEL
                        : completion.modelName
                ));
            } catch (CalloutException ex) {
                retry.add(caseId);
            }
        }
        if (!updates.isEmpty()) {
            update as user updates;
        }
        return retry;
    }

    private static String promptFor(Case current) {
        return 'Summarize this synthetic case for an agent. Do not send a message. Do not approve a draft.'
            + '\nCase ' + current.CaseNumber
            + '\nSubject ' + current.Subject
            + '\nStatus ' + current.Status
            + '\nPriority ' + current.Priority;
    }
}
