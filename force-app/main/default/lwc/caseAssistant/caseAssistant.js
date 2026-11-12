import { LightningElement, api, wire } from 'lwc';
import getCaseContext from '@salesforce/apex/CaseAssistController.getCaseContext';
import getLatestDraft from '@salesforce/apex/CaseAssistController.getLatestDraft';
import getNextBestAction from '@salesforce/apex/CaseAssistController.getNextBestAction';
import getLatestSummary from '@salesforce/apex/CaseAssistController.getLatestSummary';
import refreshCaseContext from '@salesforce/apex/CaseAssistController.refreshCaseContext';
import generateDraft from '@salesforce/apex/CaseAssistController.generateDraft';
import approveDraft from '@salesforce/apex/CaseAssistController.approveDraft';
import rejectDraft from '@salesforce/apex/CaseAssistController.rejectDraft';
import queueSummary from '@salesforce/apex/CaseAssistController.queueSummary';

export default class CaseAssistant extends LightningElement {
    @api recordId;

    context;
    error;
    isRefreshing = false;
    isGenerating = false;
    wireDraft;
    localDraft;
    useLocalDraft = false;
    editedBody = '';
    draftError;
    recommendation;
    summary;
    summaryNotice;
    isQueueing = false;

    @wire(getCaseContext, { caseId: '$recordId' })
    wiredContext({ data, error }) {
        if (!this.recordId) {
            this.context = undefined;
            this.error = undefined;
            return;
        }
        if (data) {
            this.context = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.context = undefined;
        }
    }

    @wire(getLatestDraft, { caseId: '$recordId' })
    wiredDraft({ data, error }) {
        if (!this.recordId) {
            this.wireDraft = undefined;
            return;
        }
        if (error) {
            this.draftError = messageFrom(error);
            return;
        }
        if (data !== undefined) {
            this.wireDraft = data;
            if (!this.useLocalDraft) {
                this.editedBody = data && data.Edited_Draft__c ? data.Edited_Draft__c : '';
            }
        }
    }

    @wire(getNextBestAction, { caseId: '$recordId' })
    wiredAction({ data, error }) {
        if (!this.recordId) {
            this.recommendation = undefined;
            return;
        }
        if (data) {
            this.recommendation = data;
        } else if (error) {
            this.recommendation = undefined;
            this.draftError = messageFrom(error);
        }
    }

    @wire(getLatestSummary, { caseId: '$recordId' })
    wiredSummary({ data, error }) {
        if (!this.recordId) {
            this.summary = undefined;
            return;
        }
        if (data !== undefined) {
            this.summary = data;
        } else if (error) {
            this.summary = undefined;
            this.draftError = messageFrom(error);
        }
    }

    get isLoading() {
        return Boolean(this.recordId) && !this.error && this.context === undefined;
    }

    get isError() {
        return Boolean(this.error);
    }

    get isEmpty() {
        return !this.isLoading && !this.isError && (!this.recordId || !this.context || this.context.found !== true);
    }

    get isSuccess() {
        return Boolean(this.context) && this.context.found === true && !this.error;
    }

    get isRefreshDisabled() {
        return this.isRefreshing || this.isGenerating || this.isQueueing || !this.isSuccess;
    }

    get isGenerateDisabled() {
        return !this.isSuccess || this.isGenerating || this.isRefreshing || this.isQueueing;
    }

    get isSummaryDisabled() {
        return !this.isSuccess || this.isQueueing || this.isRefreshing || this.isGenerating;
    }

    get hasAction() {
        return Boolean(this.recommendation) && this.recommendation.ruleName !== 'No matching rule';
    }

    get ruleName() {
        return this.hasAction ? this.recommendation.ruleName : 'No matching rule';
    }

    get actionText() {
        return this.hasAction ? this.recommendation.action : 'No rule recommended an action.';
    }

    get reason() {
        return this.recommendation && this.recommendation.reason
            ? this.recommendation.reason
            : 'No active rule matched this case.';
    }

    get summaryText() {
        return this.summary && this.summary.Latest_Summary__c
            ? this.summary.Latest_Summary__c
            : 'No summary yet.';
    }

    get summaryModel() {
        return this.summary && this.summary.Summary_Model_Name__c ? this.summary.Summary_Model_Name__c : '';
    }

    get activeDraft() {
        return this.useLocalDraft ? this.localDraft : this.wireDraft;
    }

    get hasDraft() {
        return Boolean(this.activeDraft);
    }

    get draftStatus() {
        return this.hasDraft ? this.activeDraft.Status__c : '';
    }

    get originalDraft() {
        return this.hasDraft ? this.activeDraft.Original_Draft__c : '';
    }

    get isDecisionReady() {
        return this.hasDraft && this.draftStatus === 'Draft' && !this.isGenerating;
    }

    get caseNumber() {
        return this.context && this.context.caseRecord ? this.context.caseRecord.CaseNumber : '';
    }

    get subject() {
        return this.context && this.context.caseRecord && this.context.caseRecord.Subject
            ? this.context.caseRecord.Subject
            : 'No subject';
    }

    get status() {
        return this.context && this.context.caseRecord ? this.context.caseRecord.Status : '';
    }

    get priority() {
        return this.context && this.context.caseRecord && this.context.caseRecord.Priority
            ? this.context.caseRecord.Priority
            : 'No priority';
    }

    get caseAge() {
        const created = this.context && this.context.caseRecord ? this.context.caseRecord.CreatedDate : null;
        if (!created) {
            return 'Not available';
        }
        const elapsed = Date.now() - new Date(created).getTime();
        const days = Math.floor(elapsed / 86400000);
        if (days <= 0) {
            return 'Opened today';
        }
        return days === 1 ? '1 day' : days + ' days';
    }

    get customerName() {
        return this.context && this.context.contact && this.context.contact.Name
            ? this.context.contact.Name
            : 'No contact on this case';
    }

    get customerEmail() {
        return this.context && this.context.contact ? this.context.contact.Email : '';
    }

    get accountName() {
        return this.context && this.context.account && this.context.account.Name
            ? this.context.account.Name
            : 'No account on this case';
    }

    get activitySummary() {
        return this.context && this.context.recentActivitySummary
            ? this.context.recentActivitySummary
            : 'No recent activity on this case.';
    }

    get recentCases() {
        return this.context && this.context.recentCases ? this.context.recentCases : [];
    }

    get hasRecentCases() {
        return this.recentCases.length > 0;
    }

    get errorMessage() {
        return messageFrom(this.error);
    }

    async handleRefresh() {
        if (this.isRefreshDisabled) {
            return;
        }
        this.isRefreshing = true;
        try {
            this.context = await refreshCaseContext({ caseId: this.recordId });
            this.error = undefined;
        } catch (error) {
            this.error = error;
            this.context = undefined;
        } finally {
            this.isRefreshing = false;
        }
    }

    async handleGenerate() {
        if (this.isGenerateDisabled) {
            return;
        }
        this.isGenerating = true;
        this.draftError = undefined;
        try {
            this.applyDraft(await generateDraft({ caseId: this.recordId }));
        } catch (error) {
            this.draftError = messageFrom(error);
        } finally {
            this.isGenerating = false;
        }
    }

    async handleApprove() {
        if (!this.isDecisionReady) {
            return;
        }
        this.isGenerating = true;
        this.draftError = undefined;
        try {
            this.applyDraft(
                await approveDraft({
                    draftId: this.activeDraft.Id,
                    editedBody: this.editedBody
                })
            );
        } catch (error) {
            this.draftError = messageFrom(error);
        } finally {
            this.isGenerating = false;
        }
    }

    async handleReject() {
        if (!this.isDecisionReady) {
            return;
        }
        this.isGenerating = true;
        this.draftError = undefined;
        try {
            this.applyDraft(await rejectDraft({ draftId: this.activeDraft.Id }));
        } catch (error) {
            this.draftError = messageFrom(error);
        } finally {
            this.isGenerating = false;
        }
    }

    handleEditedChange(event) {
        this.editedBody = event.target.value;
    }

    async handleQueueSummary() {
        if (this.isSummaryDisabled) {
            return;
        }
        this.isQueueing = true;
        this.summaryNotice = undefined;
        try {
            await queueSummary({ caseId: this.recordId });
            this.summaryNotice = 'Summary queued. Refresh after the job finishes. It does not approve a draft or send a message.';
        } catch (error) {
            this.draftError = messageFrom(error);
        } finally {
            this.isQueueing = false;
        }
    }

    applyDraft(draft) {
        this.localDraft = draft;
        this.useLocalDraft = true;
        this.editedBody = draft && draft.Edited_Draft__c ? draft.Edited_Draft__c : '';
        this.draftError = undefined;
    }
}

function messageFrom(error) {
    if (!error) {
        return 'The case could not be loaded.';
    }
    if (Array.isArray(error.body)) {
        return error.body.map((item) => item.message).filter(Boolean).join(' ');
    }
    if (error.body && error.body.message) {
        return error.body.message;
    }
    if (error.message) {
        return error.message;
    }
    return 'The case could not be loaded.';
}
