# Resource Group Design

## 1. Purpose

Resource Groups are logical containers used to organize and manage Azure resources.

They are used for:

- Organizing resources

- Applying RBAC (access control)

- Cost tracking

- Lifecycle management

---

## 2. Design Approach

The project follows a combined model:

- Environment-based separation (Prod, Dev)

- Workload-based separation (Network, Compute, Storage, Monitoring)

This approach provides:

- Clear structure

- Better troubleshooting

- Cost visibility

- Scalable design

---

## 3. Resource Groups Created

Production:

- RG-Network-Prod

- RG-Compute-Prod

- RG-Storage-Prod

- RG-Monitoring-Prod

Development:

- RG-Network-Dev

- RG-Compute-Dev

---

## 4. Tagging Strategy

Tags applied:

- Environment = Prod / Dev

- Project = CloudSchool

Used for:

- Cost tracking

- Filtering

- Governance (Azure Policy later)

---

## 5. Key Learning

- Resource Groups are logical only

- They do not isolate networking

- Resources across RGs can communicate

- Naming + tagging is critical in real environments

---

## 6. Automation

Created using:

- PowerShell (Az module)

- CSV-driven input

- Idempotent logic (Create / Skip)

This ensures:

- No duplication

- Repeatable deployment

- Clean automation design
