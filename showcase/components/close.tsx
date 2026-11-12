"use client";

import { Heading, Section } from "./motion";

const limits = [
  {
    title: "Org authorization",
    body: "No Developer Edition org is authorized from this workspace. Deploy, Apex tests, and the Service Console page are still ahead.",
  },
  {
    title: "Coverage",
    body: "Apex coverage is unmeasured. The repository keeps an 85% goal and states that the goal is unclaimed until the org command in docs/test_strategy.md is run.",
  },
  {
    title: "Credentials",
    body: "LLM_API and LLM_External are a design. Live drafts and live summaries wait on that Setup step, with the key entered in the org.",
  },
  {
    title: "Screenshots",
    body: "The repository has no console screenshots. The Case page has not been deployed from this workspace, so this site uses a layout study.",
  },
  {
    title: "Routing gap",
    body: "A lead inserted without Support, then later edited to Support, stays unrouted. Insert and conversion of an original Support lead are the covered paths.",
  },
  {
    title: "Decisions stay human",
    body: "Recommendations display text. Summaries store text, a timestamp, and a model name. Case status, approval, and sending stay with a person.",
  },
];

const walk = [
  "Deploy manifest/package.xml to a Developer Edition org and assign ServiceGenie_Lead_To_Case and ServiceGenie_AI_Draft.",
  "Add Case Assistant to the Case record page. Create Account Example Household, contact casey.demo@example.com, and a High / New / Web case titled Synthetic printer issue.",
  "Open the case. The header shows number, subject, age, priority, and status. The rule card shows High Priority New and has no send button.",
  "Generate draft. Edit a word if you want. Approve. Status becomes Approved, the case stays New, and no email is sent. Reject is the other decision.",
  "Queue summary only after LLM_API exists in Setup. Refresh when the job finishes. The summary, timestamp, and model name appear, and the case status is still unchanged.",
  "Open a working email case for Customer Waiting, and an older low-priority phone case for Open > 7 Days.",
];

const files = [
  ["force-app/main/default/triggers/LeadTrigger.trigger", "One-line trigger body"],
  ["force-app/main/default/classes/LeadToCaseService.cls", "Intake and onboarding"],
  ["force-app/main/default/classes/CaseAssistController.cls", "Console controller"],
  ["force-app/main/default/lwc/caseAssistant/", "The only LWC"],
  ["force-app/main/default/classes/LlmClient.cls", "Mask and callout"],
  ["force-app/main/default/classes/DraftService.cls", "Draft lifecycle"],
  ["force-app/main/default/objects/AI_Draft__c/", "Audit object and validation rule"],
  ["force-app/main/default/classes/NbaService.cls", "First matching rule"],
  ["force-app/main/default/customMetadata/", "Eight NBA rule records"],
  ["force-app/main/default/classes/SummaryQueueable.cls", "Callout batch and retry"],
  ["evaluations/evaluate.py", "Local 40-scenario checker"],
  ["docs/credential_architecture.md", "External and named credential design"],
];

const disclaimer =
  "This project targets Salesforce Developer Edition only. It does not use Enterprise Edition, a sandbox, a production org, real customer data, or Agentforce.";

export function Close() {
  return (
    <>
      <Section id="limits">
        <Heading
          eyebrow="Limits of this case study"
          title="What a reviewer can rely on, and what still needs an org."
          lede="The source, the Jest run, and the Python evaluation are in this workspace. Anything that needs Salesforce CLI authorization is stated as still ahead."
        />
        <div className="mt-8 grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {limits.map((item) => (
            <article
              key={item.title}
              className="rounded-2xl border border-white/10 bg-white/[0.04] p-5"
            >
              <h3 className="text-base font-semibold text-white">{item.title}</h3>
              <p className="mt-2 text-sm leading-relaxed text-slate-300">{item.body}</p>
            </article>
          ))}
        </div>

        <div className="mt-14">
          <h3 className="text-2xl font-semibold text-white">Demo path, once an org exists</h3>
          <p className="mt-3 max-w-3xl text-sm leading-relaxed text-slate-300">
            docs/demo_script.md is the click path. This workspace has not performed it. Use
            synthetic @example.com contacts.
          </p>
          <ol className="mt-6 grid gap-3">
            {walk.map((step, index) => (
              <li
                key={step}
                className="grid grid-cols-[auto_1fr] gap-4 rounded-2xl border border-white/10 bg-white/[0.03] p-4"
              >
                <span className="font-mono text-sm text-sky-300">0{index + 1}</span>
                <p className="text-sm leading-relaxed text-slate-200">{step}</p>
              </li>
            ))}
          </ol>
        </div>

        <div className="mt-14">
          <h3 className="text-2xl font-semibold text-white">Where to read the source</h3>
          <ul className="mt-6 grid gap-2 sm:grid-cols-2">
            {files.map(([path, note]) => (
              <li
                key={path}
                className="rounded-xl border border-white/10 bg-[#0c1a2e] px-4 py-3"
              >
                <p className="font-mono text-xs text-sky-200">{path}</p>
                <p className="mt-1 text-sm text-slate-300">{note}</p>
              </li>
            ))}
          </ul>
        </div>
      </Section>

      <footer className="border-t border-white/10 px-5 py-12 sm:px-8">
        <div className="mx-auto max-w-6xl">
          <p className="text-sm font-semibold text-white">ServiceGenie AI Case Assistant</p>
          <p className="mt-3 max-w-3xl text-sm leading-relaxed text-slate-300">{disclaimer}</p>
          <p className="mt-4 max-w-3xl text-sm leading-relaxed text-slate-400">
            Prepared 12 November 2026 as a recruiter case study of this repository. API 68.0.
            Empty namespace. Synthetic demo data uses example.com. Secrets stay out of source.
            The showcase site lives in showcase/ so the Salesforce DX project and its Jest
            package remain at the repository root.
          </p>
        </div>
      </footer>
    </>
  );
}
