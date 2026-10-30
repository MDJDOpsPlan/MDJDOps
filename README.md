# Maryland Judiciary — Operational Plan Automation

## Overview

The **Maryland Judiciary Operational Plan Automation** solution helps the Administrative Office of the Courts (AOC) collect, manage, approve, and report on annual operational plans and related projects. It replaces manual collection and tracking with a role-based Power Apps interface, SharePoint lists, Power Automate workflows, and Power BI reporting.

This repository is intended to hold the **portable deployment package** and supporting documentation so authorized teams can install the solution in another environment or tenant.

## Features

- Create and update annual operational plans and associated projects, including mid-year updates.
- Provide separate experiences for **Administrators** and **Chairs/Designees**.
- Manage access using SharePoint permissions and Microsoft Entra ID groups.
- Route submitted plans for administrative review and approval, with email notifications.
- Stage approved project information for Power BI reporting.
- View administrative and intranet reports, with on-demand dataset refresh.
- Create the next year's plan while carrying forward incomplete projects.

## Technology stack

| Component | Technology |
| --- | --- |
| User interface | Microsoft Power Apps Canvas App (`Maryland Operational Plan`) |
| Data storage | SharePoint Online lists |
| Workflow automation | Microsoft Power Automate |
| Reporting | Microsoft Power BI |
| Identity and access | Microsoft Entra ID / Microsoft 365 |
| Deployment | PnP PowerShell/XML blueprint **or** SharePoint Framework (SPFx) `.sppkg` for list provisioning; Power BI `.pbit` templates; unmanaged Power Platform solution `.zip` |

## Deployment package

The master documentation identifies the following files. **Folder paths below are a suggested GitHub organization**; adjust them to match the actual uploaded files.

```text
.
├── README.md
├── sharepoint/
│   ├── deploy_blueprint.ps1
│   ├── Blueprint.xml
│   └── <Operational-Plan-SPFx>.sppkg
├── power-bi/
│   ├── <Admin-Report>.pbit
│   └── <Intranet-Report>.pbit
├── power-platform/
│   └── <Operational-Plan-Solution>.zip
└── docs/
    ├── Operational_Plan_Master_Documentation.docx
    └── Operational Plan SPFx - Installation Guide.docx
```

| File | Purpose |
| --- | --- |
| `deploy_blueprint.ps1` | Connects to the target SharePoint site and applies the list template. |
| `Blueprint.xml` | Defines SharePoint lists, columns, choice fields, and lookup relationships. |
| Operational Plan SPFx `.sppkg` | Alternative SharePoint list-provisioning package; upload to the tenant App Catalog, install per site, then provision via the web part. |
| `Operational Plan SPFx - Installation Guide.docx` | Full SPFx installation, list provisioning, verification, and troubleshooting instructions. |
| Power BI `.pbit` files | Templates for the Admin Report and Operational Plan Intranet Report. |
| Power Platform solution `.zip` | Unmanaged solution containing the Canvas App, cloud flows, and related components. |
| Master documentation | Architecture, full deployment instructions, administrator and user guides, and data dictionary. |

## Prerequisites

Before deploying, ensure that you have:

- Access to the target Microsoft 365 tenant and Power Platform environment, with permission to import solutions and configure flows and connections.
- An existing SharePoint Online site and **Site Owner (Full Control)** permissions.
- **PowerShell 7.x**, **PnP PowerShell**, and an editor such as Visual Studio Code.
- **Power BI Desktop** and permission to publish to the target Power BI workspace.
- An authorized account or service account for SharePoint reporting connectivity and refresh.
- A Microsoft Entra ID security group for application users, with the required group-management permissions.
- Access to Office 365 Users, Office 365 Groups, Office 365 Outlook, SharePoint, and Power BI connectors.
- Target-environment values: SharePoint site URL, Power Platform environment, Power BI workspace/report/dataset identifiers, Entra group object ID, and notification mailbox.

## Start here: deployment guide

**Before installing or configuring the application, read the `Operational_Plan_Master_Documentation.docx` document included with the deployment package.** Navigate to **Section 3 — End-to-End Deployment Guide** and follow its instructions in order to set up the solution in your target environment.

Section 3 covers the required prerequisites and all three deployment phases: **(1) SharePoint Data Infrastructure Setup, (2) Power BI Analytics Setup, and (3) Power Platform Solution Installation**, followed by deployment validation. Use that document as the authoritative step-by-step guide, including screenshots and environment-variable configuration. For **SharePoint list setup**, choose **one** of the two supported approaches below: the PowerShell/XML method described in Section 3.2, or the SPFx method described in `Operational Plan SPFx - Installation Guide.docx`. Both lead into the same Power BI and Power Platform setup steps. The instructions below are a quick reference only.

## Deployment instructions

Follow the sequence below. For screenshots, exact field mappings, and troubleshooting context, consult the **End-to-End Deployment Guide** in the master documentation.

### Step 1 — Provision SharePoint lists (choose one method)

#### Option A — PnP PowerShell and XML blueprint

1. Keep `deploy_blueprint.ps1` and `Blueprint.xml` in the **same directory**.
2. Install the required PowerShell module:

   ```powershell
   Install-Module -Name PnP.PowerShell -Scope CurrentUser -Force
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
   ```

3. Open `deploy_blueprint.ps1` and set `$TargetUrl` to the **full target SharePoint site URL**.
4. Run the script using an authorized SharePoint Site Owner account and complete the device-login authentication when prompted.
5. Verify that all five lists have been created:
   - **Operational Plan Admin**
   - **Organization**
   - **Operational Plans**
   - **Project Plan**
   - **OpPlan Approved Staging List**

> **Caution:** Review the blueprint and existing target site before applying a provisioning script. Test in a nonproduction environment first.

#### Option B — SPFx app and web part (alternative)

Use this method instead of Option A when the **Operational Plan SPFx** `.sppkg` deployment package is available and your team has the required SharePoint administration permissions. **Read `Operational Plan SPFx - Installation Guide.docx` for the complete illustrated instructions.**

1. **App Catalog access (one time):** A SharePoint Administrator must also be a **site admin of the Apps / App Catalog site** to upload packages. In the SharePoint admin center, open **Sites → Active sites → Apps → Membership → Site admins** and add the uploader if needed.
2. **Upload package (one time or for a new version):** In the tenant App Catalog's **Manage apps**, upload the Operational Plan SPFx `.sppkg`, enable it if prompted, and confirm **State: Enabled** and **Valid app package: Yes**.
3. **Install on each target site:** As a site owner, open the SharePoint site and select **Settings → Add an app → Operational Plan SPFx → Add**. Confirm it appears under **Site contents**. *Installing the app does not create lists.*
4. **Provision lists:** Edit the site's Home page, add the **Operational Plan** web part, review its **Pre-flight check**, and click **Provision lists**. The provisioning user must have **Manage Lists** permission. Wait for all five lists to finish.
5. **Verify:** Click **Verify** in the web part; confirm all lists and fields pass, inspect the lists in **Site contents**, then **Publish changes** to retain the web part (or **Discard edits** if it was only needed for setup).

Both methods provision the same five lists: **Operational Plan Admin**, **Organization**, **Operational Plans**, **Project Plan**, and **OpPlan Approved Staging List**. Do **not** run both methods against the same site without first reviewing existing lists and their schema. If the SPFx verifier reports **Exists – differences**, consult the guide's troubleshooting section and resolve the differences before proceeding.

**SPFx-specific prerequisites:** tenant App Catalog access for the uploader, site admin membership on the Apps site, site-owner access for installation, **Manage Lists** permission for provisioning, and the `.sppkg` package. The PowerShell module is only required for Option A.

### Step 2 — Configure and publish Power BI reports

1. Open both `.pbit` templates in Power BI Desktop.
2. In Power Query, update the `SharePoint_Site_URL` parameter to the new site.
3. Refresh the preview and apply changes.
4. Publish the **Admin Report** and **Operational Plan Intranet Report** to the target Power BI workspace.
5. Record the workspace ID, report URL, and semantic model (dataset) IDs for use during solution import.

**Important:** Complete Power BI setup before Power Apps solution import when possible, because the Power BI identifiers are required as environment variables. The reports do **not** need to be fully operational at this point. If you defer Power BI setup, update the corresponding environment variables after publishing.

### Step 3 — Import the Power Platform solution

1. In Power Apps, select the target environment and navigate to **Solutions → Import solution**.
2. Upload the unmanaged solution `.zip`.
3. Authenticate the required connection references: Office 365 Users, Office 365 Groups, Office 365 Outlook, SharePoint, and Power BI.
4. Map the environment variables to **the target tenant's resources**, not the source environment's resources.
5. Finish the import, review flow configuration, and enable the appropriate flows.
6. Open the Canvas App and verify its SharePoint connections and workflows.

### Key environment variables

| Variable | Value to supply |
| --- | --- |
| `EnvSiteOpPlan` | Target SharePoint site |
| `EnvListOpAdmin` | Operational Plan Admin list |
| `EnvListOperationalPlan` | Operational Plans list |
| `EnvListOpPlanApprovedStaging` | OpPlan Approved Staging List |
| `EnvListOrganization` | Organization list |
| `EnvListProjectPlan` | Project Plan list |
| `EnvVarName` | Environment name |
| `EnvURLApp` | Canvas App URL |
| `EnvWorkspaceIdPowerBi` | Power BI workspace ID |
| `EnvReportURL` | Admin report URL |
| `EnvDatasetReport` | Admin report semantic model ID |
| `EnvDatasetIDOperationalPlan` | Intranet report semantic model ID |
| `EnvMicrosoftEntraIDGroup` | Application users' Entra group object ID |
| `EnvGroupEmail` | Administrative notification mailbox |

## Power Automate workflows

| Flow | Function |
| --- | --- |
| `FlowOpPlanAddUserPermission` | Adds new application users to the designated group and grants required permissions. |
| `FlowOpPlanSendOperationalPlanEmail` | Notifies administrators when a plan is submitted. |
| `FlowOpPlanApproval` | Copies approved project records into staging and refreshes Power BI. |
| `FlowOpPlanCreateNextYearPlan` | Creates the next year's plan and carries forward incomplete projects. |
| `FlowOpPlanRefreshReportDataset` | Supports the administrator's **Sync Reports** action. |

The master documentation notes a limit of **five on-demand report refreshes per day** for the documented licensing configuration; verify limits for your target environment.

## Reporting and data flow

```text
Administrators / Chairs / Designees
                |
                v
        Power Apps Canvas App
                |
                v
        SharePoint Online Lists
                |
                v
       Power Automate Workflows
        |                 |
        v                 v
 Approval / Staging    Notifications / Permissions
        |
        v
    Power BI Reports
 (Admin and Intranet)
```

Power BI reports use the approved staging data to show published project information. The Admin Report supports detailed review and export; the Intranet Report presents organizational progress and performance.

## Post-deployment validation

- [ ] All five SharePoint lists, required columns, and lookup relationships exist.
- [ ] Both Power BI reports are published and use the correct SharePoint site.
- [ ] The Power Platform solution imported successfully.
- [ ] Connection references and environment variables point to the target environment.
- [ ] Required Power Automate flows are enabled and run successfully.
- [ ] The Canvas App opens and reads/writes expected data.
- [ ] Administrator and Chair/Designee permissions work as intended.
- [ ] Plan submission, approval, staging, and notifications work.
- [ ] Power BI refresh and report visibility work as expected.
- [ ] Next-year plan creation carries forward incomplete projects correctly.

## Documentation

Refer to **Operational Plan Master Documentation** for:

1. Project Description & Overview
2. Project Architecture & Technical Documentation
3. End-to-End Deployment Guide
4. Administrator & User Manuals
5. SharePoint Lists & Data Types (Data Dictionary)

**Alternative list installation guide:** `Operational Plan SPFx - Installation Guide.docx` — use this for the SPFx-based SharePoint setup option.

**Repository URL:** `[Add GitHub repository URL]`  
**Branch / release:** `[Add approved branch or version]`  
**Support / ownership:** `[Add responsible team or contact]`

