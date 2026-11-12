public with sharing class NbaService {
    public class Recommendation {
        @AuraEnabled public String ruleName;
        @AuraEnabled public String action;
        @AuraEnabled public String reason;
    }

    public static Recommendation recommend(Id caseId) {
        if (caseId == null) {
            return none('A case is required.');
        }
        List<Case> rows = [
            SELECT Id, Priority, Status, Origin, CreatedDate, IsClosed, ContactId
            FROM Case
            WHERE Id = :caseId
            WITH USER_MODE
            LIMIT 1
        ];
        if (rows.isEmpty()) {
            return none('The case is not available.');
        }
        Case current = rows[0];
        Integer ageDays = current.CreatedDate == null
            ? 0
            : current.CreatedDate.date().daysBetween(Date.today());
        Boolean priorClosed = hasPriorClosedCase(current);
        List<NBA_Rule__mdt> rules = NBA_Rule__mdt.getAll().values();
        rules.sort(new RuleOrder());
        for (NBA_Rule__mdt rule : rules) {
            if (matches(rule, current, ageDays, priorClosed)) {
                return matched(rule, current, ageDays);
            }
        }
        return none('No active rule matched this case.');
    }

    private static Boolean matches(
        NBA_Rule__mdt rule,
        Case current,
        Integer ageDays,
        Boolean priorClosed
    ) {
        if (rule.Active__c != true) {
            return false;
        }
        if (current.IsClosed == true && String.isBlank(rule.Status__c)) {
            return false;
        }
        if (String.isNotBlank(rule.Priority__c) && rule.Priority__c != current.Priority) {
            return false;
        }
        if (String.isNotBlank(rule.Status__c) && rule.Status__c != current.Status) {
            return false;
        }
        if (String.isNotBlank(rule.Origin__c) && rule.Origin__c != current.Origin) {
            return false;
        }
        if (rule.Minimum_Case_Age_Days__c != null && ageDays <= rule.Minimum_Case_Age_Days__c) {
            return false;
        }
        if (rule.Maximum_Case_Age_Days__c != null && ageDays > rule.Maximum_Case_Age_Days__c) {
            return false;
        }
        if (rule.Requires_Prior_Closed_Case__c == true && priorClosed != true) {
            return false;
        }
        return true;
    }

    private static Boolean hasPriorClosedCase(Case current) {
        if (current.ContactId == null) {
            return false;
        }
        return [
            SELECT COUNT()
            FROM Case
            WHERE ContactId = :current.ContactId
            AND Id != :current.Id
            AND IsClosed = true
            WITH USER_MODE
        ] > 0;
    }

    private static Recommendation matched(NBA_Rule__mdt rule, Case current, Integer ageDays) {
        Recommendation recommendation = new Recommendation();
        recommendation.ruleName = rule.MasterLabel;
        recommendation.action = rule.Action_Text__c;
        recommendation.reason = 'Rule ' + rule.MasterLabel
            + ' matched priority ' + display(current.Priority)
            + ', status ' + display(current.Status)
            + ', origin ' + display(current.Origin)
            + ', case age ' + ageDays + ' days.';
        return recommendation;
    }

    private static Recommendation none(String reason) {
        Recommendation recommendation = new Recommendation();
        recommendation.ruleName = 'No matching rule';
        recommendation.action = 'No rule recommended an action.';
        recommendation.reason = reason;
        return recommendation;
    }

    private static String display(String value) {
        return String.isBlank(value) ? 'none' : value;
    }

    private class RuleOrder implements System.Comparator<NBA_Rule__mdt> {
        public Integer compare(NBA_Rule__mdt left, NBA_Rule__mdt right) {
            Decimal leftOrder = left.Sort_Order__c == null ? 999 : left.Sort_Order__c;
            Decimal rightOrder = right.Sort_Order__c == null ? 999 : right.Sort_Order__c;
            if (leftOrder == rightOrder) {
                return 0;
            }
            return leftOrder < rightOrder ? -1 : 1;
        }
    }
}
