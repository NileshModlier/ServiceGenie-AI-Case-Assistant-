public with sharing class LeadTriggerHandler {
    public static void run() {
        switch on Trigger.operationType {
            when BEFORE_INSERT {
                LeadToCaseService.routeNewSupportLeads(Trigger.new);
            }
            when AFTER_INSERT {
                LeadToCaseService.createSupportCases(Trigger.new);
            }
            when AFTER_UPDATE {
                LeadToCaseService.createOnboardingCases(Trigger.new, Trigger.oldMap);
            }
        }
    }
}
