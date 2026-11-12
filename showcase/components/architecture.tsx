"use client";

import { motion, useReducedMotion } from "framer-motion";
import {
  Boxes,
  Cable,
  GitBranch,
  Inbox,
  KeyRound,
  LayoutDashboard,
  Sparkles,
  UserCheck,
  UserRound,
  Zap,
  type LucideIcon,
} from "lucide-react";
import { Heading, Reveal, Section } from "./motion";

type Node = {
  title: string;
  body: string;
  icon: LucideIcon;
  layer: string;
};

const leadPath: Node[] = [
  {
    title: "Lead",
    layer: "Sales Cloud",
    icon: UserRound,
    body: "Before insert, a Support lead moves to Routed to Support and stays unconverted. A Sales lead is left alone.",
  },
  {
    title: "Trigger",
    layer: "Apex",
    icon: Zap,
    body: "LeadTrigger is the only lead trigger. Its body calls LeadTriggerHandler.run() on before insert, after insert, and after update.",
  },
  {
    title: "Handler",
    layer: "Apex",
    icon: GitBranch,
    body: "The handler switches on Trigger.operationType and delegates. It keeps SOQL and DML out of the trigger body.",
  },
  {
    title: "Service",
    layer: "Apex",
    icon: Boxes,
    body: "LeadToCaseService runs with sharing. One support insert creates one intake case. A later conversion adds one onboarding case.",
  },
  {
    title: "Case",
    layer: "Service Cloud",
    icon: Inbox,
    body: "Intake uses the subject prefix Support:, status New, and origin Web. Onboarding uses Onboarding: and the converted contact and account.",
  },
];

const casePath: Node[] = [
  {
    title: "LWC",
    layer: "Console",
    icon: LayoutDashboard,
    body: "caseAssistant targets the Case record page and an app page. It renders loading, empty, error, and success.",
  },
  {
    title: "Controller",
    layer: "Apex",
    icon: Cable,
    body: "CaseAssistController is with sharing. Reads are cacheable wires. Generate, approve, reject, refresh, and queue summary are imperative.",
  },
  {
    title: "Named Credential",
    layer: "Integration",
    icon: KeyRound,
    body: "LlmClient posts to callout:LLM_API/v1/chat/completions. LLM_API and LLM_External are a design. The key stays in the org.",
  },
  {
    title: "LLM",
    layer: "Callout",
    icon: Sparkles,
    body: "Emails, phone numbers, and card-like numbers are masked before the call. Prompt version v1. Default model servicegenie-draft.",
  },
  {
    title: "Approval",
    layer: "Governance",
    icon: UserCheck,
    body: "A standard user approves or rejects the draft. Approved is the only status a later send could use. Send is unimplemented.",
  },
];

function NodeCard({ node, index }: { node: Node; index: number }) {
  const reduce = useReducedMotion();
  return (
    <motion.article
      initial={reduce ? false : { opacity: 0, y: 12 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-40px" }}
      transition={{ duration: 0.45, delay: index * 0.08 }}
      className="min-w-0 rounded-2xl border border-white/10 bg-[#0c1a2e]/80 p-4 shadow-[inset_0_1px_0_rgba(255,255,255,0.06)] backdrop-blur-xl"
    >
      <div className="flex items-center justify-between gap-3">
        <span className="grid size-9 place-items-center rounded-lg bg-gradient-to-br from-sky-400/20 to-violet-400/20 text-sky-200">
          <node.icon className="size-4" aria-hidden />
        </span>
        <span className="text-[10px] font-semibold uppercase tracking-[0.16em] text-teal-200">
          {node.layer}
        </span>
      </div>
      <h3 className="mt-3 text-base font-semibold text-white">{node.title}</h3>
      <p className="mt-2 text-sm leading-relaxed text-slate-300">{node.body}</p>
    </motion.article>
  );
}

function Arrow({ direction }: { direction: "right" | "left" | "down" }) {
  const reduce = useReducedMotion();
  const horizontal = direction !== "down";
  return (
    <div
      className={
        horizontal
          ? "hidden items-center justify-center lg:flex"
          : "flex items-center justify-center py-1 lg:py-0"
      }
      aria-hidden
    >
      <motion.span
        className={`block rounded-full bg-gradient-to-r from-sky-400 to-violet-400 ${
          horizontal ? "h-px w-6" : "h-6 w-px bg-gradient-to-b"
        }`}
        initial={reduce ? false : horizontal ? { scaleX: 0 } : { scaleY: 0 }}
        whileInView={horizontal ? { scaleX: 1 } : { scaleY: 1 }}
        viewport={{ once: true }}
        transition={{ duration: 0.45 }}
      />
    </div>
  );
}

export function Architecture() {
  const reverseCase = [...casePath].reverse();
  return (
    <Section id="architecture">
      <Heading
        eyebrow="Solution path"
        title="From the lead to a draft a person can approve."
        lede="The diagram is the path in source: Sales Cloud lead, one trigger, a bulk-safe service, a Service Console LWC, a named-credential callout, and a human decision on AI_Draft__c."
      />

      <div className="mt-10 hidden lg:block">
        <div className="grid grid-cols-[1fr_auto_1fr_auto_1fr_auto_1fr_auto_1fr] items-stretch gap-2">
          {leadPath.map((node, index) => (
            <div key={node.title} className="contents">
              <NodeCard node={node} index={index} />
              {index < leadPath.length - 1 ? <Arrow direction="right" /> : null}
            </div>
          ))}
        </div>
        <div className="mr-[8%] mt-2 flex justify-end">
          <Arrow direction="down" />
        </div>
        <div className="grid grid-cols-[1fr_auto_1fr_auto_1fr_auto_1fr_auto_1fr] items-stretch gap-2">
          {reverseCase.map((node, index) => (
            <div key={node.title} className="contents">
              <NodeCard node={node} index={index + 5} />
              {index < reverseCase.length - 1 ? <Arrow direction="left" /> : null}
            </div>
          ))}
        </div>
        <p className="mt-4 text-sm text-slate-400">
          Read the top row left to right, drop at Case, then read the bottom row right to left:
          LWC, Controller, Named Credential, LLM, Approval.
        </p>
      </div>

      <ol className="mt-10 grid gap-3 lg:hidden">
        {[...leadPath, ...casePath].map((node, index) => (
          <li key={node.title}>
            <NodeCard node={node} index={index} />
            {index < leadPath.length + casePath.length - 1 ? (
              <div className="flex justify-center py-2">
                <Arrow direction="down" />
              </div>
            ) : null}
          </li>
        ))}
      </ol>

      <div className="mt-10 grid gap-4 md:grid-cols-3">
        <Reveal>
          <article className="h-full rounded-2xl border border-white/10 bg-white/[0.04] p-5">
            <h3 className="text-sm font-semibold text-white">Intake and onboarding</h3>
            <p className="mt-2 text-sm leading-relaxed text-slate-300">
              A Support insert creates the intake case and keeps it. Converting that lead, when
              ConvertedContactId is present, adds a second case for onboarding. The two subject
              prefixes keep them distinct. Repeating the same event does not add another copy.
            </p>
          </article>
        </Reveal>
        <Reveal delay={0.06}>
          <article className="h-full rounded-2xl border border-white/10 bg-white/[0.04] p-5">
            <h3 className="text-sm font-semibold text-white">Contact match</h3>
            <p className="mt-2 text-sm leading-relaxed text-slate-300">
              Email is trimmed and compared in lowercase. Duplicate contacts resolve to the lowest
              Id. A blank email still creates an unlinked case. Addresses in tests use example.com.
            </p>
          </article>
        </Reveal>
        <Reveal delay={0.12}>
          <article className="h-full rounded-2xl border border-white/10 bg-white/[0.04] p-5">
            <h3 className="text-sm font-semibold text-white">Bulk budget</h3>
            <p className="mt-2 text-sm leading-relaxed text-slate-300">
              The 200-lead support test asserts queries and DML each stay between 2 and 10. The
              service queries contacts once and inserts cases once. A lead inserted as Sales or
              blank, then later edited to Support, stays unrouted.
            </p>
          </article>
        </Reveal>
      </div>
    </Section>
  );
}
