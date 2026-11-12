"use client";

import {
  ArrowDown,
  BookOpen,
  Clock3,
  Inbox,
  MessagesSquare,
  MousePointerClick,
  ShieldAlert,
} from "lucide-react";
import { Heading, Reveal, Section } from "./motion";

const steps = [
  {
    icon: Inbox,
    title: "Support Requests",
    body: "A lead arrives with Request_Type__c set to Sales or Support. Support is the path this project automates. Sales is ignored.",
  },
  {
    icon: MousePointerClick,
    title: "Manual Case Handling",
    body: "Without the trigger path, a person opens the intake case by hand, copies the lead, and decides the contact link.",
  },
  {
    icon: Clock3,
    title: "Slow Agent Response",
    body: "The agent then hunts the case, the contact, the account, recent cases, and recent tasks as separate lookups.",
  },
  {
    icon: BookOpen,
    title: "Knowledge Gaps",
    body: "Prior closed cases and the latest task stay on related records. The console has no assembled context until the controller query runs.",
  },
  {
    icon: MessagesSquare,
    title: "Inconsistent Customer Communication",
    body: "Replies differ by agent. A shared draft, a prompt version, and an approver give the reply a record before anyone considers sending it.",
  },
  {
    icon: ShieldAlert,
    title: "Operational Risk",
    body: "An unreviewed message can leave the org. Generate, approve, and reject stay with a standard user. The source contains no send.",
  },
];

export function Problem() {
  return (
    <Section id="problem">
      <Heading
        eyebrow="Business problem"
        title="Support work piles up before a person can answer well."
        lede="The case study starts with the operating chain a Service Cloud team already recognizes, then hands the request to the lead automation in source."
      />
      <div className="relative mt-12">
        <div
          className="absolute bottom-28 left-[1.15rem] top-3 w-px bg-gradient-to-b from-sky-400 via-violet-400 to-teal-300 sm:left-6"
          aria-hidden
        />
        <ol className="grid gap-4">
          {steps.map((step, index) => (
            <li key={step.title}>
              <Reveal delay={index * 0.05}>
                <article className="relative grid grid-cols-[2.3rem_1fr] gap-4 sm:grid-cols-[3rem_1fr]">
                  <span className="relative z-10 grid size-9 place-items-center rounded-full border border-sky-300/40 bg-[#0c1b30] text-sky-200 sm:size-12">
                    <step.icon className="size-4" aria-hidden />
                  </span>
                  <div className="rounded-2xl border border-white/10 bg-white/[0.04] p-5 backdrop-blur-xl">
                    <p className="text-xs font-medium uppercase tracking-[0.16em] text-slate-400">
                      0{index + 1}
                    </p>
                    <h3 className="mt-1 text-lg font-semibold text-white">{step.title}</h3>
                    <p className="mt-2 text-sm leading-relaxed text-slate-300">{step.body}</p>
                  </div>
                </article>
              </Reveal>
            </li>
          ))}
        </ol>
      </div>

      <Reveal className="mt-8">
        <div className="flex flex-col items-center gap-3 text-center">
          <p className="text-xs font-semibold uppercase tracking-[0.28em] text-teal-200">Then</p>
          <ArrowDown className="size-5 text-teal-200" aria-hidden />
          <a
            href="#architecture"
            className="w-full max-w-xl rounded-3xl border border-teal-300/30 bg-gradient-to-br from-teal-300/10 via-white/[0.04] to-sky-400/10 p-6 text-left shadow-[0_30px_80px_-40px_rgba(45,212,191,0.6)]"
          >
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-teal-200">
              The source takes the request here
            </p>
            <p className="mt-2 text-3xl font-semibold text-white">Lead</p>
            <p className="mt-2 text-sm leading-relaxed text-slate-300">
              LeadTrigger, the handler, and LeadToCaseService turn a Support lead into one intake
              case. Conversion adds one onboarding case. The Service Console reads that case next.
            </p>
          </a>
        </div>
      </Reveal>
    </Section>
  );
}
