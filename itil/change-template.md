# Change request – CHG-XXXX: <short title>

| Field | Value |
|-------|-------|
| Change ID | CHG-XXXX |
| Type | Standard / Normal / Emergency |
| Requested by | |
| Implemented by | |
| Affected host(s) / service | |
| Planned window (date, start–end) | |
| Status | Draft / Approved / Implemented / Rolled back / Closed |

## 1. Description

What will be changed, why, and what the end result should be.

## 2. Risk

| Question | Answer |
|----------|--------|
| What can go wrong? | |
| Impact if it goes wrong | |
| Likelihood | Low / Medium / High |
| Risk level | Low / Medium / High |
| Downtime expected? | |
| Customer notification needed? | |

## 3. Pre-checks

- [ ] Backup or snapshot taken
- [ ] Current state recorded (versions, config, service status)
- [ ] Customer informed of the window

## 4. Implementation steps

1.
2.
3.

## 5. Test plan

How I prove the change worked (commands to run and the expected result). Include a dry run if possible
(for example `ansible-playbook --check --diff --limit <one host>`).

## 6. Rollback plan

Exact steps to undo the change, and the trigger for using them (for example "service not healthy 10 minutes after the change").

1.
2.

## 7. Approval

| Role | Name | Date | Decision |
|------|------|------|----------|
| Change owner | | | |
| Approver (CAB / team lead) | | | |

## 8. Result

- Outcome: Successful / Failed / Rolled back
- What happened during implementation:
- Test plan results:
- Follow-up actions:
