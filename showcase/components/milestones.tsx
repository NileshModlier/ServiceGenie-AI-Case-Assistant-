"use client";

import { Heading, Reveal, Section } from "./motion";

const milestones = [
  {
    id: "M1",
    title: "Foundation",
    status: "In the repository",
    body: "Salesforce DX source, API 68.0, empty namespace, architecture, object model, standards, AI governance, org setup, and the Python checks that keep those documents honest.",
  },
  {
    id: "M2",
    title: "Lead to case",
    status: "In source, awaiting an org",
    body: "Lead.Request_Type__c, Case.Source_Lead__c, the Routed to Support lead status, LeadTrigger, LeadTriggerHandler, and LeadToCaseService. Behavior from this milestone stays as specified.",
  },
  {
    id: "M3",
    title: "Apex test layer",
    status: "Coverage unmeasured",
    body: "TestDataFactory, unit, negative, and bulk tests. CI runs the Python suite and the LWC Jest suite. Apex coverage waits on an authorized org. The 85% goal is unclaimed.",
  },
  {
    id: "M4",
    title: "Service Console",
    status: "Jest runs locally",
    body: "CaseAssistController and the caseAssistant LWC. Context, customer, history, recent cases, and the four UI states. The record page itself is undeployed from this workspace.",
  },
  {
    id: "M5",
    title: "Drafts and credentials",
    status: "Credential files undeployed",
    body: "LlmClient, DraftService, and AI_Draft__c. Generate, approve, and reject. Named Credential LLM_API and External Credential LLM_External are documented for Setup.",
  },
  {
    id: "M6",
    title: "Rules and summaries",
    status: "Local evaluation has run",
    body: "Eight NBA_Rule__mdt records, NbaService, SafetyFilter, and SummaryQueueable. The console shows one recommendation and can queue a summary. It does not decide the case.",
  },
];

const classes = [
  ["LeadTriggerHandler", "Routes trigger events into the service."],
  ["LeadToCaseService", "Creates the intake and onboarding cases."],
  ["TestDataFactory", "Builds synthetic example.com rows for tests."],
  ["CaseAssistController", "Case context, drafts, the rule, and the summary job."],
  ["LlmClient", "Masks, calls out, and parses the model response."],
  ["DraftService", "Writes AI_Draft__c and records the human decision."],
  ["SafetyFilter", "Blocks injection and unsafe text before storage."],
  ["NbaService", "Returns the first matching custom metadata rule."],
  ["SummaryService", "Builds prompts, filters, and stores three case fields."],
  ["SummaryQueueable", "Allows callouts, batches of five, chains retries."],
];

const tests = [
  ["LeadToCaseServiceTest", "Intake, conversion, bulk, duplicates, and negatives."],
  ["CaseAssistControllerTest", "Empty, populated, customerless, and missing cases."],
  ["LlmClientTest", "Masking, 200, 429, 500, the named-credential call, and timeout."],
  ["DraftServiceTest", "Generate, busy, server error, timeout, approve, and reject."],
  ["NbaServiceTest", "The eight rules, including a closed case with no match."],
  ["SummaryServiceTest", "Stored text, blocked injection, blocked unsafe text, retry, and chaining."],
];

export function Milestones() {
  return (
    <Section id="milestones">
      <Heading
        eyebrow="Build record"
        title="Six milestones, all present in source."
        lede="Each phase is in the repository. Apex tests and the Service Console page still need a Developer Edition org the workspace has not authorized. The Salesforce CLI is unavailable here."
      />
      <ol className="mt-10 grid gap-4 md:grid-cols-2">
        {milestones.map((item, index) => (
          <li key={item.id}>
            <Reveal delay={index * 0.04} className="h-full">
              <article className="flex h-full gap-4 rounded-2xl border border-white/10 bg-white/[0.04] p-5">
                <p className="font-mono text-sm font-semibold text-sky-300">{item.id}</p>
                <div>
                  <h3 className="text-lg font-semibold text-white">{item.title}</h3>
                  <p className="mt-1 text-xs font-medium uppercase tracking-[0.14em] text-teal-200">
                    {item.status}
                  </p>
                  <p className="mt-2 text-sm leading-relaxed text-slate-300">{item.body}</p>
                </div>
              </article>
            </Reveal>
          </li>
        ))}
      </ol>

      <div id="apex" className="scroll-mt-24 mt-16">
        <Reveal>
          <h3 className="text-2xl font-semibold text-white">Apex surface</h3>
          <p className="mt-3 max-w-3xl text-sm leading-relaxed text-slate-300">
            Ten production classes and six test classes. Sharing is enforced with{" "}
            <span className="font-mono text-sky-200">with sharing</span>, queries use{" "}
            <span className="font-mono text-sky-200">WITH USER_MODE</span>, and draft and summary
            DML uses <span className="font-mono text-sky-200">as user</span>. No test uses
            SeeAllData.
          </p>
        </Reveal>
        <div className="mt-6 grid gap-3 sm:grid-cols-2">
          {classes.map(([name, detail]) => (
            <article
              key={name}
              className="rounded-xl border border-white/10 bg-[#0c1a2e]/70 px-4 py-3"
            >
              <p className="font-mono text-sm text-sky-200">{name}</p>
              <p className="mt-1 text-sm text-slate-300">{detail}</p>
            </article>
          ))}
        </div>
        <div className="mt-6 grid gap-3 sm:grid-cols-2">
          {tests.map(([name, detail]) => (
            <article
              key={name}
              className="rounded-xl border border-violet-300/20 bg-violet-400/[0.05] px-4 py-3"
            >
              <p className="font-mono text-sm text-violet-200">{name}</p>
              <p className="mt-1 text-sm text-slate-300">{detail}</p>
            </article>
          ))}
        </div>
        <p className="mt-4 text-sm text-slate-400">
          HttpCalloutMock covers the draft and summary callouts. Those Apex tests are written and
          have not been executed in an org from this workspace. Jest for the LWC is 7 tests,
          passed locally. The Python foundation and evaluation suite is 79 tests, passed locally.
        </p>
      </div>
    </Section>
  );
}
