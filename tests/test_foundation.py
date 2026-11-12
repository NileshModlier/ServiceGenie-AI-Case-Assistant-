"""M1 foundation checks.

These tests read the repository. They do not log in to Salesforce, deploy
metadata, or call an external model.
"""

from __future__ import annotations

import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_DOCS = (
    "docs/design.md",
    "docs/architecture.md",
    "docs/object_model.md",
    "docs/development_standards.md",
    "docs/ai_governance.md",
    "docs/test_strategy.md",
    "docs/org_setup.md",
    "docs/apex_design.md",
    "docs/bulk_processing.md",
    "docs/trigger_architecture.md",
    "README.md",
)

DISCLAIMER = (
    "This project targets Salesforce Developer Edition only. "
    "It does not use Enterprise Edition, a sandbox, a production org, "
    "real customer data, or Agentforce."
)

OBJECTS = ("Lead", "Account", "Contact", "Case", "AI_Draft__c")
OBJECT_SECTIONS = ("Purpose", "Relationships", "Ownership", "Lifecycle")


def read(relative: str) -> str:
    path = ROOT / relative
    if not path.is_file():
        raise AssertionError(f"missing file: {relative}")
    return path.read_text(encoding="utf-8")


def mermaid_blocks(text: str) -> list[str]:
    blocks = []
    marker = "```mermaid"
    start = 0
    while True:
        begin = text.find(marker, start)
        if begin < 0:
            break
        content_start = begin + len(marker)
        end = text.find("```", content_start)
        if end < 0:
            break
        blocks.append(text[content_start:end])
        start = end + 3
    return blocks


def first_positions(text: str, labels: tuple[str, ...]) -> list[int]:
    return [text.find(label) for label in labels]


class DocumentPresenceTests(unittest.TestCase):
    def test_required_documents_exist_and_are_substantial(self) -> None:
        for relative in REQUIRED_DOCS:
            text = read(relative)
            self.assertGreater(
                len(text.strip()),
                400,
                f"{relative} is too short to be a foundation document",
            )

    def test_project_files_exist(self) -> None:
        for relative in (
            "sfdx-project.json",
            "config/project-scratch-def.json",
            ".gitignore",
            ".forceignore",
            "manifest/package.xml",
            ".github/workflows/foundation.yml",
            "scripts/validate-foundation.ps1",
            "scripts/validate-foundation.sh",
        ):
            self.assertTrue((ROOT / relative).is_file(), relative)

    def test_directories_exist(self) -> None:
        for relative in (
            "servicegenie",
            "docs",
            "scripts",
            ".github/workflows",
            "force-app/main/default",
            "tests",
        ):
            self.assertTrue((ROOT / relative).is_dir(), relative)


class ArchitectureTests(unittest.TestCase):
    def test_lead_to_case_diagram(self) -> None:
        blocks = mermaid_blocks(read("docs/architecture.md"))
        labels = ("Lead", "Trigger", "Handler", "Service", "Case")
        self.assertTrue(
            any(self._in_order(block, labels) for block in blocks),
            "architecture.md needs a mermaid diagram Lead → Trigger → Handler → Service → Case",
        )

    def test_case_to_llm_diagram(self) -> None:
        blocks = mermaid_blocks(read("docs/architecture.md"))
        labels = ("Case", "LWC", "Controller", "Named Credential", "LLM")
        self.assertTrue(
            any(self._in_order(block, labels) for block in blocks),
            "architecture.md needs a mermaid diagram Case → LWC → Controller → Named Credential → LLM",
        )

    def test_named_credentials_are_deferred_to_m5(self) -> None:
        text = read("docs/architecture.md")
        self.assertIn("not configured until m5", text.lower())
        self.assertIn("External Credential", text)

    def _in_order(self, text: str, labels: tuple[str, ...]) -> bool:
        positions = first_positions(text, labels)
        return all(position >= 0 for position in positions) and positions == sorted(positions)


class ObjectModelTests(unittest.TestCase):
    def test_each_object_documents_purpose_relationships_ownership_and_lifecycle(self) -> None:
        text = read("docs/object_model.md")
        for name in OBJECTS:
            heading = f"## {name}"
            start = text.find(heading)
            self.assertGreaterEqual(start, 0, f"missing object section {name}")
            next_heading = text.find("\n## ", start + len(heading))
            section = text[start:] if next_heading < 0 else text[start:next_heading]
            for part in OBJECT_SECTIONS:
                self.assertIn(
                    f"### {part}",
                    section,
                    f"{name} is missing {part}",
                )

    def test_lead_to_case_contract(self) -> None:
        design = read("docs/design.md")
        model = read("docs/object_model.md")
        for label in (
            "Lead.Request_Type__c",
            "Case.Source_Lead__c",
            "Sales",
            "Support",
            "Routed to Support",
            "Lead Arrival",
            "Lead Qualification",
            "Support Routing",
            "Case Creation",
            "Converted Lead Handling",
        ):
            self.assertIn(label, design, f"design.md missing {label}")
            self.assertIn(label, model, f"object_model.md missing {label}")


class DevelopmentStandardsTests(unittest.TestCase):
    def test_required_rules(self) -> None:
        text = read("docs/development_standards.md")
        for heading in (
            "## One Trigger Per Object",
            "## Bulk Safe",
            "## No SOQL In Loops",
            "## No DML In Loops",
            "## Trigger Handler Pattern",
            "## No SeeAllData=true",
            "## Minimum 85% Coverage Goal",
        ):
            self.assertIn(heading, text)

    def test_coverage_goal_is_not_claimed_as_already_met(self) -> None:
        text = read("docs/development_standards.md")
        self.assertIn("not claimed as achieved", text)


class AiGovernanceTests(unittest.TestCase):
    def test_required_rules(self) -> None:
        text = read("docs/ai_governance.md")
        for heading in (
            "## Human Approval Required",
            "## No Automatic Sending",
            "## No Customer Data",
            "## No Secrets In Code",
            "## Audit Trail Required",
            "## AI Draft Only",
        ):
            self.assertIn(heading, text)

    def test_disclaimer(self) -> None:
        self.assertIn(DISCLAIMER, read("docs/ai_governance.md"))
        self.assertIn(DISCLAIMER, read("README.md"))


class TestStrategyTests(unittest.TestCase):
    def test_required_suites(self) -> None:
        text = read("docs/test_strategy.md")
        for heading in (
            "## Unit Tests",
            "## Bulk Tests",
            "## Callout Tests",
            "## LWC Tests",
            "## Security Tests",
            "## Smoke Tests",
            "## Coverage Reporting",
        ):
            self.assertIn(heading, text)


class ProjectSetupTests(unittest.TestCase):
    def test_sfdx_project_targets_developer_login_and_api_68(self) -> None:
        project = json.loads(read("sfdx-project.json"))
        self.assertEqual(project["sourceApiVersion"], "68.0")
        self.assertEqual(project["sfdcLoginUrl"], "https://login.salesforce.com")
        self.assertEqual(project["namespace"], "")
        directories = project["packageDirectories"]
        self.assertEqual(directories[0]["path"], "force-app")
        self.assertTrue(directories[0]["default"])

    def test_scratch_definition_is_developer_edition_without_sample_data(self) -> None:
        scratch = json.loads(read("config/project-scratch-def.json"))
        self.assertEqual(scratch["edition"], "Developer")
        self.assertFalse(scratch["hasSampleData"])
        features = scratch.get("features", [])
        self.assertNotIn("Agentforce", features)
        self.assertNotIn("Einstein", features)

    def test_package_manifest_lists_lead_to_case_metadata(self) -> None:
        manifest = read("manifest/package.xml")
        self.assertIn("<version>68.0</version>", manifest)
        for member in (
            "LeadTriggerHandler",
            "LeadToCaseService",
            "LeadToCaseServiceTest",
            "TestDataFactory",
            "Lead.Request_Type__c",
            "Case.Source_Lead__c",
            "LeadStatus",
            "ServiceGenie_Lead_To_Case",
        ):
            self.assertIn(member, manifest)
        for excluded in ("NamedCredential", "ExternalCredential"):
            self.assertNotIn(excluded, manifest)
        self.assertIn("caseAssistant", manifest)
        self.assertIn("CaseAssistController", manifest)

    def test_gitignore_blocks_secrets_and_cli_auth(self) -> None:
        text = read(".gitignore")
        for entry in (".env", ".sf/", ".sfdx/", "*.key"):
            self.assertIn(entry, text)

    def test_readme_sections(self) -> None:
        text = read("README.md")
        for heading in (
            "## Purpose",
            "## Architecture",
            "## Apex Layer",
            "## Trigger Architecture",
            "## Bulk-Safe Design",
            "## LWC Architecture",
            "## Controller Layer",
            "## Service Console Design",
            "## Stack",
            "## Roadmap",
            "## Developer Edition Limits",
            "## Project Status",
        ):
            self.assertIn(heading, text)
        self.assertIn(DISCLAIMER, text)

    def test_workflow_runs_the_foundation_suite(self) -> None:
        text = read(".github/workflows/foundation.yml")
        self.assertIn("python -m unittest discover -s tests -v", text)


class ScopeGuardTests(unittest.TestCase):
    """Lead-to-case Apex, the case assistant, and the draft object may exist.

    Named Credential metadata and External Credential metadata stay out of
    source. M5 documents them because no org is authorized.
    """

    def test_lead_trigger_is_the_only_trigger_and_only_delegates(self) -> None:
        triggers = list((ROOT / "force-app").rglob("*.trigger"))
        self.assertEqual(len(triggers), 1)
        self.assertEqual(triggers[0].name, "LeadTrigger.trigger")
        body = triggers[0].read_text(encoding="utf-8")
        self.assertIn("LeadTriggerHandler.run();", body)
        self.assertNotIn("[", body)
        executable = [
            line.strip()
            for line in body.splitlines()
            if line.strip() and not line.strip().startswith("trigger")
        ]
        self.assertEqual(executable, ["LeadTriggerHandler.run();", "}"])

    def test_apex_does_not_use_see_all_data(self) -> None:
        classes = list((ROOT / "force-app").rglob("*.cls"))
        self.assertGreaterEqual(len(classes), 4)
        for path in classes:
            self.assertNotIn("SeeAllData", path.read_text(encoding="utf-8"))

    def test_deferred_metadata_is_absent(self) -> None:
        self.assertTrue(
            (ROOT / "force-app/main/default/objects/AI_Draft__c/AI_Draft__c.object-meta.xml").is_file()
        )
        forbidden_names = (
            "namedCredential-meta.xml",
            "externalCredential-meta.xml",
        )
        for path in (ROOT / "force-app").rglob("*"):
            if not path.is_file():
                continue
            name = path.name
            self.assertFalse(name.endswith(".page"), name)
            self.assertFalse(name.endswith(".component"), name)
            self.assertFalse(any(name.endswith(suffix) for suffix in forbidden_names), name)
        meta = sorted(
            path.relative_to(ROOT).as_posix()
            for path in (ROOT / "force-app").rglob("*.js-meta.xml")
        )
        self.assertEqual(meta, ["force-app/main/default/lwc/caseAssistant/caseAssistant.js-meta.xml"])
        for folder in ("namedCredentials", "externalCredentials"):
            files = [
                path
                for path in (ROOT / "force-app/main/default" / folder).rglob("*")
                if path.is_file()
            ]
            self.assertTrue(files, folder)
            for path in files:
                self.assertEqual(path.name, ".gitkeep", path)

    def test_servicegenie_folder_has_no_fixtures_yet(self) -> None:
        files = [path for path in (ROOT / "servicegenie").rglob("*") if path.is_file()]
        for path in files:
            self.assertEqual(path.name, ".gitkeep", path.relative_to(ROOT))

    def test_trigger_control_record_is_not_deployed(self) -> None:
        design = read("docs/apex_design.md")
        self.assertIn("Automation_Enabled__c", design)
        self.assertIn("No custom metadata record is deployed in M2.", design)
        custom_metadata = list((ROOT / "force-app").rglob("*.md-meta.xml"))
        names = sorted(path.name for path in custom_metadata)
        self.assertEqual(
            names,
            [
                "NBA_Rule.Customer_Waiting.md-meta.xml",
                "NBA_Rule.Escalated_Waiting.md-meta.xml",
                "NBA_Rule.High_Priority_New.md-meta.xml",
                "NBA_Rule.Open_Over_7_Days.md-meta.xml",
                "NBA_Rule.Phone_High.md-meta.xml",
                "NBA_Rule.Recently_Reopened.md-meta.xml",
                "NBA_Rule.Web_New.md-meta.xml",
                "NBA_Rule.Working_Case.md-meta.xml",
            ],
        )


if __name__ == "__main__":
    unittest.main()
