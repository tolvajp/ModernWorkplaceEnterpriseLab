**Decision**  
Conditional Access MUST NOT be used to implement, replace, or duplicate
**authorization** logic.

- CA MUST NOT be used to decide whether an identity is *entitled* to access a resource.
- Authorization is handled exclusively via **roles, groups, and permissions**.
- CA evaluates only whether the access attempt is **sufficiently secure**, not whether it is **permitted**.

Source: DEC-0009/1

---

**Decision**  
Multi-Factor Authentication (MFA) is treated as a **condition** within the CA model.

- CA expresses **which MFA assurance level is required**
- MFA policy defines **which authentication methods satisfy that assurance**
- CA policy enforces this in combination with other security inputs

Source: DEC-0009/2

---

**Decision**  
The CA model defines an explicit **baseline security posture** that is:
- **implementable**
- the minimum acceptable posture for access (no identity may go below it)
- only maintainable or strengthenable (never weakened)

**Baseline security posture (minimum)**  
For **interactive human identities**, baseline security includes at minimum:
- **MFA required**, at the assurance level defined by **DEC-0008**
  (i.e., allowed MFA methods and assurance categories are governed by DEC-0008)
- **No high-confidence compromise** signal present (see Atomic Decision 5)
- Missing signals MUST NOT be used to relax requirements (see Atomic Decision 4)

**Strictness (above baseline)**  
Additional restrictions are permitted a
  access modes or requiring stronger posture for accesss explicit strictness above baseline, e.g.:
- device-based restrictions (when device trust/compliance exists), such as limiting

These strictness controls are **intended to be implementable later**, but are **not
implemented in this lab at this time**.

Source: DEC-0009/3

---

**Decision**  
Missing, unknown, or unavailable security signals MUST **not** be used to relax
security requirements.

- Unknown = **untrusted**
- A lack of information cannot reduce assurance

Source: DEC-0009/4

---

**Decision**  
When a high-confidence malicious activity signal is present, access is **blocked
unconditionally** for all **non-break-glass** identity types.

- Applies to:
  - standard users
  - administrative users
  - service / automation identities
- Independent of:
  - MFA state
  - device context
  - location

High confidence malicious activity signals include but not limited to:
  - Leaked credentials
  - Password spray
  - Malware detection
  - Tamper attempt
  - Sign-in from known malicious IP
  - Credential harvesting detected
  - LSASS memory access
  - C2 (Command & Control) communication
  - Persistence mechanism detected
  - Ransomware behavior
  - Privilege escalation exploit detected

    Not all listed signals are required to be implemented in this lab.
    Signals may originate from identity, endpoint, or infrastructure telemetry. 


**Break-glass treatment**  
Break-glass identities are **explicitly excluded from CA enforcement** and are not
subject to compromise-driven CA blocking. Break-glass access MUST remain possible
even if compromise signals produce false positives.

**Operational visibility**  
High-confidence compromise events MUST generate operational visibility (logging,
alerting, investigation trigger).

Source: DEC-0009/5

---

**Decision**  
Location and network context may only contribute to **increased strictness** when
combined with other risk signals. Location is never used:
- as a standalone trust signal
- to relax security requirements

Source: DEC-0009/6

---


**Decision**  
Conditional Access is treated as a **sign-in gate**:
- Decisions are made at authentication time
- Session-level and continuous enforcement are out of scope for this model

Source: DEC-0009/7

---


**Decision**  
The CA model applies a **global, application-agnostic baseline**.
Application-specific strictness is allowed only as an explicit, justified exception.

Source: DEC-0009/8

---

**Decision**  
Authentication methods/protocols that cannot satisfy the baseline security posture
are considered **incompatible by default**.

Source: DEC-0009/9

---

**Decision**  
The CA model requires operational visibility for significant security events,
including at minimum:
- high-confidence compromise-driven blocks
- elevated risk-driven strictness triggers
- exception usage

This decision does not prescribe tooling; it defines the expectation that such
events are observable and reviewable.

Source: DEC-0009/10

---

**Decision**  
Automation and service identities are within the **conceptual scope** of CA:
- they must be governable via security signals
- compromise signals must be enforceable (deny)

However, the **detailed CA model and implementation** for automation identities are
explicitly out of scope for this lab.


Source: DEC-0009/11

---

**Decision**  
Exceptions to the CA model are permitted only with:
- documented business justification
- explicit approval
- defined expiration
- regular review

Source: DEC-0009/12
