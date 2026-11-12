trigger LeadTrigger on Lead (before insert, after insert, after update) {
    LeadTriggerHandler.run();
}
