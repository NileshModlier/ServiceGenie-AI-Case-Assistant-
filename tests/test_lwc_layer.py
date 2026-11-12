"""Checks that the M4 console component stays inside its security and UI contract."""

from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTROLLER = ROOT / "force-app/main/default/classes/CaseAssistController.cls"
COMPONENT_JS = ROOT / "force-app/main/default/lwc/caseAssistant/caseAssistant.js"
COMPONENT_HTML = ROOT / "force-app/main/default/lwc/caseAssistant/caseAssistant.html"
JEST = ROOT / "force-app/main/default/lwc/caseAssistant/__tests__/caseAssistant.test.js"


class ConsoleLayerTests(unittest.TestCase):
    def test_controller_exists_and_uses_user_mode(self) -> None:
        source = CONTROLLER.read_text(encoding="utf-8")
        self.assertIn("public with sharing class CaseAssistController", source)
        self.assertIn("getCaseContext", source)
        self.assertIn("refreshCaseContext", source)
        self.assertGreaterEqual(source.count("WITH USER_MODE"), 4)
        self.assertNotIn("Description", source)
        self.assertNotIn("callout:", source)
        self.assertNotIn("HttpRequest", source)
        self.assertNotIn("Messaging.", source)
        for method in ("generateDraft", "approveDraft", "rejectDraft", "getLatestDraft"):
            self.assertIn(method, source)

    def test_component_uses_wire_for_reads_and_imperative_refresh(self) -> None:
        source = COMPONENT_JS.read_text(encoding="utf-8")
        self.assertIn("@wire(getCaseContext", source)
        self.assertIn("refreshCaseContext({ caseId: this.recordId })", source)
        html = COMPONENT_HTML.read_text(encoding="utf-8")
        for state in ("loading", "empty", "error", "success"):
            self.assertIn(f'data-state="{state}"', html)
        for action in ("refresh", "draft", "summary"):
            self.assertIn(f'data-action="{action}"', html)
        self.assertNotIn('data-action="next"', html)
        self.assertNotIn('data-action="send"', html)
        for field in ("rule-name", "reason", "action"):
            self.assertIn(f'data-field="{field}"', html)

    def test_jest_inventory_covers_render_states_and_buttons(self) -> None:
        source = JEST.read_text(encoding="utf-8")
        for name in (
            "renders the case context",
            "shows the loading state",
            "shows the error state",
            "shows the empty state",
            "enables refresh and generate and keeps next actions disabled",
            "shows a generated draft and keeps approve from sending",
            "shows a rule recommendation and queues a summary",
        ):
            self.assertIn(name, source)

    def test_security_and_ui_notes_exist(self) -> None:
        architecture = (ROOT / "docs/lwc_architecture.md").read_text(encoding="utf-8")
        states = (ROOT / "docs/ui_states.md").read_text(encoding="utf-8")
        console = (ROOT / "docs/service_console.md").read_text(encoding="utf-8")
        self.assertIn("with sharing", architecture)
        self.assertIn("WITH USER_MODE", architecture)
        self.assertIn("field security", architecture.lower())
        for label in ("Loading", "Empty", "Error", "Success", "Button state"):
            self.assertIn(label, states)
        self.assertIn("Generate draft", console)
        self.assertIn("does not change the case", console)
