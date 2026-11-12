public with sharing class CaseAssistController {
    @AuraEnabled(cacheable=true)
    public static CaseContext getCaseContext(Id caseId) {
        return loadContext(caseId);
    }

    @AuraEnabled
    public static CaseContext refreshCaseContext(Id caseId) {
        return loadContext(caseId);
    }

    public class CaseContext {
        @AuraEnabled public Case caseRecord;
        @AuraEnabled public Contact contact;
        @AuraEnabled public Account account;
        @AuraEnabled public List<Case> recentCases;
        @AuraEnabled public String recentActivitySummary;
        @AuraEnabled public Boolean found;
    }

    private static CaseContext loadContext(Id caseId) {
        if (caseId == null) {
            return emptyContext();
        }
        try {
            List<Case> rows = [
                SELECT Id, CaseNumber, Subject, Status, Priority, CreatedDate, ContactId, AccountId
                FROM Case
                WHERE Id = :caseId
                WITH USER_MODE
                LIMIT 1
            ];
            if (rows.isEmpty()) {
                return emptyContext();
            }
            Case current = rows[0];
            CaseContext context = new CaseContext();
            context.found = true;
            context.caseRecord = current;
            context.contact = loadContact(current.ContactId);
            context.account = loadAccount(current.AccountId);
            context.recentCases = recentCases(current.Id, current.ContactId, current.AccountId);
            context.recentActivitySummary = activitySummary(current.Id);
            return context;
        } catch (QueryException ex) {
            AuraHandledException error = new AuraHandledException('You do not have access to this case.');
            error.setMessage('You do not have access to this case.');
            throw error;
        }
    }

    private static CaseContext emptyContext() {
        CaseContext context = new CaseContext();
        context.found = false;
        context.recentCases = new List<Case>();
        context.recentActivitySummary = '';
        return context;
    }

    private static Contact loadContact(Id contactId) {
        if (contactId == null) {
            return null;
        }
        List<Contact> rows = [
            SELECT Id, Name, Email
            FROM Contact
            WHERE Id = :contactId
            WITH USER_MODE
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }

    private static Account loadAccount(Id accountId) {
        if (accountId == null) {
            return null;
        }
        List<Account> rows = [
            SELECT Id, Name
            FROM Account
            WHERE Id = :accountId
            WITH USER_MODE
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }

    private static List<Case> recentCases(Id caseId, Id contactId, Id accountId) {
        if (contactId == null && accountId == null) {
            return new List<Case>();
        }
        if (contactId != null && accountId != null) {
            return [
                SELECT Id, CaseNumber, Subject, Status, CreatedDate
                FROM Case
                WHERE Id != :caseId
                AND (ContactId = :contactId OR AccountId = :accountId)
                WITH USER_MODE
                ORDER BY CreatedDate DESC
                LIMIT 5
            ];
        }
        if (contactId != null) {
            return [
                SELECT Id, CaseNumber, Subject, Status, CreatedDate
                FROM Case
                WHERE Id != :caseId
                AND ContactId = :contactId
                WITH USER_MODE
                ORDER BY CreatedDate DESC
                LIMIT 5
            ];
        }
        return [
            SELECT Id, CaseNumber, Subject, Status, CreatedDate
            FROM Case
            WHERE Id != :caseId
            AND AccountId = :accountId
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 5
        ];
    }

    private static String activitySummary(Id caseId) {
        try {
            List<Task> tasks = [
                SELECT Subject, Status
                FROM Task
                WHERE WhatId = :caseId
                WITH USER_MODE
                ORDER BY CreatedDate DESC
                LIMIT 5
            ];
            if (tasks.isEmpty()) {
                return 'No recent activity on this case.';
            }
            String subject = String.isBlank(tasks[0].Subject) ? 'Untitled task' : tasks[0].Subject;
            String status = String.isBlank(tasks[0].Status) ? 'No status' : tasks[0].Status;
            String countLabel = tasks.size() == 1 ? '1 recent task' : tasks.size() + ' recent tasks';
            return countLabel + '. Latest: ' + subject + ' (' + status + ').';
        } catch (QueryException ex) {
            return 'Recent activity is not available for this user.';
        }
    }

    @AuraEnabled
    public static AI_Draft__c generateDraft(Id caseId) {
        return DraftService.generateDraft(caseId);
    }

    @AuraEnabled
    public static AI_Draft__c approveDraft(Id draftId, String editedBody) {
        return DraftService.approveDraft(draftId, editedBody);
    }

    @AuraEnabled
    public static AI_Draft__c rejectDraft(Id draftId) {
        return DraftService.rejectDraft(draftId);
    }

    @AuraEnabled(cacheable=true)
    public static AI_Draft__c getLatestDraft(Id caseId) {
        return DraftService.latestDraft(caseId);
    }

    @AuraEnabled(cacheable=true)
    public static NbaService.Recommendation getNextBestAction(Id caseId) {
        return NbaService.recommend(caseId);
    }

    @AuraEnabled(cacheable=true)
    public static Case getLatestSummary(Id caseId) {
        if (caseId == null) {
            return null;
        }
        List<Case> rows = [
            SELECT Id, Latest_Summary__c, Summary_Timestamp__c, Summary_Model_Name__c
            FROM Case
            WHERE Id = :caseId
            WITH USER_MODE
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }

    @AuraEnabled
    public static String queueSummary(Id caseId) {
        if (caseId == null) {
            AuraHandledException error = new AuraHandledException('Open a case before queueing a summary.');
            error.setMessage('Open a case before queueing a summary.');
            throw error;
        }
        return System.enqueueJob(new SummaryQueueable(new List<Id>{ caseId }));
    }
}
