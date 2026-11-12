public with sharing class LlmClient {
    public static final String ENDPOINT = 'callout:LLM_API/v1/chat/completions';
    public static final String PROMPT_VERSION = 'v1';
    public static final String DEFAULT_MODEL = 'servicegenie-draft';

    public class LlmCompletion {
        public Boolean success;
        public Integer statusCode;
        public String text;
        public String modelName;
        public String errorMessage;
    }

    public static LlmCompletion complete(String prompt) {
        String masked = maskSensitiveData(prompt);
        HttpRequest request = new HttpRequest();
        request.setEndpoint(ENDPOINT);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(10000);
        Map<String, Object> payload = new Map<String, Object>{
            'model' => DEFAULT_MODEL,
            'messages' => new List<Object>{
                new Map<String, Object>{
                    'role' => 'user',
                    'content' => masked
                }
            }
        };
        request.setBody(JSON.serialize(payload));
        HttpResponse response = new Http().send(request);
        return parseResponse(response);
    }

    public static LlmCompletion parseResponse(HttpResponse response) {
        LlmCompletion result = new LlmCompletion();
        result.statusCode = response == null ? null : response.getStatusCode();
        result.modelName = DEFAULT_MODEL;
        if (result.statusCode == 200) {
            result.text = extractText(response.getBody(), result);
            result.success = String.isNotBlank(result.text);
            if (!result.success) {
                result.errorMessage = 'The model response did not include draft text.';
            }
            return result;
        }
        result.success = false;
        if (result.statusCode == 429) {
            result.errorMessage = 'The model is busy. Try again later.';
        } else if (result.statusCode != null && result.statusCode >= 500) {
            result.errorMessage = 'The model could not generate a draft.';
        } else {
            result.errorMessage = 'The model request failed.';
        }
        return result;
    }

    public static String maskSensitiveData(String input) {
        if (String.isBlank(input)) {
            return input;
        }
        String masked = input.replaceAll(
            '(?i)\\b[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,}\\b',
            '[email]'
        );
        masked = masked.replaceAll('\\b\\d(?:[ -]?\\d){12,18}\\b', '[card]');
        masked = masked.replaceAll(
            '(?<!\\w)(?:\\+\\d{1,3}[-. ]?)?(?:\\(\\d{3}\\)|\\d{3})[-. ]\\d{3}[-. ]\\d{4}\\b',
            '[phone]'
        );
        return masked;
    }

    private static String extractText(String raw, LlmCompletion result) {
        if (String.isBlank(raw)) {
            return null;
        }
        Object parsed;
        try {
            parsed = JSON.deserializeUntyped(raw);
        } catch (JSONException ex) {
            return null;
        }
        if (!(parsed instanceof Map<String, Object>)) {
            return null;
        }
        Map<String, Object> payload = (Map<String, Object>) parsed;
        if (payload.get('model') instanceof String) {
            result.modelName = (String) payload.get('model');
        }
        Object choices = payload.get('choices');
        if (!(choices instanceof List<Object>) || ((List<Object>) choices).isEmpty()) {
            return null;
        }
        Object first = ((List<Object>) choices)[0];
        if (!(first instanceof Map<String, Object>)) {
            return null;
        }
        Object message = ((Map<String, Object>) first).get('message');
        if (!(message instanceof Map<String, Object>)) {
            return null;
        }
        Object content = ((Map<String, Object>) message).get('content');
        return content instanceof String ? (String) content : null;
    }
}
