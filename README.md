# Hydra Tools

Administrative tools that support Hydra outside its guest scripting context. Run the PowerShell tools from an administrator's Azure management session; run the SQL query against the Hydra database.

## Script catalog

| Tool | Purpose | Requirements |
| --- | --- | --- |
| [Add-HydraTenantServicePrincipal.ps1](Add-HydraTenantServicePrincipal.ps1) | Creates or reuses a service principal, generates a client secret, deploys Hydra custom roles, and assigns Azure permissions at subscription or resource-group scope. Can also configure Graph application permissions and consent. | Az.Accounts, Az.Resources, Microsoft.Graph.Authentication, and Microsoft.Graph.Applications; an identity allowed to create the relevant application, role definitions, assignments, and optional Graph consent. |
| [Invoke-HydraAgentAvdDeployment.ps1](Invoke-HydraAgentAvdDeployment.ps1) | Deploys the Hydra agent to AVD session-host VMs through Azure VM Run Command. | Authenticated Azure PowerShell with Az.Accounts, Az.Resources, Az.DesktopVirtualization, and Az.Compute; host-pool/VM discovery and Run Command rights, plus VM-start rights if using `-PowerOn`. |
| [Get-PersonalPowerOnSchedules.sql](Get-PersonalPowerOnSchedules.sql) | Lists enabled personal power-on schedules from the Hydra database. | SQL client and read access to `dbo.SessionHosts`; SQL JSON and STRING_AGG support, and the matching Hydra schema. |

## Create a tenant service principal

Run the script by path with the desired scope:

```powershell
.\Add-HydraTenantServicePrincipal.ps1 -TenantId '<tenant-id>' -ScopeType ResourceGroup -SubscriptionId '<subscription-id>' -ResourceGroupName '<resource-group>' -ServicePrincipalDisplayName 'svc-Hydra' -ApplyConstrainedRoleAssignmentCondition -ConfigureGraphApplicationPermissions
```

For subscription scope, use `-ScopeType Subscription` and omit `-ResourceGroupName`. The script retrieves Hydra's custom-role template from its configured GitHub URL. `-ApplyConstrainedRoleAssignmentCondition` restricts assignable roles; `-ConfigureGraphApplicationPermissions` enables application permissions and admin consent. Without the latter switch, Graph configuration is skipped.

The script prints the tenant ID, application ID, newly generated secret, and expiry for entry into Hydra. Handle the secret as a credential. If a constrained role assignment fails, the current script retries without the condition; review its output and resulting assignments.

## Deploy the Hydra agent

Authenticate with `Connect-AzAccount`, then preview a specific host pool:

```powershell
.\Invoke-HydraAgentAvdDeployment.ps1 -SubscriptionId '<subscription-id>' -HostPoolName '<host-pool-name>' -Uri '<hydra-app-uri>' -Secret '<hydra-registration-secret>' -WhatIf
```

Remove `-WhatIf` to deploy after reviewing the target scope. Provide the app URI and registration secret from your Hydra agent installer configuration.

| Parameter | Behavior / default |
| --- | --- |
| `-SubscriptionId` | Target Azure subscription. |
| `-Uri`, `-Secret` | Hydra app URI and agent registration secret. |
| `-HostPoolName` | One or more host pool names; omission targets all discovered pools. |
| `-ResourceGroupName` | One or more resource groups to search; omission searches all groups. |
| `-InstallerPath` | Defaults to `ITPC-DeployHydraAgent.ps1` alongside this script. |
| `-InstallerUri` | Hydra GitHub raw installer URL used when the local installer is missing. |
| `-PowerOn` | Starts powered-off target VMs before installation. |
| `-PowerOnTimeoutSeconds` | Readiness timeout, default 300 seconds. |
| `-RepairPerfmon` | Runs `lodctr /R` through Run Command before installation. |
| `-AsJob` | Submits installation Run Commands as background jobs. |
| `-StopOnError` | Stops on the first failure instead of continuing the batch. |
| `-WhatIf` | Previews actions without starting VMs or submitting Run Commands. |

The installer helper is downloaded when needed; it is not bundled in this folder. Its default location follows this script after relocation. Job submission with `-AsJob` does not by itself confirm successful installation.

## Query personal power-on schedules

Open `Get-PersonalPowerOnSchedules.sql` in a SQL client connected to the Hydra database and execute the SELECT. It reads schedule JSON from `SessionHosts.Advanced` and returns `AssignedUser`, `machineName`, `startTime` (HH:mm from `LocalTimeFrom`), and comma-separated weekdays. Only enabled schedules are returned. This query does not modify data or convert schedule times to the SQL client's timezone.
