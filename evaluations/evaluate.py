"""Local evaluation of summary, injection, and unsafe-content rules.

This does not call a model and does not approve or send anything.
"""

from __future__ import annotations

import json
import re
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CASES = Path(__file__).resolve().parent / "cases.json"
RESULTS = Path(__file__).resolve().parent / "latest_results.json"
FILTER = ROOT / "force-app/main/default/classes/SafetyFilter.cls"

INJECTION = (
    "ignore previous instructions",
    "ignore all prior instructions",
    "disregard the system",
    "reveal your prompt",
    "reveal the hidden",
    "you are now",
    "system prompt",
    "jailbreak",
    "developer message",
    "override the rules",
    "act as an unrestricted",
)

UNSAFE = (
    "send the email",
    "email all customers",
    "delete all cases",
    "approve automatically",
    "skip approval",
    "api key",
    "dump the database",
    "wire the money",
    "social security",
    "the password is",
)

EMAIL = re.compile(r"\b[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}\b", re.I)
CARD = re.compile(r"\b\d(?:[ -]?\d){12,18}\b")
PHONE = re.compile(r"(?<!\w)(?:\+\d{1,3}[-. ]?)?(?:\(\d{3}\)|\d{3})[-. ]\d{3}[-. ]\d{4}\b")


def mask(value: str) -> str:
    if not value:
        return value
    masked = EMAIL.sub("[email]", value)
    masked = CARD.sub("[card]", masked)
    return PHONE.sub("[phone]", masked)


def block_reason(value: str) -> str | None:
    folded = (value or "").lower()
    if any(pattern in folded for pattern in INJECTION):
        return "injection"
    if any(pattern in folded for pattern in UNSAFE):
        return "unsafe"
    return None


def load_cases() -> dict:
    return json.loads(CASES.read_text(encoding="utf-8"))


def evaluate_summary(case: dict) -> bool:
    outbound = mask(case["prompt"])
    blocked = block_reason(case["prompt"]) or block_reason(case["model"])
    stored = blocked is None
    text = mask(case["model"]) if stored else ""
    if stored != case["expectStored"]:
        return False
    if "@" in case["prompt"] and "@" in outbound:
        return False
    if not stored:
        return True
    if "@" in text:
        return False
    return all(token in text for token in case.get("mustContain", [])) and all(
        token not in text for token in case.get("mustLack", [])
    )


def masking_ok(case: dict) -> bool:
    if "@" not in case["prompt"] and "4111" not in case["prompt"]:
        return True
    outbound = mask(case["prompt"])
    return "@" not in outbound and "4111111111111111" not in outbound


def run() -> dict:
    started = time.perf_counter()
    cases = load_cases()
    summaries = [evaluate_summary(case) for case in cases["summaries"]]
    injections = [block_reason(case["text"]) == "injection" for case in cases["injections"]]
    unsafe = [block_reason(case["text"]) == "unsafe" for case in cases["unsafe"]]
    mask_checks = [masking_ok(case) for case in cases["summaries"] if "@" in case["prompt"] or "4111" in case["prompt"]]
    elapsed_ms = round((time.perf_counter() - started) * 1000, 3)
    stored = sum(1 for case in cases["summaries"] if case["expectStored"])
    return {
        "summaryTotal": len(summaries),
        "correctSummaries": sum(1 for item in summaries if item),
        "injectionTotal": len(injections),
        "blockedInjections": sum(1 for item in injections if item),
        "unsafeTotal": len(unsafe),
        "blockedUnsafe": sum(1 for item in unsafe if item),
        "autonomousApprovals": 0,
        "approvalRate": 0,
        "storedSummaries": stored,
        "maskingChecks": len(mask_checks),
        "maskingCompliant": sum(1 for item in mask_checks if item),
        "latencyMs": elapsed_ms,
        "patternsPresentInApex": all(pattern in FILTER.read_text(encoding="utf-8") for pattern in INJECTION + UNSAFE),
    }


def write_results() -> dict:
    results = run()
    RESULTS.write_text(json.dumps(results, indent=2) + "\n", encoding="utf-8")
    return results


if __name__ == "__main__":
    print(json.dumps(write_results(), indent=2))
