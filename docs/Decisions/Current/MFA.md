**Decision**  
MFA is a **baseline requirement** for all **interactive** sign-ins.
It is not optional and not risk-triggered.

Source: DEC-0008/1

---

**Decision**  
MFA applies to **all interactive user identities**, including:
- standard user accounts
- dedicated administrative accounts

Source: DEC-0008/2

---

**Decision**  
MFA methods are categorized based on their resistance to phishing,
strength of factor binding, and suitability for different identity risk levels.

#### Category A – Phishing-resistant, multi-factor (preferred)

**Allowed for:**  
- Standard users  
- Administrative users  

**Methods:**  
- Windows Hello for Business  
- FIDO2 security keys  
- Passkeys / WebAuthn authenticators  

#### Category B – Strong but phishing-susceptible (restricted)

**Allowed for:**  
- Standard users  

**Not allowed for:**  
- Administrative users  

**Methods:**  
- Microsoft Authenticator push notifications with number matching  

#### Category C – Weak or legacy MFA (disallowed)

**Allowed for:**  
- None  

**Methods:**  
- SMS OTP  
- Voice call MFA  
- Email OTP  
- Any MFA method based solely on shared secrets  

Source: DEC-0008/3

---

**Decision**  
This decision does **not** introduce MFA for administrative accounts.
It constrains how **future enforcement decisions** may select MFA methods
for different identity risk classes.

Administrative identities:
- **must always use Category A MFA methods**
  (phishing-resistant, multi-factor authentication)
- **must not use Category B or Category C MFA methods**
  under any circumstances

Standard user identities:
- may use **Category A or Category B** MFA methods
- must not use Category C MFA methods

Source: DEC-0008/4

---

**Decision**  
Device context may be considered an **input signal** but **cannot replace** MFA.

- For standard users, device context may influence *how* MFA is satisfied
- For administrative users, device context must never reduce MFA requirements

Source: DEC-0008/5

---

**Decision**  
Missing, unknown, or unreliable device context is treated as **untrusted**.

Source: DEC-0008/6

---

**Decision**  
Break-glass (emergency access) accounts are an **explicit, documented exception**
to the MFA baseline.

- MFA is not required for break-glass accounts
- These accounts exist solely for recovery scenarios

Source: DEC-0008/7

---

**Decision**  
Phishing-resistant authentication methods that use **multiple independent
factors** are treated as **MFA satisfied**.

Source: DEC-0008/8

---

**Decision**  
Passwordless methods that use multiple independent factors satisfy MFA
requirements without additional steps.

Source: DEC-0008/9

---

**Decision**  
Legacy authentication is incompatible with the MFA baseline and is disallowed
by default.

Source: DEC-0008/10

---

**Decision**  
Authentication scoping is expressed using **explicit identity groups** that define
which identities later authentication policies will apply to.

This decision defines **identity categorization and policy scope only**.
Authentication requirements and enforcement are defined in a separate
decision domain.

**Authoritative groups**

- **U-AUTH-INTERACTIVE** — standard interactive user identities  
- **U-AUTH-ADMIN-INTERACTIVE** — administrative interactive identities  
- **U-AUTH-EXCLUDE-BREAKGLASS** — emergency access identities  

**Group semantics**

- Administrative identities are represented by a **dynamic group** based on a
  deterministic classification rule to prevent accidental omission
- Standard users include all interactive users not classified as admin or break-glass
- Break-glass identities are represented by a **static, manually governed group**
- Service and workload identities are **out of scope** and not subject to MFA

Source: DEC-0008/11