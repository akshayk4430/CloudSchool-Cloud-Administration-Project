```markdown
# Troubleshooting and Fixes

## 📌 Purpose
This document records issues faced during the project and how they were resolved.

---

## ⚠️ Issue 1: Blank CSV Export

### Problem
While exporting users from groups, the CSV file was generated but contained no data.

### Possible Cause
- GroupId was not correctly retrieved
- Script failed to fetch group members

### Error Observed

### Fix / Approach
- Verified group name and existence
- Ensured correct retrieval of GroupId using:
```powershell
Get-MgGroup -Filter "displayName eq 'GROUP_NAME'"
