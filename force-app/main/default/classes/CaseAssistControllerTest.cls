@isTest
private class CaseAssistControllerTest {
    @isTest
    static void nullCaseIdReturnsEmptyContext() {
        CaseAssistController.CaseContext context = CaseAssistController.getCaseContext(null);

        Assert.isFalse(context.found, 'A missing case id is empty');
        Assert.isNull(context.caseRecord, 'Case');
        Assert.isNull(context.contact, 'Contact');
        Assert.isNull(context.account, 'Account');
        Assert.areEqual(0, context.recentCases.size(), 'Recent cases');
        Assert.areEqual('', context.recentActivitySummary, 'Recent activity summary');
        Assert.areEqual(context.found, CaseAssistController.refreshCaseContext(null).found, 'Refresh uses the same result');
    }

    @isTest
    static void caseContextReturnsCustomerHistoryAndRecentCases() {
        Account account = new Account(Name = 'Example Household');
        insert account;
        Contact contact = new Contact(
            LastName = 'Demo',
            AccountId = account.Id,
            Email = 'agent.demo@example.com'
        );
        insert contact;
        Case earlier = new Case(
            Subject = 'Earlier synthetic case',
            Status = 'New',
            Origin = 'Web',
            Priority = 'Low',
            AccountId = account.Id,
            ContactId = contact.Id
        );
        insert earlier;
        Case current = new Case(
            Subject = 'Current synthetic case',
            Status = 'Working',
            Origin = 'Web',
            Priority = 'High',
            AccountId = account.Id,
            ContactId = contact.Id
        );
        insert current;
        insert new Task(
            Subject = 'Call the household',
            WhatId = current.Id,
            Status = 'Not Started',
            ActivityDate = Date.today()
        );

        Test.startTest();
        CaseAssistController.CaseContext context = CaseAssistController.getCaseContext(current.Id);
        Test.stopTest();

        Assert.isTrue(context.found, 'Case was found');
        Assert.areEqual(current.Id, context.caseRecord.Id, 'Case');
        Assert.areEqual('Working', context.caseRecord.Status, 'Status');
        Assert.areEqual('High', context.caseRecord.Priority, 'Priority');
        Assert.isTrue(String.isNotBlank(context.caseRecord.CaseNumber), 'Case number');
        Assert.areEqual(contact.Id, context.contact.Id, 'Contact');
        Assert.areEqual('agent.demo@example.com', context.contact.Email, 'Contact email');
        Assert.areEqual(account.Id, context.account.Id, 'Account');
        Assert.areEqual('Example Household', context.account.Name, 'Account name');
        Assert.areEqual(1, context.recentCases.size(), 'Recent cases exclude the open case');
        Assert.areEqual(earlier.Id, context.recentCases[0].Id, 'Recent case');
        Assert.isTrue(context.recentActivitySummary.contains('Call the household'), 'Recent activity summary');

        CaseAssistController.CaseContext refreshed = CaseAssistController.refreshCaseContext(current.Id);
        Assert.areEqual(context.caseRecord.Id, refreshed.caseRecord.Id, 'Refresh returns the same case');
        Assert.areEqual(context.recentActivitySummary, refreshed.recentActivitySummary, 'Refresh returns the same summary');
    }

    @isTest
    static void caseWithoutCustomerHasNoRelatedRows() {
        Case current = new Case(
            Subject = 'No customer yet',
            Status = 'New',
            Origin = 'Web',
            Priority = 'Medium'
        );
        insert current;

        CaseAssistController.CaseContext context = CaseAssistController.getCaseContext(current.Id);

        Assert.isTrue(context.found, 'Case was found');
        Assert.isNull(context.contact, 'Contact');
        Assert.isNull(context.account, 'Account');
        Assert.areEqual(0, context.recentCases.size(), 'Recent cases');
        Assert.areEqual('No recent activity on this case.', context.recentActivitySummary, 'Recent activity summary');
    }

    @isTest
    static void deletedCaseReturnsEmptyContext() {
        Case current = new Case(Subject = 'Temporary synthetic case', Status = 'New', Origin = 'Web');
        insert current;
        Id caseId = current.Id;
        delete current;

        CaseAssistController.CaseContext context = CaseAssistController.getCaseContext(caseId);

        Assert.isFalse(context.found, 'Deleted case is empty');
        Assert.areEqual(0, context.recentCases.size(), 'Recent cases');
    }
}
