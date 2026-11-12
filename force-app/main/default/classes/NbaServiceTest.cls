@isTest
private class NbaServiceTest {
    @isTest
    static void highPriorityNewMatchesTheFirstRule() {
        Case current = insertCase('Synthetic printer', 'New', 'High', 'Web', null);
        NbaService.Recommendation recommendation = NbaService.recommend(current.Id);
        Assert.areEqual('High Priority New', recommendation.ruleName, recommendation.reason);
        Assert.isTrue(recommendation.action.contains('approves'), recommendation.action);
        Assert.areEqual('New', [SELECT Status FROM Case WHERE Id = :current.Id].Status, 'Case is unchanged');
        Assert.areEqual(0, Limits.getEmailInvocations(), 'No email');
    }

    @isTest
    static void escalatedCaseMatchesTheWaitingRule() {
        Case current = insertCase('Synthetic escalation', 'Escalated', 'Medium', 'Phone', null);
        Assert.areEqual('Escalated + Waiting', NbaService.recommend(current.Id).ruleName);
    }

    @isTest
    static void emailWorkingCaseMatchesCustomerWaiting() {
        Case current = insertCase('Synthetic email wait', 'Working', 'Low', 'Email', null);
        Assert.areEqual('Customer Waiting', NbaService.recommend(current.Id).ruleName);
    }

    @isTest
    static void oldCaseMatchesTheAgeRule() {
        Case current = insertCase('Synthetic aging case', 'Working', 'Low', 'Phone', null);
        Test.setCreatedDate(current.Id, Datetime.now().addDays(-10));
        NbaService.Recommendation recommendation = NbaService.recommend(current.Id);
        Assert.areEqual('Open > 7 Days', recommendation.ruleName, recommendation.reason);
        Assert.isTrue(recommendation.reason.contains('days'), recommendation.reason);
    }

    @isTest
    static void priorClosedCaseMatchesRecentlyReopened() {
        Account account = new Account(Name = 'Example Household');
        insert account;
        Contact contact = new Contact(
            LastName = 'Demo',
            AccountId = account.Id,
            Email = 'reopen.demo@example.com'
        );
        insert contact;
        insertCase('Earlier synthetic case', 'Closed', 'Low', 'Phone', contact.Id);
        Case current = insertCase('Synthetic return', 'Working', 'Low', 'Phone', contact.Id);
        Assert.areEqual('Recently Reopened', NbaService.recommend(current.Id).ruleName);
    }

    @isTest
    static void closedCaseHasNoRecommendation() {
        Case current = insertCase('Synthetic closed', 'Closed', 'High', 'Web', null);
        Assert.areEqual('No matching rule', NbaService.recommend(current.Id).ruleName);
        Assert.areEqual('No matching rule', NbaService.recommend(null).ruleName);
    }

    @isTest
    static void webNewAndPhoneHighUseTheirOwnRules() {
        Case web = insertCase('Synthetic web', 'New', 'Medium', 'Web', null);
        Case phone = insertCase('Synthetic phone', 'Working', 'High', 'Phone', null);
        Assert.areEqual('Web New', NbaService.recommend(web.Id).ruleName);
        Assert.areEqual('Phone High', NbaService.recommend(phone.Id).ruleName);
    }

    private static Case insertCase(String subject, String status, String priority, String origin, Id contactId) {
        Case current = new Case(
            Subject = subject,
            Status = status,
            Priority = priority,
            Origin = origin,
            ContactId = contactId
        );
        insert current;
        return current;
    }
}
