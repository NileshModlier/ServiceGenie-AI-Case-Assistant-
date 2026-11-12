public with sharing class SummaryQueueable implements Queueable, Database.AllowsCallouts {
    public static final Integer MAX_ATTEMPTS = 3;

    private final List<Id> pending;
    private final Integer attempt;

    public SummaryQueueable(List<Id> caseIds) {
        this(caseIds, 1);
    }

    public SummaryQueueable(List<Id> caseIds, Integer attempt) {
        pending = caseIds == null ? new List<Id>() : caseIds;
        this.attempt = attempt == null || attempt < 1 ? 1 : attempt;
    }

    public void execute(QueueableContext context) {
        if (pending.isEmpty()) {
            return;
        }
        Integer room = Limits.getLimitCallouts() - Limits.getCallouts();
        Integer size = Math.min(SummaryService.BATCH_SIZE, Math.min(room, pending.size()));
        if (size <= 0) {
            return;
        }
        List<Id> batch = new List<Id>();
        List<Id> rest = new List<Id>();
        for (Integer index = 0; index < pending.size(); index++) {
            if (index < size) {
                batch.add(pending[index]);
            } else {
                rest.add(pending[index]);
            }
        }
        List<Id> failed = SummaryService.summarize(batch);
        ChainPlan next = plan(rest, failed, attempt);
        if (next.chain) {
            System.enqueueJob(new SummaryQueueable(next.caseIds, next.attempt));
        }
    }

    public static ChainPlan plan(List<Id> remaining, List<Id> failed, Integer attempt) {
        ChainPlan result = new ChainPlan();
        result.caseIds = new List<Id>();
        Integer safeAttempt = attempt == null || attempt < 1 ? 1 : attempt;
        if (failed != null && !failed.isEmpty() && safeAttempt < MAX_ATTEMPTS) {
            result.caseIds.addAll(failed);
            if (remaining != null) {
                result.caseIds.addAll(remaining);
            }
            result.attempt = safeAttempt + 1;
            result.chain = true;
            return result;
        }
        if (remaining != null) {
            result.caseIds.addAll(remaining);
        }
        result.attempt = 1;
        result.chain = !result.caseIds.isEmpty();
        return result;
    }

    public class ChainPlan {
        public List<Id> caseIds;
        public Integer attempt;
        public Boolean chain;
    }
}
