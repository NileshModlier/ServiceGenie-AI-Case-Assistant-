public with sharing class SafetyFilter {
    private static final List<String> INJECTION = new List<String>{
        'ignore previous instructions',
        'ignore all prior instructions',
        'disregard the system',
        'reveal your prompt',
        'reveal the hidden',
        'you are now',
        'system prompt',
        'jailbreak',
        'developer message',
        'override the rules',
        'act as an unrestricted'
    };

    private static final List<String> UNSAFE = new List<String>{
        'send the email',
        'email all customers',
        'delete all cases',
        'approve automatically',
        'skip approval',
        'api key',
        'dump the database',
        'wire the money',
        'social security',
        'the password is'
    };

    public static String blockReason(String text) {
        if (matches(text, INJECTION)) {
            return 'Blocked prompt injection.';
        }
        if (matches(text, UNSAFE)) {
            return 'Blocked unsafe content.';
        }
        return null;
    }

    private static Boolean matches(String text, List<String> patterns) {
        if (String.isBlank(text)) {
            return false;
        }
        String folded = text.toLowerCase();
        for (String pattern : patterns) {
            if (folded.contains(pattern)) {
                return true;
            }
        }
        return false;
    }
}
