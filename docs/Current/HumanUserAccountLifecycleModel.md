**Decision**  
All **human user accounts** are created **exclusively via script**.

- Manual creation is not a supported creation path.
- Manual actions are allowed only:
  - for **customization not supported by the script**, or
  - to implement **later decisions** before automation exists.

Source: DEC-0015/1

---

**Decision**  
Manual changes to user accounts are permitted only when:
1) the creation script does not support the required change, or  
2) a later decision requires updates not yet automated.

Manual handling is **exceptional**, not an alternative operating mode.

Source: DEC-0015/2

---

**Decision**  
Each human user is represented by **exactly one standard (normal) account**.

This account is mandatory and represents the person’s primary identity.

Source: DEC-0015/3

---

**Decision**  
Administrative accounts are **paired complements** of standard accounts.

- An administrative account cannot exist without its paired standard account.
- Administrative accounts exist solely for privileged operations.

Source: DEC-0015/4

---

**Decision**  
The standard account and its paired administrative account:
- are created together (when admin access is needed)
- are disabled together
- are deleted together

Source: DEC-0015/5

---

**Decision**  
Administrative accounts are issued **only when privileged roles are required**
(e.g. Entra roles, Azure roles).

They are not pre-created “just in case”.

Source: DEC-0015/6

---

**Decision**  
Administrative accounts are deterministically derived from standard accounts
by applying an `a-` prefix.

Source: DEC-0015/7

---

**Decision**  
When a human identity lifecycle ends:

- both the standard account and its paired administrative account are **deleted directly**
- no intermediate “disabled” state is required or enforced

Account deletion relies on the platform’s built-in **soft-delete mechanism** as protection
against accidental removal.

Source: DEC-0015/8

---

**Decision**  
UPN reuse is allowed after account deletion.

- No permanent UPN reservation or tombstone registry is maintained.
- Platform default behavior is accepted.

Source: DEC-0015/9

---

**Decision**  
The tenant contains exactly **two break-glass accounts**:

- domain-level emergency identities
- not tied to any person
- not lifecycle-coupled to standard or admin accounts
- credentials stored offline (“in a safe”)

Source: DEC-0015/10

---

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

Source: DEC-0015/11

---

**Decision**  
The existence of an **administrative account without its paired standard account**
MUST generate an **alert** and operational visibility.

This condition is considered a **model violation** and must not exist silently.

Source: DEC-0015/12
