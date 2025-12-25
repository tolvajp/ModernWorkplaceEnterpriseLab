# Runbook – Group-based Access and Licensing Model

## Purpose
Create enterprise-model groups (license, role, department) as defined in DEC-0004.

## Preconditions
- Microsoft Entra ID tenant exists
- Global Administrator permissions available
- Microsoft Graph PowerShell module installed

## Steps
1. Load group definition JSON
2. Create groups if not present
3. Validate creation

## Validation
- Groups exist in Entra ID
- Names and descriptions match JSON
