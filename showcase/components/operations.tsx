"use client";

import { Heading, Reveal, Section } from "./motion";

const rules = [
  ["10", "High Priority New", "Priority High, status New", "Prepare a draft a person approves."],
  ["15", "Escalated + Waiting", "Status Escalated", "A person reviews the escalation."],
  ["25", "Recently Reopened", "Working, age 30 days or less, prior closed case", "A person confirms whether the issue returned."],
  ["35", "Customer Waiting", "Working, origin Email", "Draft a reply for a person to approve."],
  ["45", "Open > 7 Days", "Open, older than 7 days", "A person decides whether to follow up."],
  ["55", "Web New", "Status New, origin Web", "Confirm the web request and draft a response."],
  ["65", "Phone High", "Priority High, origin Phone", "Return the call with a draft a person approves."],
  ["80", "Working Case", "Status Working", "Continue the case. Updates wait for an approved draft."],
];

const metrics = [
  ["20 / 20", "Summary fixtures judged correct by the local checker"],
  ["10 / 10", "Prompt-injection fixtures blocked"],
  ["10 / 10", "Unsafe-content fixtures blocked"],
  ["17 / 20", "Summaries stored. Three fixtures are blocked on purpose"],
  ["7 / 7", "Masking checks compliant when the prompt holds an email or a card-like number"],
  ["0", "Autonomous approvals. The approval rate in this evaluation is that count"],
  ["7", "Jest tests passed locally for caseAssistant"],
  ["79", "Python tests passed locally, including the evaluation suite"],
];

export function Operations() {
  return (
    <>
      <Section id="rules">
        <Heading
          eyebrow="Next best actions"
          title="Eight rules. The first match wins. Nothing runs."
          lede="NbaService reads NBA_Rule__mdt in sort order and returns the rule name, the action, and a reason. Blank priority, status, or origin means any value. A closed case does not match a rule whose status is blank. The model is not called for this card."
        />
        <div className="mt-8 w-full max-w-full overflow-x-auto rounded-2xl border border-white/10">
          <table className="w-full min-w-[720px] text-left text-sm">
            <caption className="sr-only">NBA rules in source</caption>
            <thead className="bg-white/[0.04] text-xs uppercase tracking-[0.14em] text-slate-400">
              <tr>
                <th className="px-4 py-3 font-medium">Sort</th>
                <th className="px-4 py-3 font-medium">Rule</th>
                <th className="px-4 py-3 font-medium">Match</th>
                <th className="px-4 py-3 font-medium">What the agent reads</th>
              </tr>
            </thead>
            <tbody>
              {rules.map((row) => (
                <tr key={row[1]} className="border-t border-white/10">
                  {row.map((cell) => (
                    <td key={cell} className="px-4 py-3 align-top text-slate-200">
                      {cell}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <p className="mt-4 max-w-3xl text-sm leading-relaxed text-slate-400">
          Escalated + Waiting uses the standard status Escalated. The project does not replace
          Case statuses, so there is no separate Waiting value. Customer Waiting is a working
          email case. Recently Reopened is a working case, at most 30 days old, whose contact
          already has another closed case. No match returns the name “No matching rule”.
        </p>

        <div className="mt-12">
          <Reveal>
            <h3 className="text-2xl font-semibold text-white">Queueable summaries</h3>
            <p className="mt-3 max-w-3xl text-sm leading-relaxed text-slate-300">
              The agent presses Queue summary on the open case. CaseAssistController enqueues
              SummaryQueueable, which implements Queueable and Database.AllowsCallouts. The job
              writes Latest_Summary__c, Summary_Timestamp__c, and Summary_Model_Name__c. Case
              status stays unchanged.
            </p>
          </Reveal>
          <ol className="mt-6 grid gap-3 md:grid-cols-4">
            {[
              ["Batch of 5", "The job takes the minimum of the batch size, the remaining callout room, and the pending ids."],
              ["One chain", "Failed ids retry with the remainder, up to 3 attempts. Only one enqueue happens per execution."],
              ["Filter first", "SafetyFilter drops injection in the prompt and unsafe text in the model reply. Those ids are not retried."],
              ["Person starts it", "urgentIds can list up to 50 open High or Escalated cases. No trigger and no schedule calls it."],
            ].map(([title, body], index) => (
              <li key={title}>
                <article className="h-full rounded-2xl border border-white/10 bg-white/[0.04] p-4">
                  <p className="font-mono text-xs text-sky-300">0{index + 1}</p>
                  <h4 className="mt-2 text-sm font-semibold text-white">{title}</h4>
                  <p className="mt-2 text-sm leading-relaxed text-slate-300">{body}</p>
                </article>
              </li>
            ))}
          </ol>
          <p className="mt-4 text-sm text-slate-400">
            If callout room is already zero, the job returns. It does not enqueue itself again.
            Until LLM_API exists in the org, a live summary fails the callout, retries, and stores
            nothing.
          </p>
        </div>
      </Section>

      <Section id="evaluation">
        <Heading
          eyebrow="Evaluation"
          title="Forty scenarios, scored on the fixtures, with zero autonomous approvals."
          lede="evaluations/evaluate.py and evaluations/cases.json run without an org and without a live model. The checker mirrors the Apex mask and SafetyFilter. A Python test requires the filter phrases in SafetyFilter.cls to match the checker."
        />
        <div className="mt-8 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          {metrics.map(([value, label], index) => (
            <Reveal key={label} delay={index * 0.03}>
              <article className="h-full rounded-2xl border border-white/10 bg-gradient-to-br from-white/[0.05] to-transparent p-4">
                <p className="font-mono text-2xl font-semibold text-teal-200">{value}</p>
                <p className="mt-2 text-sm leading-relaxed text-slate-300">{label}</p>
              </article>
            </Reveal>
          ))}
        </div>
        <div className="mt-6 grid gap-4 md:grid-cols-2">
          <article className="rounded-2xl border border-white/10 bg-white/[0.04] p-5">
            <h3 className="text-base font-semibold text-white">What “correct” means here</h3>
            <p className="mt-2 text-sm leading-relaxed text-slate-300">
              A stored summary must contain the fixture’s required phrase, lack the forbidden
              phrase, and contain no raw email after masking. Three of the twenty summary fixtures
              are blocked on purpose: injection in the subject, a model reply that says to send
              the email, and a subject about an API key. Blocked rows are a pass for those
              fixtures, and they are absent from the 17 stored summaries.
            </p>
          </article>
          <article className="rounded-2xl border border-white/10 bg-white/[0.04] p-5">
            <h3 className="text-base font-semibold text-white">What the timing figure is</h3>
            <p className="mt-2 text-sm leading-relaxed text-slate-300">
              latest_results.json records the local check time. That run finishes in under a
              second, and re-running the suite rewrites the file. It is the checker’s own clock.
              It is not a model round trip, and this workspace has made no live call through
              LLM_API.
            </p>
          </article>
        </div>
      </Section>
    </>
  );
}
