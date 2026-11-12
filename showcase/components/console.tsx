"use client";

import { Heading, Reveal, Section } from "./motion";

export function Console() {
  return (
    <Section id="console">
      <Heading
        eyebrow="Service Console"
        title="One LWC, four states, and a layout study of the agent workspace."
        lede="caseAssistant is the only Lightning Web Component. This panel follows the regions in source. The Case Lightning page is undeployed from this workspace, so the panel is a layout study of synthetic demo data, not an org screenshot."
      />

      <Reveal className="mt-10">
        <div className="overflow-hidden rounded-3xl border border-white/10 bg-[#0a1628] shadow-[0_40px_120px_-50px_rgba(27,150,255,0.55)]">
          <div className="flex items-center justify-between border-b border-white/10 px-4 py-3">
            <div className="flex items-center gap-2">
              <span className="size-2.5 rounded-full bg-rose-400/80" />
              <span className="size-2.5 rounded-full bg-amber-300/80" />
              <span className="size-2.5 rounded-full bg-emerald-400/80" />
              <p className="ml-3 text-xs text-slate-400">Service Console · Case Assistant</p>
            </div>
            <p className="text-[11px] uppercase tracking-[0.16em] text-slate-500">Layout study</p>
          </div>
          <div className="border-b border-white/10 px-5 py-4">
            <div className="flex flex-wrap items-start justify-between gap-4">
              <div>
                <p className="font-mono text-xs text-sky-300">Case · synthetic</p>
                <h3 className="mt-1 text-xl font-semibold text-white">Synthetic printer issue</h3>
                <p className="mt-1 text-sm text-slate-400">Opened today · Origin Web</p>
              </div>
              <div className="flex flex-wrap gap-2">
                <span className="rounded-full bg-rose-400/15 px-3 py-1 text-xs font-medium text-rose-200">
                  High
                </span>
                <span className="rounded-full bg-sky-400/15 px-3 py-1 text-xs font-medium text-sky-200">
                  New
                </span>
              </div>
            </div>
          </div>
          <div className="grid gap-px bg-white/10 lg:grid-cols-3">
            <div className="bg-[#0c1b30] p-5">
              <p className="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">
                Customer
              </p>
              <p className="mt-3 text-sm font-medium text-white">Casey Demo</p>
              <p className="text-sm text-slate-400">casey.demo@example.com</p>
              <p className="mt-1 text-sm text-slate-400">Example Household</p>
              <p className="mt-5 text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">
                History
              </p>
              <p className="mt-2 text-sm leading-relaxed text-slate-300">
                No recent activity on this case.
              </p>
              <p className="mt-5 text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">
                Recent cases
              </p>
              <p className="mt-2 text-sm text-slate-300">Up to five related cases, when the contact has them.</p>
            </div>
            <div className="bg-[#0c1b30] p-5">
              <p className="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">
                Draft
              </p>
              <p className="mt-3 text-sm text-slate-300">
                Status <span className="text-amber-200">Draft</span> after generate. Original and
                edited text both start as the model reply. The agent can edit before approval.
              </p>
              <div className="mt-4 rounded-xl border border-white/10 bg-white/[0.03] p-3 text-sm text-slate-200">
                Thanks for the note about the synthetic printer. A person will confirm the next step.
              </div>
              <div className="mt-4 flex flex-wrap gap-2">
                {["Refresh", "Generate draft", "Approve", "Reject"].map((label) => (
                  <span
                    key={label}
                    className="rounded-md border border-white/15 px-2.5 py-1 text-xs text-slate-200"
                  >
                    {label}
                  </span>
                ))}
              </div>
            </div>
            <div className="bg-[#0c1b30] p-5">
              <p className="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">
                Next best action
              </p>
              <p className="mt-3 text-sm font-semibold text-white">High Priority New</p>
              <p className="mt-2 text-sm leading-relaxed text-slate-300">
                Rule High Priority New matched priority High, status New, origin Web, case age 0
                days.
              </p>
              <p className="mt-2 text-sm leading-relaxed text-slate-300">
                Prepare a reply draft for this new high-priority case. A person approves it before
                any customer message.
              </p>
              <p className="mt-3 text-xs text-teal-200">
                This is a recommendation. It does not change the case or send a message.
              </p>
              <p className="mt-5 text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">
                Summary
              </p>
              <p className="mt-2 text-sm text-slate-300">No summary yet.</p>
              <span className="mt-3 inline-flex rounded-md border border-white/15 px-2.5 py-1 text-xs text-slate-200">
                Queue summary
              </span>
            </div>
          </div>
        </div>
      </Reveal>

      <div className="mt-6 grid gap-4 md:grid-cols-4">
        {[
          ["Loading", "A record id is set and the wire has not returned context or an error."],
          ["Empty", "No record id, or the case is invisible, so found is false. That is empty, not an error."],
          ["Error", "A query the user cannot run surfaces: You do not have access to this case."],
          ["Success", "found is true. Header, age, priority, status, customer, history, and actions render."],
        ].map(([title, body]) => (
          <article key={title} className="rounded-2xl border border-white/10 bg-white/[0.04] p-4">
            <h3 className="text-sm font-semibold text-white">{title}</h3>
            <p className="mt-2 text-sm leading-relaxed text-slate-300">{body}</p>
          </article>
        ))}
      </div>
      <p className="mt-4 text-sm text-slate-400">
        Case age is computed in the browser from CreatedDate: Not available, Opened today, 1 day,
        or N days. Refresh, generate, and queue summary disable one another while a request is in
        flight. The component has no send action.
      </p>
    </Section>
  );
}
