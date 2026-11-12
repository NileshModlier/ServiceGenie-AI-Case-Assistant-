@isTest
public class TestDataFactory {
    public class ConvertedLeadResult {
        public Lead lead;
        public Id contactId;
        public Id accountId;
    }

    public static List<Lead> supportLeads(Integer count, Boolean includeEmail) {
        return supportLeads(count, includeEmail, 0);
    }

    public static List<Lead> supportLeads(Integer count, Boolean includeEmail, Integer startIndex) {
        List<Lead> leads = new List<Lead>();
        if (count == null || count <= 0) {
            return leads;
        }
        Integer first = startIndex == null ? 0 : startIndex;
        for (Integer index = 0; index < count; index++) {
            Integer sequence = first + index;
            Lead lead = new Lead(
                FirstName = 'Synthetic',
                LastName = 'Support ' + sequence,
                Company = 'Example Household ' + sequence,
                Request_Type__c = 'Support',
                Status = 'Open - Not Contacted',
                Description = 'Synthetic support request ' + sequence
            );
            if (includeEmail == true) {
                lead.Email = 'support.' + sequence + '@example.com';
            }
            leads.add(lead);
        }
        return leads;
    }

    public static List<Lead> salesLeads(Integer count) {
        return salesLeads(count, 0);
    }

    public static List<Lead> salesLeads(Integer count, Integer startIndex) {
        List<Lead> leads = new List<Lead>();
        if (count == null || count <= 0) {
            return leads;
        }
        Integer first = startIndex == null ? 0 : startIndex;
        for (Integer index = 0; index < count; index++) {
            Integer sequence = first + index;
            leads.add(new Lead(
                FirstName = 'Synthetic',
                LastName = 'Sales ' + sequence,
                Company = 'Example Sales ' + sequence,
                Email = 'sales.' + sequence + '@example.com',
                Request_Type__c = 'Sales',
                Status = 'Open - Not Contacted'
            ));
        }
        return leads;
    }

    public static List<Lead> unqualifiedLeads(Integer count) {
        List<Lead> leads = new List<Lead>();
        if (count == null || count <= 0) {
            return leads;
        }
        for (Integer index = 0; index < count; index++) {
            leads.add(new Lead(
                FirstName = 'Synthetic',
                LastName = 'Unqualified ' + index,
                Company = 'Example Unqualified ' + index,
                Email = 'unqualified.' + index + '@example.com',
                Status = 'Open - Not Contacted'
            ));
        }
        return leads;
    }

    public static List<Lead> mixedBatch(Integer supportCount, Integer salesCount) {
        List<Lead> batch = supportLeads(supportCount, true);
        batch.addAll(salesLeads(salesCount));
        return batch;
    }

    public static Contact existingContact(String email) {
        return existingContact(email, null);
    }

    public static Contact existingContact(String email, Id accountId) {
        Id parentId = accountId;
        if (parentId == null) {
            Account account = new Account(Name = 'Example Household');
            insert account;
            parentId = account.Id;
        }
        Contact contact = new Contact(
            FirstName = 'Casey',
            LastName = 'Demo',
            AccountId = parentId,
            Email = email
        );
        Database.DMLOptions options = new Database.DMLOptions();
        options.DuplicateRuleHeader.allowSave = true;
        Database.SaveResult result = Database.insert(contact, options);
        if (!result.isSuccess()) {
            String message = result.getErrors().isEmpty()
                ? 'Contact insert failed'
                : result.getErrors()[0].getMessage();
            Assert.fail(message);
        }
        return contact;
    }

    public static Case caseForLead(Id leadId, Id contactId) {
        return caseForLead(leadId, contactId, 'Support: factory');
    }

    public static Case caseForLead(Id leadId, Id contactId, String subject) {
        Case record = new Case(
            Subject = subject,
            Status = 'New',
            Origin = 'Web',
            Source_Lead__c = leadId,
            ContactId = contactId,
            Description = 'Synthetic case created by the test factory.'
        );
        insert record;
        return record;
    }

    public static ConvertedLeadResult convertedSupportLead() {
        Lead lead = supportLeads(1, true)[0];
        insert lead;
        return convertLead(lead.Id);
    }

    public static ConvertedLeadResult convertLead(Id leadId) {
        Database.LeadConvert conversion = new Database.LeadConvert();
        conversion.setLeadId(leadId);
        conversion.setConvertedStatus(convertedStatusLabel());
        conversion.setDoNotCreateOpportunity(true);
        Database.LeadConvertResult conversionResult = Database.convertLead(conversion);
        if (!conversionResult.isSuccess()) {
            String message = conversionResult.getErrors().isEmpty()
                ? 'Lead conversion failed'
                : conversionResult.getErrors()[0].getMessage();
            Assert.fail(message);
        }
        ConvertedLeadResult result = new ConvertedLeadResult();
        result.contactId = conversionResult.getContactId();
        result.accountId = conversionResult.getAccountId();
        result.lead = [
            SELECT Id, IsConverted, ConvertedContactId, ConvertedAccountId,
                Request_Type__c, Status, Name, Company, Email, Description
            FROM Lead
            WHERE Id = :leadId
        ];
        return result;
    }

    private static String convertedStatusLabel() {
        return [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1].MasterLabel;
    }
}
