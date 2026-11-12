"use client";

import {
  BrainCircuit,
  Briefcase,
  Building2,
  Cloud,
  Code2,
  Headphones,
  Users,
} from "lucide-react";
import { CountUp, Reveal } from "./motion";

const counters = [
  { value: 16, label: "Apex Classes", tone: "text-sky-300" },
  { value: 6, label: "Apex Test Classes", tone: "text-sky-300" },
  { value: 45, label: "Apex Test Methods", tone: "text-sky-300" },
  { value: 1, label: "LWC", tone: "text-violet-300" },
  { value: 8, label: "NBA Rules", tone: "text-violet-300" },
  { value: 40, label: "AI Evaluation Scenarios", tone: "text-teal-300" },
  { value: 0, label: "Autonomous Approvals", tone: "text-teal-200" },
];

const audience = [
  { icon: Briefcase, label: "Salesforce Recruiters" },
  { icon: Code2, label: "Salesforce Developers" },
  { icon: Building2, label: "Salesforce Architects" },
  { icon: Cloud, label: "CRM Engineering Teams" },
  { icon: Headphones, label: "Service Cloud Teams" },
  { icon: Users, label: "Hiring Managers" },
  { icon: BrainCircuit, label: "AI Engineering Teams" },
];

export function Hero() {
  return (
    <section id="top" className="relative overflow-hidden px-5 pb-8 pt-28 sm:px-8 sm:pt-32">
      <div className="pointer-events-none absolute inset-0 mesh" aria-hidden />
      <div className="relative mx-auto max-w-6xl">
        <Reveal>
          <p className="inline-flex items-center gap-2 rounded-full border border-sky-400/30 bg-sky-400/10 px-3 py-1 text-xs font-medium uppercase tracking-[0.18em] text-sky-200">
            Developer Edition portfolio · API 68.0
          </p>
          <h1 className="mt-6 max-w-4xl text-4xl font-semibold tracking-tight text-white sm:text-6xl">
            ServiceGenie AI Case Assistant
          </h1>
          <p className="mt-5 max-w-3xl text-lg leading-relaxed text-slate-300 sm:text-xl">
            AI-Assisted Service Cloud Operations with Apex, LWC and Human-In-The-Loop Governance
          </p>
        </Reveal>

        <Reveal delay={0.08} className="mt-8 flex flex-wrap gap-3">
          <a
            href="#architecture"
            className="rounded-full bg-sky-500 px-5 py-2.5 text-sm font-semibold text-[#041018] transition hover:bg-sky-400"
          >
            Follow the architecture
          </a>
          <a
            href="#evaluation"
            className="rounded-full border border-white/15 bg-white/5 px-5 py-2.5 text-sm font-semibold text-white transition hover:border-white/30"
          >
            Review the evaluation
          </a>
        </Reveal>

        <ul className="mt-8 flex flex-wrap gap-2" aria-label="Audience">
          {audience.map(({ icon: Icon, label }) => (
            <li
              key={label}
              className="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/[0.04] px-3 py-1.5 text-xs text-slate-300"
            >
              <Icon className="size-3.5 text-sky-300" aria-hidden />
              {label}
            </li>
          ))}
        </ul>

        <div className="mt-10 grid grid-cols-2 gap-3 md:grid-cols-4 xl:grid-cols-7">
          {counters.map((item, index) => (
            <Reveal key={item.label} delay={index * 0.04}>
              <article
                className={`h-full rounded-2xl border px-4 py-4 backdrop-blur-xl ${
                  item.value === 0
                    ? "border-teal-300/40 bg-teal-300/[0.07]"
                    : "border-white/10 bg-white/[0.04]"
                }`}
              >
                <p className={`font-mono text-3xl font-semibold tracking-tight ${item.tone}`}>
                  <CountUp value={item.value} />
                </p>
                <p className="mt-2 text-xs leading-snug text-slate-300">{item.label}</p>
              </article>
            </Reveal>
          ))}
        </div>
        <p className="mt-4 max-w-3xl text-sm leading-relaxed text-slate-400">
          The 16 Apex classes include the 6 test classes. The 45 test methods are in source
          and still need an authorized Developer Edition org before they run. The 40 evaluation
          scenarios are a local fixture check: 20 summaries, 10 prompt-injection cases, and 10
          unsafe-content cases. Autonomous approvals stay at zero.
        </p>
      </div>
    </section>
  );
}
