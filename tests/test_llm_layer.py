"""Checks the M5 draft callout stays behind a named credential and a person."""

from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CLASSES = ROOT / "force-app/main/default/classes"
LLM = CLASSES / "LlmClient.cls"
LLM_TEST = CLASSES / "LlmClientTest.cls"
DRAFT = CLASSES / "DraftService.cls"
DRAFT_TEST = CLASSES / "DraftServiceTest.cls"


class LlmLayerTests(unittest.TestCase):
    def test_client_masks_and_uses_the_named_credential(self) -> None:
        source = LLM.read_text(encoding="utf-8")
        self.assertIn("public with sharing class LlmClient", source)
        for method in ("complete(", "parseResponse(", "maskSensitiveData("):
            self.assertIn(method, source)
        self.assertIn("callout:LLM_API/v1/chat/completions", source)
        self.assertNotIn("https://", source)
        self.assertNotIn("Authorization", source)
        self.assertNotIn("Bearer", source)
        self.assertNotIn("Queueable", source)
        self.assertNotIn("enqueueJob", source)

    def test_draft_flow_requires_a_person_and_does_not_send(self) -> None:
        source = DRAFT.read_text(encoding="utf-8")
        for method in ("generateDraft(", "approveDraft(", "rejectDraft("):
            self.assertIn(method, source)
        self.assertIn("CaseAssistController.getCaseContext", source)
        self.assertIn("LlmClient.complete", source)
        self.assertIn("insert as user", source)
        self.assertIn("UserInfo.getUserType() != 'Standard'", source)
        self.assertNotIn("Messaging", source)
        self.assertNotIn("EmailMessage", source)
        self.assertNotIn("Queueable", source)
        self.assertNotIn("enqueueJob", source)

    def test_mock_inventory_covers_status_masking_and_decisions(self) -> None:
        client = LLM_TEST.read_text(encoding="utf-8")
        draft = DRAFT_TEST.read_text(encoding="utf-8")
        combined = client + draft
        for token in (
            "HttpCalloutMock",
            "429",
            "500",
            "timed out",
            "[email]",
            "[phone]",
            "[card]",
            "approveDraft",
            "rejectDraft",
            "Limits.getEmailInvocations()",
        ):
            self.assertIn(token, combined, token)
        self.assertIn("callout:LLM_API/v1/chat/completions", client)

    def test_credentials_are_documented_and_not_deployed(self) -> None:
        design = (ROOT / "docs/credential_architecture.md").read_text(encoding="utf-8")
        for phrase in (
            "Custom",
            "Named Principal",
            "Permission set",
            "Authorization",
            "LLM_API",
            "https://llm.example.com",
            "Do not store secrets in code",
        ):
            self.assertIn(phrase, design)
        for folder in ("namedCredentials", "externalCredentials"):
            files = [
                path
                for path in (ROOT / "force-app/main/default" / folder).rglob("*")
                if path.is_file()
            ]
            self.assertEqual([path.name for path in files], [".gitkeep"], folder)
        manifest = (ROOT / "manifest/package.xml").read_text(encoding="utf-8")
        self.assertNotIn("NamedCredential", manifest)
        self.assertNotIn("ExternalCredential", manifest)
        self.assertIn("AI_Draft__c", manifest)
        self.assertIn("LlmClient", manifest)
        self.assertIn("DraftService", manifest)

    def test_audit_and_prompt_docs(self) -> None:
        audit = (ROOT / "docs/audit_model.md").read_text(encoding="utf-8")
        prompt = (ROOT / "docs/prompt_strategy.md").read_text(encoding="utf-8")
        design = (ROOT / "docs/llm_design.md").read_text(encoding="utf-8")
        for label in (
            "Original Draft",
            "Edited Draft",
            "Approver",
            "Approval Time",
            "Prompt Version",
            "Model Name",
            "Draft",
            "Approved",
            "Rejected",
        ):
            self.assertIn(label, audit)
        self.assertIn("does not send", design.lower())
        self.assertIn("v1", prompt)
        self.assertIn("[email]", prompt)
