**Decision**  
Any sign-in attempt using a **break-glass account** MUST generate an **alert** and
operational visibility.

This applies to:
- successful sign-ins
- failed sign-in attempts

The alert requirement is unconditional and does not depend on:
- location
- device state
- authentication method
- Conditional Access outcome


---

**Decision**  
The existence of an **administrative account without its paired standard account**
MUST generate an **alert** and operational visibility.

This condition is considered a **model violation** and must not exist silently.
