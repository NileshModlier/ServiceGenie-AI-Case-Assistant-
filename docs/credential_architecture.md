# Credential Architecture

The callout name is `LLM_API`. No Developer Edition org is authorized from this workspace, so the Named Credential and the External Credential are design only. `force-app/main/default/namedCredentials/` and `externalCredentials/` stay empty on purpose. Apex calls `callout:LLM_API/v1/chat/completions`. Tests mock that call. They do not log in and they do not read a key.

This project targets Salesforce Developer Edition only. It does not use Enterprise Edition, a sandbox, a production org, real customer data, or Agentforce.

## External credential

Name: `LLM_External`.

| Piece | Design |
| --- | --- |
| Authentication protocol | Custom. Salesforce does not receive a username and password in source. |
| Principal | Named Principal. Principal name `NamedPrincipal`, sequence 1. |
| Permission set access | `ServiceGenie_AI_Draft` grants the draft object today. When an admin creates `LLM_External` in the org, that same permission set gets principal access for `LLM_External-NamedPrincipal`. A user without that access cannot make the callout. |
| Header injection | A custom header named `Authorization`. The value is entered in Setup as `Bearer {!$Credential.LLM_External.ApiKey}`. Apex does not add this header. |
| Secret storage | The `ApiKey` parameter is an authentication parameter on the external credential. Salesforce stores it in the org. It is not a custom metadata record, a custom setting, a custom label, a remote site, or a file in git. |

Do not store secrets in code. Do not paste a provider key into a named credential URL.

## Named credential

Name: `LLM_API`. Label: LLM API. Type: Secured Endpoint.

| Piece | Design |
| --- | --- |
| Endpoint | The admin types the provider base URL in Setup. The documented placeholder is `https://llm.example.com`. The path `/v1/chat/completions` is appended by Apex through the callout name. The URL has no user, password, or key. |
| Authentication | External credential `LLM_External`. Generate Authorization Header is off, because the custom header above is the injection point. |
| Usage pattern | `LlmClient` sends one POST. `HttpCalloutMock` stands in for the network. A unit test sees the request before the platform would inject the header, so the test asserts that Apex itself left `Authorization` empty. |

Remote Site Settings are not used. They would not hold the secret in the managed credential store.

## What is in source

The string `callout:LLM_API` is in `LlmClient`. The permission set `ServiceGenie_AI_Draft` does not list a principal, because the external credential record does not exist yet. Adding that principal in source before the credential exists would fail deployment.

They were not configured until M5. M5 documents them and does not deploy the credential files.
