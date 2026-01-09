function New-MWEGroup {
  <#
.SYNOPSIS
Creates a Microsoft Entra ID security group according to enforced MWE decisions.

.DESCRIPTION
Creates a Microsoft Entra ID **security group** following the Modern Workplace Enterprise (MWE)
decision model and taxonomy.

The function represents a single public operational domain: **group creation**.
All naming, validation, and enforcement rules are derived from explicit decision logs.

Supported group intents are:
- LICENSE     – Group-based Microsoft 365 license assignment
- ENTRAROLE  – Group-based Entra ID directory role assignment (Active or Eligible via PIM)

The function enforces:
- deterministic, decision-driven group naming
- strict input validation and fail-fast behavior
- mandatory explicit descriptions
- idempotent behavior via decision-aligned guards
- separation of public orchestration and private implementation

Authentication and permissions are treated as explicit preconditions and are not handled here.

.PARAMETER Intent
Specifies the group intent category.

Supported values:
- LICENSE
- ENTRAROLE

This parameter determines which decision domain and validation rules are applied.

.PARAMETER Principal
Specifies the identity scope of the group.

Supported values:
- U – User principals
- D – Device principals
- X – Mixed principals (exceptional use only)

.PARAMETER SkuPartNumber
Specifies the license SKU part number.

Required when Intent is LICENSE.
Ignored for other intents.

.PARAMETER RoleName
Specifies the Entra ID directory role name.

Required when Intent is ENTRAROLE.
The role must exist in the tenant role definitions.

.PARAMETER AssignmentType
Specifies the role assignment type for ENTRAROLE groups.

Supported values:
- Eligible – PIM-protected role eligibility
- Active   – Permanently active role assignment

This parameter is mandatory when Intent is ENTRAROLE.

.PARAMETER MaximumActivationHours
Specifies the maximum activation duration (in hours) for Eligible PIM role assignments.

Applicable only when:
- Intent is ENTRAROLE
- AssignmentType is Eligible

.EXAMPLE
New-MWEGroup -Intent LICENSE -Principal U -SkuPartNumber SPE_E5

Creates a user-scoped security group named according to the enforced
license taxonomy (for example: U-LICENSE-SPE_E5) and assigns the
Microsoft 365 E5 license via group-based licensing.

.EXAMPLE
New-MWEGroup -Intent ENTRAROLE -Principal U -RoleName GlobalAdministrator -AssignmentType Eligible -MaximumActivationHours 9

Creates a user-scoped Entra ID role group for the Global Administrator role
with PIM-protected eligibility and a maximum activation duration of 9 hours.

.NOTES
- This function does not authenticate or request permissions.
- Required Microsoft Graph permissions are treated as preconditions.
- All errors are terminating and fail fast by design.
- Group creation is performed exclusively by automation to prevent drift.

.LINK
DEC-0004 – Group taxonomy and naming rules  
DEC-0005 – License distribution model  
DEC-0006 – Group-based PIM for Entra ID roles  
DEC-0007 – Module refactoring principles
#>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'LICENSE')]
    param (
        #if we want to assign a license, this parameter tells the license name.
        [Parameter(Mandatory, ParameterSetName='LICENSE')]
        [string]$SkuPartNumber,

        #If we want to assign a liceense, this parameter tells is used to just create the group, but not assign the license. aka: we want to mock the license assignment because the lab only has one.
        [Parameter(ParameterSetName = 'LICENSE')]
        [switch]$Mock,

        #If we want to assign an Entra role, this parameter tells the role name.
        [Parameter(Mandatory, ParameterSetName = 'ENTRAROLE')]
        [string]$RoleName,

        #If we want to assign an Entra role, this parameter tells if we want to force the activation of the role before assignement, or we want to throw if thee role template is not activated.
        [Parameter(ParameterSetName = 'ENTRAROLE')]
        [switch]$Force,

        #If we want to assign an Entra role, this parameter tells the assignment type.
        [Parameter(Mandatory, ParameterSetName = 'ENTRAROLE')]
        [ValidateSet('Active','Eligible')]
        [string]$AssignmentType,

        #If we want to assign an Entra role, this parameter tells the maximum activation hours for eligible assignments.
        [Parameter(ParameterSetName = 'ENTRAROLE')]
        [Int32]$MaximumActivationHours
    )
  $ErrorActionPreference = 'Stop'
  $intent=$PSCmdlet.ParameterSetName
  # Set default for MaximumActivationHours if not provided and AssignmentType is 'Eligible' according to DEC-0006
  if ($intent -eq 'ENTRAROLE' -and
	$AssignmentType -eq 'Eligible' -and
	-not $PSBoundParameters.ContainsKey('MaximumActivationHours')
) {
	$MaximumActivationHours = 9
	$PSBoundParameters['MaximumActivationHours'] = 9
}

  # Build parameter splat for Assert-MWEGroupParameters
  $parameterValidationSplat = @{Intent = $intent}
  if ($PSBoundParameters.ContainsKey('SkuPartNumber')) { $parameterValidationSplat.SkuPartNumber = $SkuPartNumber }
  if ($PSBoundParameters.ContainsKey('Mock')) { $parameterValidationSplat.Mock = $Mock }
  if ($PSBoundParameters.ContainsKey('RoleName')) { $parameterValidationSplat.RoleName = $RoleName }
  if ($PSBoundParameters.ContainsKey('Force')) { $parameterValidationSplat.Force = $Force }
  if ($PSBoundParameters.ContainsKey('AssignmentType')) { $parameterValidationSplat.AssignmentType = $AssignmentType }
  if ($PSBoundParameters.ContainsKey('MaximumActivationHours')) { $parameterValidationSplat.MaximumActivationHours = $MaximumActivationHours }

  # Populate additional parameters required for validation, creating variables for later use.
  switch ($intent) {
        'LICENSE' {
          $subscribedSkuGetSplat = @{}
          $AvailableSkus = Invoke-MWECommand -Command 'Get-MgSubscribedSku' -Splat $subscribedSkuGetSplat
         
          $parameterValidationSplat.AvailableSkuPartNumbers = $AvailableSkus.SkuPartNumber
        }
        'ENTRAROLE' {
            $roleDefinitionsGetSplat = @{ All = $true }
            $directoryRolesGetSplat = @{ All = $true }
            $roleDefinitions = Invoke-MWECommand -Command 'Get-MgRoleManagementDirectoryRoleDefinition' -Splat $roleDefinitionsGetSplat
            $directoryRoles = Invoke-MWECommand -Command 'Get-MgDirectoryRole' -Splat $directoryRolesGetSplat

            $parameterValidationSplat.RoleDefinitionDisplayNames = $roleDefinitions.DisplayName
            $parameterValidationSplat.DirectoryRoleDisplayNames = $directoryRoles.DisplayName
        }
    }
    # Run parameter validation
  Invoke-MWECommand -Command 'Assert-MWEGroupParameters' -Splat $parameterValidationSplat

  # Build parameter splat for Assert-MWEExistingGroup
  $groupExistenceValidationSplat= @{Intent = $intent}
    switch ($intent) {
        'LICENSE' {$groupExistenceValidationSplat.SkuPartNumber = $SkuPartNumber}
        'ENTRAROLE' {$groupExistenceValidationSplat.RoleName = $RoleName}
    }
  # Run existing group validation
  Invoke-MWECommand -Command 'Assert-MWEExistingGroup' -Splat $groupExistenceValidationSplat

    $newGroupSplat=@{Intent=$intent}

    switch ($intent) {
        'LICENSE' {
            $newGroupSplat.SkuPartNumber = $SkuPartNumber
        }
        'ENTRAROLE' {
            $newGroupSplat.RoleName = $RoleName
            $newGroupSplat.AssignmentType = $AssignmentType
        }
    }
    $newGroup = Invoke-MWECommand -Command 'New-MWEGroupResource' -Splat $newGroupSplat

    switch ($intent) {
      'LICENSE' {
        if (-not $Mock) {
          $licenseAssignmentSplat=@{GroupId=$newGroup.Id; SkuPartNumber=$SkuPartNumber}
          Invoke-MWECommand -Command 'Set-MWEGroupLicenseAssignment' -Splat $licenseAssignmentSplat 
        }
      }
      'ENTRAROLE' {
        $roleAssignmentSplat=@{
          GroupId = $newGroup.Id
          RoleName = $RoleName
          AssignmentType = $AssignmentType
          RoleDefinitions = $roleDefinitions
          DirectoryRoles = $directoryRoles
        }
        if ($PSBoundParameters.ContainsKey('MaximumActivationHours')) { $roleAssignmentSplat.MaximumActivationHours = $MaximumActivationHours }
        if ($PSBoundParameters.ContainsKey('Force')) { $roleAssignmentSplat.Force = $Force }
        Invoke-MWECommand -Command 'Set-MWEGroupEntraRoleAssignment' -Splat $roleAssignmentSplat
      }
    }
}
