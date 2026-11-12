@isTest
private class LlmClientTest {
    @isTest
    static void maskSensitiveDataHidesEmailPhoneAndCard() {
        String raw = 'Email agent.demo@example.com phone 555-010-0199 card 4111111111111111 case 00001001';

        String masked = LlmClient.maskSensitiveData(raw);

        Assert.isTrue(masked.contains('[email]'), masked);
        Assert.isTrue(masked.contains('[phone]'), masked);
        Assert.isTrue(masked.contains('[card]'), masked);
        Assert.isTrue(masked.contains('00001001'), masked);
        Assert.isFalse(masked.contains('agent.demo@example.com'), masked);
        Assert.isFalse(masked.contains('555-010-0199'), masked);
        Assert.isFalse(masked.contains('4111111111111111'), masked);
        Assert.areEqual(null, LlmClient.maskSensitiveData(null), 'Null stays null');
    }

    @isTest
    static void parseResponseReadsA200Body() {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setBody(
            '{"model":"servicegenie-draft","choices":[{"message":{"content":"Thanks for the synthetic note."}}]}'
        );

        LlmClient.LlmCompletion completion = LlmClient.parseResponse(response);

        Assert.isTrue(completion.success, 'Success');
        Assert.areEqual(200, completion.statusCode, 'Status');
        Assert.areEqual('Thanks for the synthetic note.', completion.text, 'Draft text');
        Assert.areEqual('servicegenie-draft', completion.modelName, 'Model');
    }

    @isTest
    static void parseResponseReports429() {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(429);
        response.setBody('{"error":"busy"}');

        LlmClient.LlmCompletion completion = LlmClient.parseResponse(response);

        Assert.isFalse(completion.success, 'Not stored as a success');
        Assert.areEqual('The model is busy. Try again later.', completion.errorMessage, '429');
        Assert.isTrue(String.isBlank(completion.text), 'No draft text');
    }

    @isTest
    static void parseResponseReports500() {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(500);
        response.setBody('{"error":"down"}');

        LlmClient.LlmCompletion completion = LlmClient.parseResponse(response);

        Assert.isFalse(completion.success, 'Not stored as a success');
        Assert.areEqual('The model could not generate a draft.', completion.errorMessage, '500');
    }

    @isTest
    static void completeSendsMaskedBodyThroughTheNamedCredential() {
        CapturingMock mock = new CapturingMock();
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        LlmClient.LlmCompletion completion = LlmClient.complete(
            'Email agent.demo@example.com phone (555) 010-0199 card 4111-1111-1111-1111 case 00001001'
        );
        Test.stopTest();

        Assert.isTrue(completion.success, completion.errorMessage);
        Assert.areEqual('callout:LLM_API/v1/chat/completions', mock.endpoint, 'Named credential');
        Assert.areEqual('POST', mock.method, 'Method');
        Assert.isNull(mock.authorization, 'Apex does not set the secret header');
        Assert.isFalse(mock.endpoint.contains('https://'), mock.endpoint);
        Assert.isTrue(mock.body.contains('[email]'), mock.body);
        Assert.isTrue(mock.body.contains('[phone]'), mock.body);
        Assert.isTrue(mock.body.contains('[card]'), mock.body);
        Assert.isTrue(mock.body.contains('00001001'), mock.body);
        Assert.isFalse(mock.body.contains('agent.demo@example.com'), mock.body);
        Assert.isFalse(mock.body.contains('4111-1111-1111-1111'), mock.body);
    }

    @isTest
    static void completeSurfacesATimeout() {
        Test.setMock(HttpCalloutMock.class, new TimeoutMock());

        Test.startTest();
        try {
            LlmClient.complete('Synthetic prompt');
            Assert.fail('Expected a timeout');
        } catch (CalloutException ex) {
            Assert.isTrue(ex.getMessage().contains('timed out'), ex.getMessage());
        }
        Test.stopTest();
    }

    private class CapturingMock implements HttpCalloutMock {
        public String endpoint;
        public String body;
        public String method;
        public String authorization;

        public HttpResponse respond(HttpRequest request) {
            endpoint = request.getEndpoint();
            body = request.getBody();
            method = request.getMethod();
            authorization = request.getHeader('Authorization');
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody(
                '{"model":"servicegenie-draft","choices":[{"message":{"content":"Thanks for the synthetic note."}}]}'
            );
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
