@isTest
private class DraftServiceTest {
    @isTest
    static void generateDraftStoresADraftAndDoesNotSend() {
        Id caseId = caseWithSensitiveContext();
        CapturingMock mock = new CapturingMock(200, successBody());
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        AI_Draft__c draft = DraftService.generateDraft(caseId);
        Assert.areEqual(0, Limits.getEmailInvocations(), 'No email is sent');
        Test.stopTest();

        AI_Draft__c stored = [
            SELECT Status__c, Original_Draft__c, Edited_Draft__c, Prompt_Version__c,
                Model_Name__c, Approved_By__c, Approved_At__c, Case__c
            FROM AI_Draft__c
            WHERE Id = :draft.Id
        ];
        Assert.areEqual(caseId, stored.Case__c, 'Parent case');
        Assert.areEqual('Draft', stored.Status__c, 'Status');
        Assert.areEqual('Thanks for the synthetic note.', stored.Original_Draft__c, 'Original draft');
        Assert.areEqual(stored.Original_Draft__c, stored.Edited_Draft__c, 'Edited starts as the original');
        Assert.areEqual('v1', stored.Prompt_Version__c, 'Prompt version');
        Assert.areEqual('servicegenie-draft', stored.Model_Name__c, 'Model name');
        Assert.isNull(stored.Approved_By__c, 'No approver yet');
        Assert.isNull(stored.Approved_At__c, 'No approval time yet');
        Assert.areEqual('callout:LLM_API/v1/chat/completions', mock.endpoint, 'Named credential');
        Assert.isNull(mock.authorization, 'Secret header is not set in Apex');
        Assert.isTrue(mock.body.contains('[email]'), mock.body);
        Assert.isTrue(mock.body.contains('[phone]'), mock.body);
        Assert.isTrue(mock.body.contains('[card]'), mock.body);
        Assert.isFalse(mock.body.contains('agent.demo@example.com'), mock.body);
        Assert.isFalse(mock.body.contains('4111111111111111'), mock.body);
        Case current = [SELECT CaseNumber, Status FROM Case WHERE Id = :caseId];
        Assert.areEqual('New', current.Status, 'The case status is unchanged');
        Assert.isTrue(mock.body.contains(current.CaseNumber), mock.body);
    }

    @isTest
    static void busyResponseDoesNotStoreADraft() {
        Id caseId = caseWithSensitiveContext();
        Test.setMock(HttpCalloutMock.class, new CapturingMock(429, '{"error":"busy"}'));

        Test.startTest();
        try {
            DraftService.generateDraft(caseId);
            Assert.fail('Expected a busy response');
        } catch (AuraHandledException ex) {
            Assert.areEqual('The model is busy. Try again later.', ex.getMessage());
        }
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM AI_Draft__c], 'No draft row');
    }

    @isTest
    static void serverErrorDoesNotStoreADraft() {
        Id caseId = caseWithSensitiveContext();
        Test.setMock(HttpCalloutMock.class, new CapturingMock(500, '{"error":"down"}'));

        Test.startTest();
        try {
            DraftService.generateDraft(caseId);
            Assert.fail('Expected a server error');
        } catch (AuraHandledException ex) {
            Assert.areEqual('The model could not generate a draft.', ex.getMessage());
        }
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM AI_Draft__c], 'No draft row');
    }

    @isTest
    static void timeoutDoesNotStoreADraft() {
        Id caseId = caseWithSensitiveContext();
        Test.setMock(HttpCalloutMock.class, new TimeoutMock());

        Test.startTest();
        try {
            DraftService.generateDraft(caseId);
            Assert.fail('Expected a timeout');
        } catch (AuraHandledException ex) {
            Assert.areEqual('The model request timed out.', ex.getMessage());
        }
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM AI_Draft__c], 'No draft row');
    }

    @isTest
    static void approveDraftRecordsThePersonAndDoesNotSend() {
        Id caseId = caseWithSensitiveContext();
        Test.setMock(HttpCalloutMock.class, new CapturingMock(200, successBody()));
        Test.startTest();
        AI_Draft__c draft = DraftService.generateDraft(caseId);
        AI_Draft__c approved = DraftService.approveDraft(draft.Id, 'Edited synthetic reply.');
        Assert.areEqual(0, Limits.getEmailInvocations(), 'Approval does not send email');
        Test.stopTest();

        AI_Draft__c stored = [
            SELECT Status__c, Original_Draft__c, Edited_Draft__c, Approved_By__c, Approved_At__c
            FROM AI_Draft__c
            WHERE Id = :approved.Id
        ];
        Assert.areEqual('Approved', stored.Status__c, 'Approved');
        Assert.areEqual('Thanks for the synthetic note.', stored.Original_Draft__c, 'Original stays');
        Assert.areEqual('Edited synthetic reply.', stored.Edited_Draft__c, 'Edited draft');
        Assert.areEqual(UserInfo.getUserId(), stored.Approved_By__c, 'Approver');
        Assert.isNotNull(stored.Approved_At__c, 'Approval time');
        Assert.areEqual('New', [SELECT Status FROM Case WHERE Id = :caseId].Status, 'Case is unchanged');
    }

    @isTest
    static void rejectDraftKeepsTheOriginalAndDoesNotSend() {
        Id caseId = caseWithSensitiveContext();
        Test.setMock(HttpCalloutMock.class, new CapturingMock(200, successBody()));
        Test.startTest();
        AI_Draft__c draft = DraftService.generateDraft(caseId);
        AI_Draft__c rejected = DraftService.rejectDraft(draft.Id);
        Assert.areEqual(0, Limits.getEmailInvocations(), 'Rejection does not send email');
        try {
            DraftService.approveDraft(rejected.Id, 'Should not apply');
            Assert.fail('A rejected draft cannot be approved');
        } catch (AuraHandledException ex) {
            Assert.areEqual('Only a draft can be approved.', ex.getMessage());
        }
        Test.stopTest();

        AI_Draft__c stored = [
            SELECT Status__c, Original_Draft__c, Approved_By__c, Approved_At__c
            FROM AI_Draft__c
            WHERE Id = :rejected.Id
        ];
        Assert.areEqual('Rejected', stored.Status__c, 'Rejected');
        Assert.areEqual('Thanks for the synthetic note.', stored.Original_Draft__c, 'Original stays');
        Assert.areEqual(UserInfo.getUserId(), stored.Approved_By__c, 'Approver');
        Assert.isNotNull(stored.Approved_At__c, 'Decision time');
        Assert.areEqual(1, [SELECT COUNT() FROM AI_Draft__c], 'The row is kept');
    }

    private static Id caseWithSensitiveContext() {
        Account account = new Account(Name = 'Example Household');
        insert account;
        Contact contact = new Contact(
            LastName = 'Demo',
            AccountId = account.Id,
            Email = 'agent.demo@example.com',
            Phone = '555-010-0199'
        );
        insert contact;
        Case current = new Case(
            Subject = 'Synthetic printer 4111111111111111',
            Status = 'New',
            Origin = 'Web',
            Priority = 'High',
            ContactId = contact.Id,
            AccountId = account.Id
        );
        insert current;
        return current.Id;
    }

    private static String successBody() {
        return '{"model":"servicegenie-draft","choices":[{"message":{"content":"Thanks for the synthetic note."}}]}';
    }

    private class CapturingMock implements HttpCalloutMock {
        public String endpoint;
        public String body;
        public String authorization;
        private final Integer statusCode;
        private final String responseBody;

        CapturingMock(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public HttpResponse respond(HttpRequest request) {
            endpoint = request.getEndpoint();
            body = request.getBody();
            authorization = request.getHeader('Authorization');
            HttpResponse response = new HttpResponse();
            response.setStatusCode(statusCode);
            response.setBody(responseBody);
            return response;
        }
    }

    private class TimeoutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            CalloutException timeout = new CalloutException();
            timeout.setMessage('Read timed out');
            throw timeout;
        }
    }
}
