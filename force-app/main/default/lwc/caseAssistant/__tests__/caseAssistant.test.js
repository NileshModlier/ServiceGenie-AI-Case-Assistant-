import { createElement } from 'lwc';
import CaseAssistant from 'c/caseAssistant';
import getCaseContext from '@salesforce/apex/CaseAssistController.getCaseContext';
import getNextBestAction from '@salesforce/apex/CaseAssistController.getNextBestAction';
import getLatestSummary from '@salesforce/apex/CaseAssistController.getLatestSummary';
import refreshCaseContext from '@salesforce/apex/CaseAssistController.refreshCaseContext';
import generateDraft from '@salesforce/apex/CaseAssistController.generateDraft';
import approveDraft from '@salesforce/apex/CaseAssistController.approveDraft';
import queueSummary from '@salesforce/apex/CaseAssistController.queueSummary';

jest.mock(
    '@salesforce/apex/CaseAssistController.getCaseContext',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return {
            default: createApexTestWireAdapter(jest.fn())
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/CaseAssistController.getLatestDraft',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return {
            default: createApexTestWireAdapter(jest.fn())
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/CaseAssistController.getNextBestAction',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return {
            default: createApexTestWireAdapter(jest.fn())
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/CaseAssistController.getLatestSummary',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return {
            default: createApexTestWireAdapter(jest.fn())
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/CaseAssistController.refreshCaseContext',
    () => ({
        default: jest.fn()
    }),
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/CaseAssistController.generateDraft',
    () => ({
        default: jest.fn()
    }),
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/CaseAssistController.approveDraft',
    () => ({
        default: jest.fn()
    }),
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/CaseAssistController.rejectDraft',
    () => ({
        default: jest.fn()
    }),
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/CaseAssistController.queueSummary',
    () => ({
        default: jest.fn()
    }),
    { virtual: true }
);

const CASE_ID = '500000000000001AAA';

const SUCCESS = {
    found: true,
    caseRecord: {
        Id: CASE_ID,
        CaseNumber: '00001001',
        Subject: 'Synthetic printer issue',
        Status: 'Working',
        Priority: 'High',
        CreatedDate: new Date().toISOString()
    },
    contact: {
        Id: '003000000000001AAA',
        Name: 'Casey Demo',
        Email: 'casey.demo@example.com'
    },
    account: {
        Id: '001000000000001AAA',
        Name: 'Example Household'
    },
    recentCases: [
        {
            Id: '500000000000002AAA',
            CaseNumber: '00001000',
            Subject: 'Earlier synthetic case',
            Status: 'New'
        }
    ],
    recentActivitySummary: '1 recent task. Latest: Call the household (Not Started).'
};

function flush() {
    return new Promise((resolve) => {
        setTimeout(resolve, 0);
    });
}

async function mount(recordId) {
    const element = createElement('c-case-assistant', { is: CaseAssistant });
    if (recordId) {
        element.recordId = recordId;
    }
    document.body.appendChild(element);
    await flush();
    return element;
}

describe('caseAssistant', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
        generateDraft.mockReset();
        approveDraft.mockReset();
        refreshCaseContext.mockReset();
        queueSummary.mockReset();
    });

    it('renders the case context', async () => {
        const element = await mount(CASE_ID);
        getCaseContext.emit(SUCCESS);
        await flush();

        expect(element.shadowRoot.querySelector('[data-state="success"]')).not.toBeNull();
        expect(element.shadowRoot.querySelector('[data-field="case-number"]').textContent).toBe('00001001');
        expect(element.shadowRoot.querySelector('[data-field="subject"]').textContent).toBe('Synthetic printer issue');
        expect(element.shadowRoot.querySelector('[data-field="case-age"]').textContent).toBe('Opened today');
        expect(element.shadowRoot.querySelector('[data-field="priority"]').textContent).toBe('High');
        expect(element.shadowRoot.querySelector('[data-field="status"]').textContent).toBe('Working');
        expect(element.shadowRoot.querySelector('[data-field="customer"]').textContent).toBe('Casey Demo');
        expect(element.shadowRoot.querySelector('[data-field="account"]').textContent).toBe('Example Household');
        expect(element.shadowRoot.querySelector('[data-field="history"]').textContent).toContain('Call the household');
        expect(element.shadowRoot.querySelector('[data-recent="500000000000002AAA"]').textContent).toContain('00001000');
        expect(element.shadowRoot.querySelector('[data-card="draft"]')).not.toBeNull();
        expect(element.shadowRoot.querySelector('[data-card="next"]')).not.toBeNull();
    });

    it('shows the loading state before data arrives', async () => {
        const element = await mount(CASE_ID);

        expect(element.shadowRoot.querySelector('[data-state="loading"]')).not.toBeNull();
        expect(element.shadowRoot.querySelector('[data-state="success"]')).toBeNull();
    });

    it('shows the error state', async () => {
        const element = await mount(CASE_ID);
        getCaseContext.error({ message: 'You do not have access to this case.' });
        await flush();

        const error = element.shadowRoot.querySelector('[data-state="error"]');
        expect(error).not.toBeNull();
        expect(error.textContent).toBe('You do not have access to this case.');
    });

    it('shows the empty state when no case is open', async () => {
        const element = await mount();

        expect(element.shadowRoot.querySelector('[data-state="empty"]')).not.toBeNull();
        expect(element.shadowRoot.querySelector('[data-state="loading"]')).toBeNull();
    });

    it('enables refresh and generate and keeps next actions disabled', async () => {
        const element = await mount(CASE_ID);
        getCaseContext.emit(SUCCESS);
        await flush();

        const refresh = element.shadowRoot.querySelector('[data-action="refresh"]');
        const draft = element.shadowRoot.querySelector('[data-action="draft"]');
        const summary = element.shadowRoot.querySelector('[data-action="summary"]');
        expect(refresh.disabled).toBe(false);
        expect(draft.disabled).toBe(false);
        expect(summary.disabled).toBe(false);
        expect(element.shadowRoot.querySelector('[data-action="next"]')).toBeNull();
        expect(element.shadowRoot.querySelector('[data-action="send"]')).toBeNull();
        expect(element.shadowRoot.querySelector('[data-field="rule-name"]').textContent).toBe('No matching rule');
        expect(element.shadowRoot.querySelector('[data-field="summary"]').textContent).toBe('No summary yet.');

        let release;
        refreshCaseContext.mockImplementation(
            () =>
                new Promise((resolve) => {
                    release = resolve;
                })
        );
        refresh.click();
        await flush();
        expect(element.shadowRoot.querySelector('[data-action="refresh"]').disabled).toBe(true);
        expect(element.shadowRoot.querySelector('[data-action="draft"]').disabled).toBe(true);

        release({
            ...SUCCESS,
            recentActivitySummary: 'No recent activity on this case.'
        });
        await flush();
        expect(element.shadowRoot.querySelector('[data-field="history"]').textContent).toBe(
            'No recent activity on this case.'
        );
        expect(element.shadowRoot.querySelector('[data-action="refresh"]').disabled).toBe(false);
        expect(element.shadowRoot.querySelector('[data-action="draft"]').disabled).toBe(false);
        expect(element.shadowRoot.querySelector('[data-action="summary"]').disabled).toBe(false);
        expect(element.shadowRoot.querySelector('[data-action="send"]')).toBeNull();
    });

    it('shows a generated draft and keeps approve from sending', async () => {
        const element = await mount(CASE_ID);
        getCaseContext.emit(SUCCESS);
        await flush();

        generateDraft.mockResolvedValue({
            Id: 'a00000000000001AAA',
            Status__c: 'Draft',
            Original_Draft__c: 'Thanks for the synthetic note.',
            Edited_Draft__c: 'Thanks for the synthetic note.'
        });
        element.shadowRoot.querySelector('[data-action="draft"]').click();
        await flush();

        expect(generateDraft).toHaveBeenCalledWith({ caseId: CASE_ID });
        expect(element.shadowRoot.querySelector('[data-field="draft-status"]').textContent).toBe('Draft');
        expect(element.shadowRoot.querySelector('[data-field="original-draft"]').textContent).toBe(
            'Thanks for the synthetic note.'
        );
        expect(element.shadowRoot.querySelector('[data-action="approve"]')).not.toBeNull();
        expect(element.shadowRoot.querySelector('[data-action="reject"]')).not.toBeNull();
        expect(element.shadowRoot.querySelector('[data-action="send"]')).toBeNull();

        approveDraft.mockResolvedValue({
            Id: 'a00000000000001AAA',
            Status__c: 'Approved',
            Original_Draft__c: 'Thanks for the synthetic note.',
            Edited_Draft__c: 'Thanks for the synthetic note.'
        });
        element.shadowRoot.querySelector('[data-action="approve"]').click();
        await flush();

        expect(approveDraft).toHaveBeenCalledWith({
            draftId: 'a00000000000001AAA',
            editedBody: 'Thanks for the synthetic note.'
        });
        expect(element.shadowRoot.querySelector('[data-field="draft-status"]').textContent).toBe('Approved');
        expect(element.shadowRoot.querySelector('[data-action="approve"]')).toBeNull();
        expect(element.shadowRoot.querySelector('[data-action="send"]')).toBeNull();
    });

    it('shows a rule recommendation and queues a summary', async () => {
        const element = await mount(CASE_ID);
        getCaseContext.emit(SUCCESS);
        getNextBestAction.emit({
            ruleName: 'High Priority New',
            action: 'Prepare a reply draft. A person approves it.',
            reason: 'Rule High Priority New matched priority High, status New, origin Web, case age 0 days.'
        });
        getLatestSummary.emit({
            Id: CASE_ID,
            Latest_Summary__c: 'The synthetic printer case is still new.',
            Summary_Model_Name__c: 'servicegenie-draft'
        });
        await flush();

        expect(element.shadowRoot.querySelector('[data-field="rule-name"]').textContent).toBe('High Priority New');
        expect(element.shadowRoot.querySelector('[data-field="reason"]').textContent).toContain('priority High');
        expect(element.shadowRoot.querySelector('[data-field="action"]').textContent).toContain('approves');
        expect(element.shadowRoot.querySelector('[data-field="summary"]').textContent).toBe(
            'The synthetic printer case is still new.'
        );
        expect(element.shadowRoot.querySelector('[data-action="send"]')).toBeNull();

        queueSummary.mockResolvedValue('707000000000001AAA');
        element.shadowRoot.querySelector('[data-action="summary"]').click();
        await flush();
        expect(queueSummary).toHaveBeenCalledWith({ caseId: CASE_ID });
        expect(element.shadowRoot.querySelector('[data-field="summary-notice"]').textContent).toContain(
            'does not approve'
        );
    });
});
