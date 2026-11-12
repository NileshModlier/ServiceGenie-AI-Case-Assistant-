@isTest
private class LeadToCaseServiceTest {
    private static final String CASE_STATUS = 'New';

    @isTest
    static void singleSupportLeadCreatesOneCase() {
        Lead lead = TestDataFactory.supportLeads(1, true)[0];

        Test.startTest();
        insert lead;
        Test.stopTest();

        Lead stored = [SELECT Status FROM Lead WHERE Id = :lead.Id];
        List<Case> cases = casesFor(new Set<Id>{ lead.Id });

        Assert.areEqual(LeadToCaseService.ROUTED_STATUS, stored.Status, 'Support lead is routed on insert');
        Assert.areEqual(1, cases.size(), 'Case count');
        assertCase(cases[0], lead.Id, null, null);
        Assert.isTrue(cases[0].Subject.startsWith(LeadToCaseService.SUPPORT_SUBJECT_PREFIX), 'Intake subject');
        Assert.areEqual(0, [SELECT COUNT() FROM Account], 'A support lead does not create an account');
        Assert.areEqual(0, [SELECT COUNT() FROM Contact], 'A support lead does not create a contact');
    }

    @isTest
    static void bulkSupportLeadsCreateTwoHundredCases() {
        List<Lead> leads = TestDataFactory.supportLeads(200, true);

        Test.startTest();
        insert leads;
        Integer queries = Limits.getQueries();
        Integer dmlStatements = Limits.getDmlStatements();
        Test.stopTest();

        Assert.isTrue(
            queries >= 2 && queries <= 10,
            'Queries used for 200 support leads should be 2 and must stay at or below 10. Queries used: ' + queries
        );
        Assert.isTrue(
            dmlStatements >= 2 && dmlStatements <= 10,
            'DML statements used for 200 support leads should be 2 and must stay at or below 10. DML statements used: ' + dmlStatements
        );

        Map<Id, Lead> stored = new Map<Id, Lead>([SELECT Status FROM Lead WHERE Id IN :leads]);
        Assert.areEqual(200, stored.size(), 'All 200 leads were inserted');
        for (Lead lead : stored.values()) {
            Assert.areEqual(LeadToCaseService.ROUTED_STATUS, lead.Status, 'Every support lead is routed');
        }

        List<Case> cases = casesFor(stored.keySet());
        Assert.areEqual(200, cases.size(), 'Case count');
        Set<Id> sources = new Set<Id>();
        for (Case record : cases) {
            assertCase(record, record.Source_Lead__c, null, null);
            Assert.isTrue(stored.containsKey(record.Source_Lead__c), 'Source lead is one of the inserted leads');
            sources.add(record.Source_Lead__c);
        }
        Assert.areEqual(200, sources.size(), 'Each lead has its own case');
    }

    @isTest
    static void salesLeadsAreIgnored() {
        List<Lead> sales = TestDataFactory.salesLeads(2);

        Test.startTest();
        insert sales;
        Test.stopTest();

        for (Lead lead : [SELECT Status, Request_Type__c FROM Lead WHERE Id IN :sales]) {
            Assert.areEqual('Sales', lead.Request_Type__c, 'Request type');
            Assert.areEqual('Open - Not Contacted', lead.Status, 'Sales status stays unchanged');
        }
        Assert.areEqual(0, [SELECT COUNT() FROM Case], 'Case count');
        LeadToCaseService.createSupportCases(sales);
        Assert.areEqual(0, [SELECT COUNT() FROM Case], 'Calling the service again still creates no case');

        TestDataFactory.convertLead(sales[0].Id);
        Assert.areEqual(0, [SELECT COUNT() FROM Case], 'Converting a sales lead does not create an onboarding case');
    }

    @isTest
    static void supportLeadWithoutEmailCreatesUnlinkedCase() {
        Lead lead = TestDataFactory.supportLeads(1, false)[0];
        lead.Description = null;

        Test.startTest();
        insert lead;
        Test.stopTest();

        List<Case> cases = casesFor(new Set<Id>{ lead.Id });
        Assert.areEqual(1, cases.size(), 'Case count');
        assertCase(cases[0], lead.Id, null, null);
        Assert.areEqual(0, [SELECT COUNT() FROM Contact], 'No contact is created for a blank email');
    }

    @isTest
    static void supportLeadMatchesExistingContact() {
        Contact contact = TestDataFactory.existingContact('Casey.Demo@example.com');
        Lead lead = TestDataFactory.supportLeads(1, false)[0];
        lead.Email = 'casey.demo@example.com';

        Test.startTest();
        insert lead;
        Test.stopTest();

        List<Case> cases = casesFor(new Set<Id>{ lead.Id });
        Assert.areEqual(1, cases.size(), 'Case count');
        assertCase(cases[0], lead.Id, contact.Id, contact.AccountId);
    }

    @isTest
    static void convertedSupportLeadCreatesOnboardingCase() {
        Lead lead = TestDataFactory.supportLeads(1, true)[0];
        insert lead;
        Assert.areEqual(1, casesFor(new Set<Id>{ lead.Id }).size(), 'Insert creates the intake case first');

        Test.startTest();
        TestDataFactory.ConvertedLeadResult result = TestDataFactory.convertLead(lead.Id);
        Test.stopTest();

        List<Case> cases = casesFor(new Set<Id>{ lead.Id });
        Assert.areEqual(2, cases.size(), 'Case count');
        Case intake = findIntake(cases);
        Case onboarding = findOnboarding(cases);
        assertCase(intake, lead.Id, null, null);
        assertCase(onboarding, lead.Id, result.contactId, result.accountId);
        Assert.isTrue(onboarding.Subject.startsWith(LeadToCaseService.ONBOARDING_SUBJECT_PREFIX), 'Onboarding case creation');
    }

    @isTest
    static void mixedBatchCreatesCasesOnlyForSupport() {
        List<Lead> batch = TestDataFactory.mixedBatch(2, 3);

        Test.startTest();
        insert batch;
        Test.stopTest();

        Map<Id, Lead> stored = new Map<Id, Lead>([
            SELECT Status, Request_Type__c
            FROM Lead
            WHERE Id IN :batch
        ]);
        Set<Id> supportIds = new Set<Id>();
        Integer salesCount = 0;
        for (Lead lead : stored.values()) {
            if (lead.Request_Type__c == 'Support') {
                supportIds.add(lead.Id);
                Assert.areEqual(LeadToCaseService.ROUTED_STATUS, lead.Status, 'Support lead status');
            } else {
                salesCount++;
                Assert.areEqual('Open - Not Contacted', lead.Status, 'Sales lead status');
            }
        }
        Assert.areEqual(2, supportIds.size(), 'Support lead count');
        Assert.areEqual(3, salesCount, 'Sales lead count');

        List<Case> cases = casesFor(stored.keySet());
        Assert.areEqual(2, cases.size(), 'Case count');
        for (Case record : cases) {
            assertCase(record, record.Source_Lead__c, null, null);
            Assert.isTrue(supportIds.contains(record.Source_Lead__c), 'Source lead is a support lead');
        }
    }

    @isTest
    static void mixedBulkInsertOfTwoHundredLeads() {
        List<Lead> batch = TestDataFactory.mixedBatch(120, 80);

        Test.startTest();
        insert batch;
        Integer queries = Limits.getQueries();
        Integer dmlStatements = Limits.getDmlStatements();
        Test.stopTest();

        Assert.isTrue(
            queries >= 2 && queries <= 10,
            'Queries used for 120 support and 80 sales leads should be 2 and must stay at or below 10. Queries used: ' + queries
        );
        Assert.isTrue(
            dmlStatements >= 2 && dmlStatements <= 10,
            'DML statements used for the mixed 200-lead insert should be 2 and must stay at or below 10. DML statements used: ' + dmlStatements
        );

        Map<Id, Lead> stored = new Map<Id, Lead>([
            SELECT Status, Request_Type__c
            FROM Lead
            WHERE Id IN :batch
        ]);
        Assert.areEqual(200, stored.size(), 'Mixed batch size');
        Set<Id> supportIds = new Set<Id>();
        Set<Id> salesIds = new Set<Id>();
        for (Lead lead : stored.values()) {
            if (lead.Request_Type__c == 'Support') {
                supportIds.add(lead.Id);
                Assert.areEqual(LeadToCaseService.ROUTED_STATUS, lead.Status, 'Support status');
            } else {
                salesIds.add(lead.Id);
                Assert.areEqual('Open - Not Contacted', lead.Status, 'Sales status');
            }
        }
        Assert.areEqual(120, supportIds.size(), 'Support count');
        Assert.areEqual(80, salesIds.size(), 'Sales count');

        List<Case> cases = casesFor(stored.keySet());
        Assert.areEqual(120, cases.size(), 'Case count');
        Set<Id> sources = new Set<Id>();
        for (Case record : cases) {
            assertCase(record, record.Source_Lead__c, null, null);
            Assert.isTrue(supportIds.contains(record.Source_Lead__c), 'Only support leads produce cases');
            Assert.isFalse(salesIds.contains(record.Source_Lead__c), 'Sales leads produce no case');
            sources.add(record.Source_Lead__c);
        }
        Assert.areEqual(120, sources.size(), 'One case per support lead');
    }

    @isTest
    static void duplicatePassDoesNotCreateAnotherCase() {
        Lead lead = TestDataFactory.supportLeads(1, true)[0];
        insert lead;
        Id intakeId = casesFor(new Set<Id>{ lead.Id })[0].Id;

        LeadToCaseService.createSupportCases(new List<Lead>{ lead });
        List<Case> afterSecondPass = casesFor(new Set<Id>{ lead.Id });
        Assert.areEqual(1, afterSecondPass.size(), 'Duplicate prevention for the intake case');
        Assert.areEqual(intakeId, afterSecondPass[0].Id, 'The original intake case is kept');

        Lead sales = TestDataFactory.salesLeads(1, 50)[0];
        insert sales;
        TestDataFactory.caseForLead(sales.Id, null);
        Lead asSupport = sales.clone(true, true, true, true);
        asSupport.Request_Type__c = 'Support';
        LeadToCaseService.createSupportCases(new List<Lead>{ asSupport });
        Assert.areEqual(1, casesFor(new Set<Id>{ sales.Id }).size(), 'An existing intake case blocks another one');

        TestDataFactory.ConvertedLeadResult converted = TestDataFactory.convertLead(lead.Id);
        Assert.areEqual(2, casesFor(new Set<Id>{ lead.Id }).size(), 'Onboarding case creation');
        LeadToCaseService.createOnboardingCases(
            new List<Lead>{ converted.lead },
            new Map<Id, Lead>{ converted.lead.Id => priorVersion(converted.lead) }
        );
        List<Case> afterConversionPass = casesFor(new Set<Id>{ lead.Id });
        Assert.areEqual(2, afterConversionPass.size(), 'Duplicate prevention for the onboarding case');
        assertCase(findOnboarding(afterConversionPass), lead.Id, converted.contactId, converted.accountId);
    }

    @isTest
    static void emptyInputsDoNotCreateCases() {
        Lead unsaved = TestDataFactory.supportLeads(1, false)[0];

        LeadToCaseService.routeNewSupportLeads(null);
        LeadToCaseService.routeNewSupportLeads(new List<Lead>());
        LeadToCaseService.routeNewSupportLeads(new List<Lead>{ unsaved });
        LeadToCaseService.createSupportCases(null);
        LeadToCaseService.createSupportCases(new List<Lead>());
        LeadToCaseService.createSupportCases(new List<Lead>{ unsaved });
        LeadToCaseService.createOnboardingCases(null, null);
        LeadToCaseService.createOnboardingCases(new List<Lead>(), null);
        LeadToCaseService.createOnboardingCases(new List<Lead>(), new Map<Id, Lead>());

        Assert.areEqual(LeadToCaseService.ROUTED_STATUS, unsaved.Status, 'In-memory support lead is routed');
        Assert.areEqual(0, [SELECT COUNT() FROM Case], 'Case count');
        Assert.areEqual(0, [SELECT COUNT() FROM Account], 'Empty inputs create no account');
        Assert.areEqual(0, [SELECT COUNT() FROM Contact], 'Empty inputs create no contact');
    }

    @isTest
    static void nullInputsHaveZeroSideEffects() {
        Lead unsaved = TestDataFactory.supportLeads(1, true)[0];
        LeadToCaseService.routeNewSupportLeads(new List<Lead>{ null, unsaved });
        LeadToCaseService.createSupportCases(new List<Lead>{ null });
        LeadToCaseService.createOnboardingCases(new List<Lead>{ null }, new Map<Id, Lead>());

        Lead sales = TestDataFactory.salesLeads(1)[0];
        insert sales;
        Contact contact = TestDataFactory.existingContact('null.case.demo@example.com');
        Integer casesBefore = [SELECT COUNT() FROM Case];

        Lead missingPrior = supportShape(sales, contact);
        LeadToCaseService.createOnboardingCases(new List<Lead>{ missingPrior }, new Map<Id, Lead>());

        Lead alreadyConverted = supportShape(sales, contact);
        Lead priorConverted = alreadyConverted.clone(true, true, true, true);
        priorConverted.IsConverted = true;
        LeadToCaseService.createOnboardingCases(
            new List<Lead>{ alreadyConverted },
            new Map<Id, Lead>{ alreadyConverted.Id => priorConverted }
        );

        Lead missingContact = supportShape(sales, contact);
        missingContact.ConvertedContactId = null;
        LeadToCaseService.createOnboardingCases(
            new List<Lead>{ missingContact },
            new Map<Id, Lead>{ missingContact.Id => priorVersion(missingContact) }
        );

        Assert.areEqual(LeadToCaseService.ROUTED_STATUS, unsaved.Status, 'A null list entry does not block a support lead');
        Assert.areEqual(casesBefore, [SELECT COUNT() FROM Case], 'Null handling creates no case');
        Assert.areEqual('Open - Not Contacted', [SELECT Status FROM Lead WHERE Id = :sales.Id].Status, 'The stored sales lead is unchanged');
    }

    @isTest
    static void blankRequestTypeHasZeroSideEffects() {
        Lead lead = TestDataFactory.unqualifiedLeads(1)[0];

        Test.startTest();
        insert lead;
        update new Lead(Id = lead.Id, Description = 'Still unqualified');
        Test.stopTest();

        Lead stored = [SELECT Status, Request_Type__c FROM Lead WHERE Id = :lead.Id];
        Assert.isNull(stored.Request_Type__c, 'Request type stays blank');
        Assert.areEqual('Open - Not Contacted', stored.Status, 'Status');
        Assert.areEqual(0, [SELECT COUNT() FROM Case], 'Case count');
        Assert.areEqual(0, [SELECT COUNT() FROM Account], 'No account is created');
        Assert.areEqual(0, [SELECT COUNT() FROM Contact], 'No contact is created');
    }

    @isTest
    static void duplicateContactEmailsUseLowestId() {
        Contact first = TestDataFactory.existingContact('dup.demo@example.com');
        Contact second = TestDataFactory.existingContact('dup.demo@example.com', first.AccountId);
        Lead lead = TestDataFactory.supportLeads(1, false)[0];
        lead.Email = 'DUP.demo@example.com';

        Test.startTest();
        insert lead;
        Test.stopTest();

        Id lowestId = String.valueOf(first.Id) < String.valueOf(second.Id) ? first.Id : second.Id;
        List<Case> cases = casesFor(new Set<Id>{ lead.Id });
        Assert.areEqual(1, cases.size(), 'Case count');
        assertCase(cases[0], lead.Id, lowestId, first.AccountId);
    }

    @isTest
    static void nonConversionUpdateDoesNotAddACase() {
        Lead lead = TestDataFactory.supportLeads(1, true)[0];
        insert lead;
        Id intakeId = casesFor(new Set<Id>{ lead.Id })[0].Id;

        Test.startTest();
        update new Lead(Id = lead.Id, Description = 'Updated synthetic note');
        Test.stopTest();

        List<Case> cases = casesFor(new Set<Id>{ lead.Id });
        Assert.areEqual(1, cases.size(), 'Case count');
        Assert.areEqual(intakeId, cases[0].Id, 'The intake case is not replaced');
        assertCase(cases[0], lead.Id, null, null);
        Assert.areEqual(
            LeadToCaseService.ROUTED_STATUS,
            [SELECT Status FROM Lead WHERE Id = :lead.Id].Status,
            'Status'
        );
    }

    @isTest
    static void trimmedEmailMatchesExistingContact() {
        Contact contact = TestDataFactory.existingContact('trim.demo@example.com');
        Lead sales = TestDataFactory.salesLeads(1, 90)[0];
        insert sales;
        Lead asSupport = sales.clone(true, true, true, true);
        asSupport.Request_Type__c = 'Support';
        asSupport.Email = '  TRIM.demo@example.com  ';

        LeadToCaseService.createSupportCases(new List<Lead>{ asSupport });

        List<Case> cases = casesFor(new Set<Id>{ sales.Id });
        Assert.areEqual(1, cases.size(), 'Case count');
        assertCase(cases[0], sales.Id, contact.Id, contact.AccountId);
    }

    @isTest
    static void onboardingRecordDoesNotBlockIntakeCase() {
        Lead sales = TestDataFactory.salesLeads(1, 80)[0];
        insert sales;
        TestDataFactory.caseForLead(sales.Id, null, 'Onboarding: existing');
        Lead asSupport = sales.clone(true, true, true, true);
        asSupport.Request_Type__c = 'Support';

        LeadToCaseService.createSupportCases(new List<Lead>{ asSupport });
        List<Case> cases = casesFor(new Set<Id>{ sales.Id });
        Assert.areEqual(2, cases.size(), 'Case count');
        assertCase(findIntake(cases), sales.Id, null, null);
        Assert.isNotNull(findOnboarding(cases), 'Onboarding case remains');

        LeadToCaseService.createSupportCases(new List<Lead>{ asSupport });
        Assert.areEqual(2, casesFor(new Set<Id>{ sales.Id }).size(), 'Duplicate prevention after the intake case exists');
    }

    private static List<Case> casesFor(Set<Id> leadIds) {
        return [
            SELECT Id, Subject, Status, ContactId, AccountId, Source_Lead__c
            FROM Case
            WHERE Source_Lead__c IN :leadIds
        ];
    }

    private static void assertCase(Case record, Id leadId, Id contactId, Id accountId) {
        Assert.areEqual(leadId, record.Source_Lead__c, 'Source_Lead__c');
        Assert.areEqual(CASE_STATUS, record.Status, 'Status');
        Assert.areEqual(contactId, record.ContactId, 'ContactId');
        Assert.areEqual(accountId, record.AccountId, 'AccountId');
    }

    private static Case findIntake(List<Case> cases) {
        for (Case record : cases) {
            if (record.Subject == null || !record.Subject.startsWith(LeadToCaseService.ONBOARDING_SUBJECT_PREFIX)) {
                return record;
            }
        }
        Assert.fail('Intake case was not created');
        return null;
    }

    private static Case findOnboarding(List<Case> cases) {
        for (Case record : cases) {
            if (record.Subject != null && record.Subject.startsWith(LeadToCaseService.ONBOARDING_SUBJECT_PREFIX)) {
                return record;
            }
        }
        Assert.fail('Onboarding case was not created');
        return null;
    }

    private static Lead priorVersion(Lead current) {
        Lead prior = current.clone(true, true, true, true);
        prior.IsConverted = false;
        return prior;
    }

    private static Lead supportShape(Lead source, Contact contact) {
        Lead shaped = source.clone(true, true, true, true);
        shaped.Request_Type__c = 'Support';
        shaped.IsConverted = true;
        shaped.ConvertedContactId = contact.Id;
        shaped.ConvertedAccountId = contact.AccountId;
        return shaped;
    }
}
