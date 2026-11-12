"use client";

import { KeyRound, ShieldCheck, UserCheck } from "lucide-react";
import { Heading, Reveal, Section } from "./motion";

const states = [
  {
    title: "Generate",
    detail:
      "DraftService loads case context, adds the customer phone with a user-mode query, and asks LlmClient for a short reply the agent can edit. The insert stores status Draft, the original text, the edited text, prompt version v1, and the model name.",
  },
  {
    title: "Approve",
    detail:
      "A standard user can approve only a Draft row. An edited body, including a blank one, replaces Edited_Draft__c. Original_Draft__c stays. Status becomes Approved, with Approved_By__c and Approved_At__c.",
  },
  {
    title: "Reject",
    detail:
      "Reject sets status Rejected and records the same person and time. Both text fields stay as they were. The row remains on the case. A non-draft cannot be approved or rejected.",
  },
];

export function Governance() {
  return (
    <Section id="governance">
      <Heading
        eyebrow="Human approval"
        title="The model proposes. A standard user decides."
        lede="AI_Draft__c is a master-detail child of Case, auto-numbered DR-{0000}, with field history. Validation rule Decision_Requires_Approver requires both the approver and the time when status is Approved or Rejected."
      />

      <div className="mt-10 grid gap-4 lg:grid-cols-[1.2fr_0.8fr]">
        <div className="grid gap-3">
          {states.map((state, index) => (
            <Reveal key={state.title} delay={index * 0.05}>
              <article className="rounded-2xl border border-white/10 bg-white/[0.04] p-5">
                <div className="flex items-center gap-3">
                  <span className="grid size-8 place-items-center rounded-full bg-sky-400/15 font-mono text-xs text-sky-200">
                    0{index + 1}
                  </span>
                  <h3 className="text-lg font-semibold text-white">{state.title}</h3>
                </div>
                <p className="mt-3 text-sm leading-relaxed text-slate-300">{state.detail}</p>
              </article>
            </Reveal>
          ))}
        </div>
        <Reveal>
          <aside className="h-full rounded-2xl border border-teal-300/30 bg-teal-300/[0.06] p-5">
            <UserCheck className="size-5 text-teal-200" aria-hidden />
            <h3 className="mt-3 text-lg font-semibold text-white">What approval changes</h3>
            <ul className="mt-3 grid gap-2 text-sm leading-relaxed text-slate-300">
              <li>The draft row records the person and the timestamp.</li>
              <li>Case status stays where the agent left it.</li>
              <li>Approved is the only status eligible for a later send.</li>
              <li>That send is absent from the controller, the LWC, and the services.</li>
              <li>A non-standard user is refused with a message that a standard user must decide.</li>
            </ul>
          </aside>
        </Reveal>
      </div>

      <div className="mt-8 grid gap-4 md:grid-cols-2">
        <article className="rounded-2xl border border-white/10 bg-[#0c1a2e] p-5">
          <div className="flex items-center gap-2 text-sky-200">
            <KeyRound className="size-4" aria-hidden />
            <h3 className="text-base font-semibold text-white">Credential architecture</h3>
          </div>
          <ol className="mt-4 grid gap-3 text-sm leading-relaxed text-slate-300">
            <li>
              <span className="text-white">External Credential LLM_External.</span> Custom protocol.
              Named principal NamedPrincipal. The Authorization header is entered in Setup as a
              bearer merge field. The secret is an org authentication parameter.
            </li>
            <li>
              <span className="text-white">Named Credential LLM_API.</span> Secured endpoint.
              Placeholder base https://llm.example.com. Generate Authorization Header is off. Apex
              appends the path.
            </li>
            <li>
              <span className="text-white">Apex.</span> The callout string is
              callout:LLM_API/v1/chat/completions. Timeout is 10 seconds. Content-Type is
              application/json. Apex sets no Authorization header.
            </li>
          </ol>
          <p className="mt-4 text-sm text-slate-400">
            The namedCredentials and externalCredentials folders contain only a placeholder. The
            manifest does not deploy credential metadata. Permission set principal access is
            documented for the day the credential exists.
          </p>
        </article>
        <article className="rounded-2xl border border-white/10 bg-[#0c1a2e] p-5">
          <div className="flex items-center gap-2 text-violet-200">
            <ShieldCheck className="size-4" aria-hidden />
            <h3 className="text-base font-semibold text-white">Masking and the audit row</h3>
          </div>
          <p className="mt-4 text-sm leading-relaxed text-slate-300">
            maskSensitiveData runs before the callout. Emails become [email]. Phone numbers become
            [phone]. Sequences of 13 to 19 digits, with optional spaces or dashes, become [card].
            An 8-digit case number stays. Summaries pass through the mask again before they are
            stored.
          </p>
          <p className="mt-3 text-sm leading-relaxed text-slate-300">
            The audit fields are Original_Draft__c, Edited_Draft__c, Status__c, Approved_By__c,
            Approved_At__c, Prompt_Version__c, and Model_Name__c. Permission set
            ServiceGenie_AI_Draft grants create and edit, and it leaves delete off. There is no
            view-all on the draft object.
          </p>
        </article>
      </div>
    </Section>
  );
}
