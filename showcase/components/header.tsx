"use client";

import { useState } from "react";
import { Menu, X } from "lucide-react";

const links = [
  { href: "#problem", label: "Problem" },
  { href: "#architecture", label: "Architecture" },
  { href: "#milestones", label: "Milestones" },
  { href: "#console", label: "Console" },
  { href: "#governance", label: "Governance" },
  { href: "#rules", label: "Rules" },
  { href: "#evaluation", label: "Evaluation" },
  { href: "#limits", label: "Limits" },
];

export function Header() {
  const [open, setOpen] = useState(false);

  return (
    <header className="fixed inset-x-0 top-0 z-50 border-b border-white/10 bg-[#07111f]/75 backdrop-blur-xl">
      <div className="mx-auto flex h-16 max-w-6xl items-center justify-between gap-4 px-5 sm:px-8">
        <a href="#top" className="flex items-center gap-2 text-sm font-semibold text-white">
          <span className="grid size-7 place-items-center rounded-lg bg-gradient-to-br from-sky-400 to-violet-500 text-xs font-bold text-[#07111f]">
            SG
          </span>
          ServiceGenie
          <span className="hidden text-slate-400 sm:inline">Case study</span>
        </a>
        <nav className="hidden items-center gap-5 lg:flex" aria-label="Page">
          {links.map((link) => (
            <a
              key={link.href}
              href={link.href}
              className="text-sm text-slate-300 transition hover:text-white"
            >
              {link.label}
            </a>
          ))}
        </nav>
        <button
          type="button"
          className="grid size-10 place-items-center rounded-lg border border-white/10 text-slate-200 lg:hidden"
          aria-expanded={open}
          aria-controls="mobile-nav"
          onClick={() => setOpen((value) => !value)}
        >
          <span className="sr-only">Menu</span>
          {open ? <X className="size-5" /> : <Menu className="size-5" />}
        </button>
      </div>
      {open ? (
        <nav
          id="mobile-nav"
          className="border-t border-white/10 bg-[#07111f] px-5 py-4 lg:hidden"
          aria-label="Page"
        >
          <ul className="grid gap-1">
            {links.map((link) => (
              <li key={link.href}>
                <a
                  href={link.href}
                  className="block rounded-lg px-3 py-2 text-sm text-slate-200 hover:bg-white/5"
                  onClick={() => setOpen(false)}
                >
                  {link.label}
                </a>
              </li>
            ))}
          </ul>
        </nav>
      ) : null}
    </header>
  );
}
