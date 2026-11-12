public with sharing class LeadToCaseService {
    @TestVisible
    private static final String REQUEST_TYPE_SUPPORT = 'Support';
    @TestVisible
    private static final String ROUTED_STATUS = 'Routed to Support';
    @TestVisible
    private static final String SUPPORT_SUBJECT_PREFIX = 'Support: ';
    @TestVisible
    private static final String ONBOARDING_SUBJECT_PREFIX = 'Onboarding: ';

    private static final String CASE_STATUS_NEW = 'New';
    private static final String CASE_ORIGIN_WEB = 'Web';

    public static void routeNewSupportLeads(List<Lead> newLeads) {
        if (!isAutomationEnabled() || newLeads == null) {
            return;
        }
        for (Lead lead : newLeads) {
            if (isSupport(lead)) {
                lead.Status = ROUTED_STATUS;
            }
        }
    }

    public static void createSupportCases(List<Lead> newLeads) {
        if (!isAutomationEnabled() || newLeads == null || newLeads.isEmpty()) {
            return;
        }

        List<Lead> supportLeads = new List<Lead>();
        Set<Id> leadIds = new Set<Id>();
        Set<String> emails = new Set<String>();
        for (Lead lead : newLeads) {
            if (!isSupport(lead) || lead.Id == null) {
                continue;
            }
            supportLeads.add(lead);
            leadIds.add(lead.Id);
            if (String.isNotBlank(lead.Email)) {
                emails.add(lead.Email.trim());
            }
        }
        if (supportLeads.isEmpty()) {
            return;
        }

        Map<Id, List<Case>> existingByLead = casesBySourceLead(leadIds);
        Map<String, Contact> contactByEmail = contactsByEmail(emails);
        List<Case> toInsert = new List<Case>();
        for (Lead lead : supportLeads) {
            if (hasIntakeCase(existingByLead.get(lead.Id))) {
                continue;
            }
            toInsert.add(intakeCase(lead, contactByEmail));
        }
        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
    }

    public static void createOnboardingCases(List<Lead> newLeads, Map<Id, Lead> oldMap) {
        if (!isAutomationEnabled() || newLeads == null || newLeads.isEmpty() || oldMap == null) {
            return;
        }

        List<Lead> convertedSupport = new List<Lead>();
        Set<Id> leadIds = new Set<Id>();
        for (Lead lead : newLeads) {
            if (!isNewlyConvertedSupport(lead, oldMap.get(lead.Id))) {
                continue;
            }
            convertedSupport.add(lead);
            leadIds.add(lead.Id);
        }
        if (convertedSupport.isEmpty()) {
            return;
        }

        Map<Id, List<Case>> existingByLead = casesBySourceLead(leadIds);
        List<Case> toInsert = new List<Case>();
        for (Lead lead : convertedSupport) {
            if (hasOnboardingCase(existingByLead.get(lead.Id))) {
                continue;
            }
            toInsert.add(onboardingCase(lead));
        }
        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
    }

    private static Boolean isAutomationEnabled() {
        // Future record: Trigger_Control__mdt.Lead_To_Case.Automation_Enabled__c
        // via Trigger_Control__mdt.getInstance('Lead_To_Case'). No record is deployed in M2.
        return true;
    }

    private static Boolean isSupport(Lead lead) {
        return lead != null && lead.Request_Type__c == REQUEST_TYPE_SUPPORT;
    }

    private static Boolean isNewlyConvertedSupport(Lead current, Lead prior) {
        return current != null
            && prior != null
            && isSupport(current)
            && current.IsConverted
            && !prior.IsConverted
            && current.ConvertedContactId != null;
    }

    private static Map<Id, List<Case>> casesBySourceLead(Set<Id> leadIds) {
        Map<Id, List<Case>> casesByLead = new Map<Id, List<Case>>();
        for (Case record : [
            SELECT Id, Source_Lead__c, Subject
            FROM Case
            WHERE Source_Lead__c IN :leadIds
        ]) {
            if (!casesByLead.containsKey(record.Source_Lead__c)) {
                casesByLead.put(record.Source_Lead__c, new List<Case>());
            }
            casesByLead.get(record.Source_Lead__c).add(record);
        }
        return casesByLead;
    }

    private static Map<String, Contact> contactsByEmail(Set<String> emails) {
        Map<String, Contact> contactByEmail = new Map<String, Contact>();
        if (emails.isEmpty()) {
            return contactByEmail;
        }
        for (Contact contact : [
            SELECT Id, Email, AccountId
            FROM Contact
            WHERE Email IN :emails
        ]) {
            String key = contact.Email.trim().toLowerCase();
            Contact current = contactByEmail.get(key);
            if (current == null || String.valueOf(contact.Id) < String.valueOf(current.Id)) {
                contactByEmail.put(key, contact);
            }
        }
        return contactByEmail;
    }

    private static Case intakeCase(Lead lead, Map<String, Contact> contactByEmail) {
        Contact match = contactByEmail.get(emailKey(lead.Email));
        String companyName = String.isBlank(lead.Company) ? lead.LastName : lead.Company;
        Case record = new Case(
            Subject = SUPPORT_SUBJECT_PREFIX + companyName,
            Status = CASE_STATUS_NEW,
            Origin = CASE_ORIGIN_WEB,
            Source_Lead__c = lead.Id,
            Description = supportDescription(lead)
        );
        if (match != null) {
            record.ContactId = match.Id;
            record.AccountId = match.AccountId;
        }
        return record;
    }

    private static Case onboardingCase(Lead lead) {
        return new Case(
            Subject = ONBOARDING_SUBJECT_PREFIX + lead.Name,
            Status = CASE_STATUS_NEW,
            Origin = CASE_ORIGIN_WEB,
            Source_Lead__c = lead.Id,
            ContactId = lead.ConvertedContactId,
            AccountId = lead.ConvertedAccountId,
            Description = 'Onboarding case for the contact created from a converted support lead.'
        );
    }

    private static String supportDescription(Lead lead) {
        if (String.isNotBlank(lead.Description)) {
            return lead.Description;
        }
        return 'Support request from ' + lead.FirstName + ' ' + lead.LastName + ' at ' + lead.Company + '.';
    }

    private static Boolean hasIntakeCase(List<Case> existing) {
        if (existing == null) {
            return false;
        }
        for (Case record : existing) {
            if (!isOnboardingSubject(record.Subject)) {
                return true;
            }
        }
        return false;
    }

    private static Boolean hasOnboardingCase(List<Case> existing) {
        if (existing == null) {
            return false;
        }
        for (Case record : existing) {
            if (isOnboardingSubject(record.Subject)) {
                return true;
            }
        }
        return false;
    }

    private static Boolean isOnboardingSubject(String subject) {
        return subject != null && subject.startsWith(ONBOARDING_SUBJECT_PREFIX);
    }

    private static String emailKey(String email) {
        return String.isBlank(email) ? null : email.trim().toLowerCase();
    }
}
