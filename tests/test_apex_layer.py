"""Checks that the M3 Apex test layer is present and stays inside its scope.

These tests read the repository. They do not log in to Salesforce or report an
Apex coverage percentage.
"""

from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TEST_CLASS = ROOT / "force-app/main/default/classes/LeadToCaseServiceTest.cls"
FACTORY = ROOT / "force-app/main/default/classes/TestDataFactory.cls"

REQUIRED_TESTS = (
    "singleSupportLeadCreatesOneCase",
    "bulkSupportLeadsCreateTwoHundredCases",
    "salesLeadsAreIgnored",
    "supportLeadWithoutEmailCreatesUnlinkedCase",
    "supportLeadMatchesExistingContact",
    "convertedSupportLeadCreatesOnboardingCase",
    "mixedBatchCreatesCasesOnlyForSupport",
    "mixedBulkInsertOfTwoHundredLeads",
    "duplicatePassDoesNotCreateAnotherCase",
    "emptyInputsDoNotCreateCases",
    "nullInputsHaveZeroSideEffects",
    "blankRequestTypeHasZeroSideEffects",
    "duplicateContactEmailsUseLowestId",
    "nonConversionUpdateDoesNotAddACase",
    "trimmedEmailMatchesExistingContact",
    "onboardingRecordDoesNotBlockIntakeCase",
)

FACTORY_METHODS = (
    "supportLeads",
    "salesLeads",
    "unqualifiedLeads",
    "mixedBatch",
    "existingContact",
    "caseForLead",
    "convertedSupportLead",
    "convertLead",
)

BULK_TESTS = (
    "bulkSupportLeadsCreateTwoHundredCases",
    "mixedBulkInsertOfTwoHundredLeads",
)


def apex_files() -> list[Path]:
    return [
        path
        for path in (ROOT / "force-app").rglob("*")
        if path.suffix in {".cls", ".trigger"}
    ]


def method_body(source: str, name: str) -> str:
    signature = f"static void {name}("
    start = source.find(signature)
    if start < 0:
        raise AssertionError(f"missing test method {name}")
    next_method = source.find("\n    static void ", start + len(signature))
    next_helper = source.find("\n    private static ", start + len(signature))
    candidates = [index for index in (next_method, next_helper) if index >= 0]
    end = min(candidates) if candidates else len(source)
    return source[start:end]


class ApexTestLayerTests(unittest.TestCase):
    def test_required_methods_exist(self) -> None:
        source = TEST_CLASS.read_text(encoding="utf-8")
        for name in REQUIRED_TESTS:
            self.assertIn(f"static void {name}(", source)

    def test_factory_supports_the_synthetic_shapes(self) -> None:
        source = FACTORY.read_text(encoding="utf-8")
        for name in FACTORY_METHODS:
            self.assertIn(f"static ", source)
            self.assertIn(name + "(", source)
        self.assertIn("example.com", source)
        self.assertNotIn("SeeAllData", source)

    def test_bulk_tests_record_queries_and_dml(self) -> None:
        source = TEST_CLASS.read_text(encoding="utf-8")
        for name in BULK_TESTS:
            body = method_body(source, name)
            self.assertIn("Limits.getQueries()", body, name)
            self.assertIn("Limits.getDmlStatements()", body, name)
            self.assertIn("Queries used", body, name)
            self.assertIn("DML statements used", body, name)

    def test_assertions_cover_the_case_contract(self) -> None:
        source = TEST_CLASS.read_text(encoding="utf-8")
        for token in (
            "Source_Lead__c",
            "Status",
            "ContactId",
            "AccountId",
            "Case count",
            "Duplicate prevention",
            "Onboarding case",
        ):
            self.assertIn(token, source)

    def test_apex_has_no_callouts_credentials_or_draft_object(self) -> None:
        forbidden = (
            "SeeAllData",
            "HttpRequest",
            "HttpCalloutMock",
            "callout:",
            "AI_Draft__c",
            "NamedCredential",
            "ExternalCredential",
        )
        lead_to_case = {
            "LeadToCaseService.cls",
            "LeadToCaseServiceTest.cls",
            "LeadTriggerHandler.cls",
            "TestDataFactory.cls",
            "LeadTrigger.trigger",
        }
        for path in apex_files():
            text = path.read_text(encoding="utf-8")
            self.assertNotIn("SeeAllData", text, path.name)
            if path.name not in lead_to_case:
                continue
            for token in forbidden:
                self.assertNotIn(token, text, f"{path.name} contains {token}")


if __name__ == "__main__":
    unittest.main()
