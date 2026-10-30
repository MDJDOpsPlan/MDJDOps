# Deploying the Operational Plan SPFx

This guide is for the IT team installing the Operational Plan solution. It creates the five SharePoint lists the Power App, flows and Power BI reports use, without PowerShell.

**At a glance:** upload one `.sppkg` file to your App Catalog → add the app to the target site → put the web part on a page → click **Check site**, **Provision lists**, **Verify** → copy the values into the Power Platform solution import.

## Who you need

| Step | Role required |
|---|---|
| Upload the package to the **tenant** App Catalog | SharePoint Administrator (or Global Administrator), or an owner of the tenant App Catalog site |
| Upload to a **site collection** App Catalog instead | Site Collection Administrator of that site (the site collection App Catalog must already be enabled by a SharePoint Administrator) |
| Add the app to the site, add the web part, run it | **Site Owner** of the target site (the web part checks for the *Manage Lists* permission and turns Provision off without it) |

## Security summary

- **No API permissions.** The package declares no `webApiPermissionRequests`, so there is nothing to approve in *API access*.
- **No Microsoft Graph, no Azure Functions, no app-only access.** Every request goes from the signed-in user's browser to the **current site's** SharePoint REST API (`<site>/_api/...`), using the user's own session. The tool can only do what that user is already allowed to do.
- **Current site only.** It reads and changes lists only in the site where the web part is placed.
- **No external services.** The web part's code calls only the current site. As with any SPFx web part built on Microsoft's Fluent UI, the UI library references Microsoft's Office font CDN (`res-1.cdn.office.net`) for the Segoe UI font. SharePoint pages already load fonts from this CDN.
- **Assets ship inside the package** (`includeClientSideAssets: true`). They are served from your App Catalog (or your tenant's Microsoft 365 CDN if you enabled it). Nothing is loaded from an ARK Infotech server.
- **Never deletes.** It does not delete lists, columns, views or items, ever.
- **No source-tenant data.** The package contains only the list schema. The original site's webhooks, flow trigger URLs and site addresses are stripped at build time, and the build fails if any remain.
- **No custom script.** `requiresCustomScript` is `false`, so it works on sites where custom script is disabled.

## 1. Build and package (skip if you received the `.sppkg`)

Requires Node.js 22 (SPFx 1.23.2 does not support Node 24). With nvm:

```bash
nvm install 22
```

```bash
nvm use 22
```

In the project folder:

```bash
npm ci
```

```bash
npm run build
```

The package is created at `sharepoint/solution/OperationalPlanSPFx.sppkg`. The build fails, and produces no package, if any test fails or if the blueprint is invalid.

## 2. Upload the package to an App Catalog

**Tenant App Catalog** (most common):
1. Open the SharePoint admin center → **More features** → **Apps** → **Open**, or go straight to the App Catalog site → **Apps for SharePoint**.
2. Click **Upload** and choose `OperationalPlanSPFx.sppkg`.
3. In the dialog, click **Deploy** (on newer admin centers: **Enable app**, then **Only enable this app**).
   - The package is installed per site (`skipFeatureDeployment: false`), so the "make available to all sites" option is not offered. This is intentional; see *Tenant-wide deployment* below.
4. Confirm the app shows **Deployed = Yes** and **App package error message = No errors**.

**Site collection App Catalog** (when IT wants it limited to one site collection): open the site collection's **Apps for SharePoint** library and follow the same steps.

## 3. Add the app to the target site

1. Go to the site that will hold the Operational Plan lists.
2. **Settings (⚙) → Add an app** (or **Site contents → New → App**).
3. Choose **Operational Plan SPFx** (listed under *From your organization*) and wait until it finishes installing in Site contents.

## 4. Add the web part to a page

1. **New → Page** (for example "Operational Plan setup"). A page visible only to owners is fine.
2. Click **+**, search for **Operational Plan SPFx** (group *Advanced*) and add it.
3. **Publish** the page (or **Save as draft**; the web part also works in edit mode).

## 5. Run Check → Provision → Verify

Stay on the page and **keep the browser tab open** while it runs. The work happens in the browser.

1. **Check site** runs automatically when the page opens; click it again at any time. It changes nothing. Look at the pre-flight panel:
   - *You have Manage Lists permission*: you can continue. If it says you don't, ask a Site Owner to run it.
   - Each list shows **Missing** (will be created), **Exists – matches**, **Exists – differences** or **Name conflict** (see Troubleshooting).
2. **Provision lists** creates the lists in dependency order:
   1. Operational Plan Admin and Organization
   2. Operational Plans
   3. Project Plan
   4. OpPlan Approved Staging List

   For each list it then sets the list settings, updates the Title column, creates the columns and sets up the default view.
   - If any list already exists with differences, you are asked to confirm first.
   - A run makes roughly 300–400 requests and usually takes 2–5 minutes. If SharePoint throttles, the log shows *Throttled – waiting* and the run continues by itself.
   - Do not close or refresh the tab. If you do, just click **Provision lists** again; finished steps are skipped.
3. **Verify** compares every list with the blueprint, field by field:
   - internal name, type, display name, required and default
   - choices, lookup target list, ShowField, projected lookups
   - indexed, unique values, cascade delete, column formatting
   - list settings and the default view

   You want **Exists – matches** on all five lists and the message *All 5 lists exist and match the blueprint*.

## 6. Copy the values into the Power Platform solution import

When all lists match, the web part shows **Values for the Power Platform solution import**. Click **Copy values**. When importing the Operational Plan solution, the import asks for these environment variables:

| Environment variable | Value to choose / enter |
|---|---|
| `EnvSiteOpPlan` | the site URL shown |
| `EnvListOrganization` | Organization |
| `EnvListOpAdmin` | Operational Plan Admin |
| `EnvListOperationalPlan` | Operational Plans |
| `EnvListProjectPlan` | Project Plan |
| `EnvListOpPlanApprovedStaging` | OpPlan Approved Staging List |

The import wizard normally lets you pick the site and then each list by name. If you use a deployment-settings file instead, list variables take the **list ID** (GUID) shown in the block, and the site variable takes the site URL. Remember that schema names in a settings file carry your solution publisher's prefix.

## 7. After provisioning

- Add the first administrator: in **Operational Plan Admin**, create an item with **AppUser** = the administrator and **Role** = *Admin*. The app reads its administrators from this list, and the tool creates no items.
- Optional: remove the setup page, or the app from the site (see *Removal*). The lists stay.
- Note: deleting an item in **Operational Plans** deletes its related **Project Plan** items (cascade delete, as in the original solution).

## Tenant-wide deployment (optional)

To make the web part available on every site without "Add an app":
1. In `config/package-solution.json`, set `"skipFeatureDeployment": true`.
2. Increase `"version"` (for example `1.0.1.0`), run `npm run build`, and upload the new `.sppkg`.
3. In the deploy dialog, choose **Enable this app and add it to all sites** (or tick *Make this solution available to all sites in the organization*).

This does not give the tool more rights: it still acts only as the signed-in user, on the site where it is used. Per-site installation (the default) keeps it off sites that don't need it.

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| *You don't have Manage Lists permission*; Provision is greyed out | You are not a Site Owner of this site. Ask a Site Owner to run it, or to add you to the Owners group, then reload the page. |
| Web part not in the toolbox | The app isn't added to this site (step 3), or the upload wasn't deployed (step 2). |
| Log shows *Throttled – waiting …* | SharePoint is limiting requests. The tool waits as instructed (`Retry-After`) and retries up to 8 times per request. A change request gives up after about 10 minutes of waiting, so its security token can't expire. Leave it running. If it eventually stops, wait a few minutes and click **Provision lists** again. |
| *Provisioning stopped* (tab closed, network drop, *No response from SharePoint after 180 s*, error) | Fix the cause shown, then click **Provision lists** again. It finds what is already there and continues; nothing is created twice. Read requests are retried automatically after a network error. Change requests are not, because SharePoint may already have applied them; the next run detects that. |
| Log lines marked **Error**, but the run continued | A setting, column or view was changed but still doesn't match the blueprint when read back (for example, a tenant policy overrides the version limit). The run continues so you see everything at once. The **Verification** section lists each item. Click **Provision lists** again for items marked *Provision fixes this*; fix the rest by hand. |
| A list shows **Name conflict** | A list with that title already exists at a different URL (for example `Lists/OrganizationOld` titled "Organization"). List titles must be unique, so the tool won't continue. Rename that list (List settings → name) and run **Check site** again. |
| A list shows **Exists – differences** | The list is already there but differs from the blueprint. **Verify** lists each difference and says whether *Provision fixes this* or a *Manual fix required*. Provision adds missing columns and fixes settings, display names, indexes, unique values, cascade delete, formatting and the default view. It never changes an existing column's type, lookup target, choices, default or required flag, because that could lose data. Fix those by hand in List settings (or delete the column if it holds no data), then run Provision again. |
| *…was created at …/Lists/Organization1, but the blueprint requires …/Lists/Organization* | A deleted list with that URL is still in the site's recycle bin (or second-stage recycle bin). Restore it or empty it from the recycle bin, delete the unexpected list, then run Provision again. |
| *SharePoint created "…" with internal name "Status0" instead of "Status"* | A column with that internal name already existed (possibly hidden). The tool stops so the app is never wired to the wrong column. Delete the stray column manually, then run Provision again. |
| *field ID … is already used by "…"* | An earlier attempt created the column under a different internal name. Delete that column manually and run Provision again. |
| *Unique values / index could not be set* on an existing list | The list already contains duplicate values, or has more than 5,000 items. Clean up the data, then run Provision again. |
| *The web part's script was not read as UTF-8* | The app files are being served with the wrong character set, so special characters in choices would be created wrong. Provision is turned off as a safeguard. Contact your SharePoint administrator. |

## Removal

- **Remove the app from a site:** Site contents → *Operational Plan SPFx* → **…** → **Remove**.
- **Remove it from the tenant:** delete the `.sppkg` from the App Catalog.

Neither action deletes the lists or their data. The lists are ordinary SharePoint lists and stay until someone deletes them in Site contents.

## Appendix: acceptance test on a fresh test site

Before handing a new build to production, on a new, empty test site (communication or team site):

1. Upload the `.sppkg`, add the app, add the web part. **Check site** shows all five lists *Missing* and *You have Manage Lists permission*.
2. As a **Member** (not Owner), open the page: Provision must be greyed out with the permission message.
3. As an Owner, click **Provision lists**. Every log line should be *Done* or *No change*, ending with *All 5 lists exist and match the blueprint*.
4. Click **Verify**: all five lists are *Exists – matches*.
5. In Site contents, check the five URLs: `/Lists/Operational Plan Admin`, `/Lists/Organization`, `/Lists/Operational Plans`, `/Lists/Project Plan` and `/Lists/OpPlan Approved Staging List`.
6. Spot-check in List settings:
   - **Operational Plans** has a column displayed as " Last Updated Date" with internal name `LastUpdatedDate`.
   - The two Organization projected columns are present.
   - Status shows coloured pills.
   - **Project Plan** → Operational Plan column → *Enforce relationship behavior: Cascade delete*. The column is indexed (List settings → Indexed columns).
   - Strategic Priorities has 39 choices.
   - **OpPlan Approved Staging List** → Title is *not* required, and the column *Project Plan Modified* is there.
7. Click **Provision lists** again: everything should say *No change*, and nothing is duplicated.
8. Resume test: rename the column *Designees* in Operational Plans and change a list's version limit. Run **Verify** (it shows the differences, marked *Provision fixes this*), then **Provision lists** (it fixes them), then **Verify** again (all match).
9. Interrupt test: on another fresh site, start Provision and close the tab after the first two lists. Reopen the page and click **Provision lists**. It must finish without errors or duplicates.
10. Copy the values block and import the Power Platform solution into a test environment against this site. Open the app and run each flow once.
