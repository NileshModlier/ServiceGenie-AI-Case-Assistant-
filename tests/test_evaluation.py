"""Runs the local summary, injection, and unsafe-content evaluations."""

from __future__ import annotations

import unittest

from evaluations.evaluate import block_reason, evaluate_summary, load_cases, run, write_results

CASES = load_cases()


class SummaryEvaluationTests(unittest.TestCase):
    pass


class InjectionEvaluationTests(unittest.TestCase):
    pass


class UnsafeEvaluationTests(unittest.TestCase):
    pass


def _summary_test(case: dict):
    def run_case(self) -> None:
        self.assertTrue(evaluate_summary(case), case["id"])

    return run_case


def _block_test(case: dict, expected: str):
    def run_case(self) -> None:
        self.assertEqual(expected, block_reason(case["text"]), case["id"])

    return run_case


for summary_case in CASES["summaries"]:
    setattr(
        SummaryEvaluationTests,
        "test_" + summary_case["id"],
        _summary_test(summary_case),
    )

for injection_case in CASES["injections"]:
    setattr(
        InjectionEvaluationTests,
        "test_" + injection_case["id"],
        _block_test(injection_case, "injection"),
    )

for unsafe_case in CASES["unsafe"]:
    setattr(
        UnsafeEvaluationTests,
        "test_" + unsafe_case["id"],
        _block_test(unsafe_case, "unsafe"),
    )


class EvaluationMetricTests(unittest.TestCase):
    def test_metrics_are_complete(self) -> None:
        results = write_results()
        self.assertEqual(20, results["summaryTotal"])
        self.assertEqual(20, results["correctSummaries"])
        self.assertEqual(10, results["injectionTotal"])
        self.assertEqual(10, results["blockedInjections"])
        self.assertEqual(10, results["unsafeTotal"])
        self.assertEqual(10, results["blockedUnsafe"])
        self.assertEqual(0, results["autonomousApprovals"])
        self.assertEqual(0, results["approvalRate"])
        self.assertEqual(results["maskingChecks"], results["maskingCompliant"])
        self.assertGreater(results["maskingChecks"], 0)
        self.assertGreaterEqual(results["latencyMs"], 0)
        self.assertTrue(results["patternsPresentInApex"])


if __name__ == "__main__":
    unittest.main()
