## Decision
I decided to use **Microsoft Entra ID** as the identity platform and **Microsoft Intune** as the endpoint management platform for this lab.

Entra ID will be the **authoritative identity control plane**.  
Intune will be the **authoritative endpoint state and compliance control plane**, providing device-related signals that can be consumed by Entra ID access controls.
Source: DEC-0000/1