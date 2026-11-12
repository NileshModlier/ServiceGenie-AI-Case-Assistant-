# Evaluation

The scored run is local. It does not call a model, does not log in to Salesforce, and does not approve or send anything. `evaluations/evaluate.py` applies the same masking expressions and the same block phrases as `SafetyFilter` and `LlmClient`. `tests/test_evaluation.py` runs 20 summary cases, 10 prompt-injection cases, and 10 unsafe-content cases.

## Measures

| Measure | Meaning in this run |
| --- | --- |
| Correct summaries | The case was stored or blocked as the fixture expects, and a stored summary keeps the expected words and drops raw emails, phones, and card-like numbers. |
| Approval rate | Autonomous approvals. The product has no path that approves a draft or a summary by itself, so this rate is 0. |
| Blocked unsafe responses | Unsafe fixtures that `SafetyFilter` rejects. |
| Blocked injections | Injection fixtures that `SafetyFilter` rejects. |
| Latency | Time to run the local checks. It is not model latency and not org latency. |
| Masking compliance | Fixtures whose prompt contains an email or a card-like number, checked after masking. |

The latest numbers are in `evaluations/latest_results.json`. Re-run with:

```bash
python -m unittest tests.test_evaluation -v
```

A password-reset subject is allowed. The block phrase is "the password is", so a normal reset request can still be summarized. A subject or reply that asks to send email, reveal a key, or ignore the instructions is not stored.
