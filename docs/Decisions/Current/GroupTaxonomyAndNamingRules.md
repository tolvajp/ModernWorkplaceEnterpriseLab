**Decision**  
All managed group names follow the structure:

`<Principal>-<Function>-<Specifier>-<Specifier>-...`

Where:
- `Principal` is exactly one of:
  - `U` – user principals
  - `D` – device principals
  - `X` – mixed principals (exceptional use only)
- `Function` expresses the high-level intent of the group
- One or more `Specifier` tokens qualify the function

At least one `Specifier` token is mandatory.

Source: DEC-0004/1

---

**Decision**  
Only the following characters are allowed in group names:

- A–Z  
- a–z  
- 0–9  
- `-`  
- `_`

Any other character is invalid.

source: DEC-0004/2

---

**Decision**  
Whitespace and any character outside the allowed set (A–Z a–z 0–9 - _) are automatically removed
during group name generation.

Source: DEC-0004/3

---

**Decision**  
The `mailNickname` property is set to exactly the same value as the normalized group name.
It should not be longer than 64 character

Source: DEC-0004/4

----

**Decision**  
Every managed group must have a non-empty, human-readable description that clearly states
the group’s intended purpose.


Source: DEC-0004/5

---

**Decision**  
All managed groups are created exclusively by automation scripts.
Manual creation of managed groups is not permitted.

Source: DEC-0004/6

---

**Decision**  
The group creation logic must be modular so that new group functions or rules
can be added with minimal refactoring existing behaviour.

Source: DEC-0004/7