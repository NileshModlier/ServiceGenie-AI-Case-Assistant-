# Org Setup

This project targets Salesforce Developer Edition only. It does not use Enterprise Edition, a sandbox, a production org, real customer data, or Agentforce.

M1 does not require an authorized org. The files in this repository are the foundation. Authorize a Developer Edition org when you are ready to deploy a later milestone. Nothing in M1 deploys metadata.

## What You Need

- A free Salesforce Developer Edition org you signed up for yourself
- Salesforce CLI (`sf`) installed locally
- Python 3, used only to run `tests/test_foundation.py`
- Git

You do not need a Partner Developer Edition, a Dev Hub, a sandbox, or a production login.

## Create the Org

1. Sign up at [https://developer.salesforce.com/signup](https://developer.salesforce.com/signup).
2. When the org is ready, confirm the edition before you build anything:
   - Setup → Company Information → Organization Edition
   - The value must be Developer Edition
   - If the edition is anything else, stop. Do not use that org for this project
3. Confirm storage under Setup → Storage Usage. The published Developer Edition allocation is 5 MB of data and 20 MB of files, with no per-user increase. Treat those as the budget until your own Storage Usage page shows different numbers.
4. Leave Agentforce unused. Do not create agents, topics, or actions. Do not turn on a feature for this project just because a new Developer Edition offers it.

Developer Edition orgs in Salesforce's published comparison include 2 Salesforce user licenses and 3 Salesforce Platform user licenses, and they list the separate Service Cloud user-license count as 0. Use the Salesforce licenses. After login, open App Manager and confirm which Service apps your org actually shows. Do not assume extra Service Cloud feature licenses.

That comparison is Salesforce Help, "Benefits of Using a Partner Development Org and Demo Environment." It also lists 15,000 API requests per 24 hours and no sandboxes. Confirm the API allocation on your org before M5 designs callout volume. This project does not use the larger Partner Developer Edition column in that article.

Salesforce deactivates inactive Developer Edition orgs. The same Help comparison lists expiration after inactivity. Log in often enough to keep the org, and treat Salesforce's notice as the source of truth if it differs.

## Authorize the Org

Developer Edition uses the login host `https://login.salesforce.com`. Sandbox login (`https://test.salesforce.com`) is out of scope.

From the repository root:

```bash
sf org login web --alias servicegenie-de --instance-url https://login.salesforce.com
sf org display --target-org servicegenie-de
```

After login, check Organization Edition again. Sharing the login host with other org types is not permission to use those orgs. This project does not claim production access.

Do not commit the `.sf/` folder, auth files, or any alias that contains a token. `.gitignore` excludes them.

Set the default org only on your machine:

```bash
sf config set target-org servicegenie-de
```

## What the Manifest Deploys

`manifest/package.xml` deploys the M2 lead-to-case metadata: the trigger, the handler, the service, the test factory, the Apex tests, `Lead.Request_Type__c`, `Case.Source_Lead__c`, the Lead Status value `Routed to Support`, and the `ServiceGenie_Lead_To_Case` permission set.

```bash
sf project deploy start --manifest manifest/package.xml --target-org servicegenie-de
```

Run that against a Developer Edition org after you confirm Organization Edition. The Lead Status file includes the usual open, working, converted, and not-converted values plus `Routed to Support`. If your org has extra lead statuses, add them to that file before deploying so the deploy does not try to remove them.

Then run the Apex tests:

```bash
sf apex run test --tests LeadToCaseServiceTest --code-coverage --result-format human --wait 30
```

Do not retrieve the org into `force-app`. A retrieve would copy org configuration this project did not design.

## Scratch Org Shape

`config/project-scratch-def.json` describes a Developer edition shape with `hasSampleData` set to false and the ServiceCloud feature requested. It is documentation for a possible later scratch org.

Creating a scratch org requires a Dev Hub:

```bash
sf org create scratch --definition-file config/project-scratch-def.json --alias servicegenie-scratch --target-dev-hub YOUR_DEV_HUB
```

This project does not assume a Dev Hub is enabled, and M1 does not ask you to run that command. If you do run it later and the CLI rejects the ServiceCloud feature as unavailable on Developer edition, remove that feature from the definition. Do not change `edition` away from `Developer` to make the command succeed.

The working path remains a Developer Edition org created through the signup link above.

## Synthetic Data

Do not import customer data, Salesforce sample data, or a production extract.

When a later milestone needs rows, create a few by hand or with a script of obvious demo values:

- Company: `Example Household`
- Email: `casey.demo@example.com`
- Lead `Request_Type__c`: `Support` or `Sales` once that field exists

Keep the set small. Five megabytes of data storage is the published Developer Edition budget. The Apex tests create their own rows and roll them back. Do not load a customer extract.

## Named Credentials

Named Credentials and External Credentials are documented in `docs/architecture.md`. Do not create them during org setup. M5 is the milestone that configures them.

Do not create a Remote Site Setting, a Named Credential, or an External Credential "early so the org is ready." There is no provider, no key, and no callout class in M1.

## Service App

Cases are part of the demo design. If your Developer Edition org shows the Service Console or the Service app in App Manager, you may open it and confirm the standard Case object is there. Do not enable Email-to-Case, auto-response rules, or escalation rules for this project. Those features send or reshuffle customer messages, which this design does not do.

M2 source includes the Lead Status `Routed to Support`, `Lead.Request_Type__c`, and `Case.Source_Lead__c`. Deploy them with the manifest. Do not recreate them by hand in Setup.

## Local Validation

No org is required:

```bash
python -m unittest discover -s tests -v
```

The GitHub workflow `.github/workflows/foundation.yml` runs the same command.
