# Resource Group Design

## 1. Purpose

Resource Groups are logical containers used to organize and manage Azure resources.  
They help in:

- Structuring resources in a clean way  
- Applying access control (RBAC)  
- Tracking costs  
- Managing lifecycle (create, update, delete)

---

## 2. Design Approach

The project follows a **combined model**:

- Environment-based separation (Prod, Dev)
- Workload-based separation (Network, Compute, Storage, Monitoring)

This approach is commonly used in real-world environments because it provides:

- Better organization  
- Clear ownership boundaries  
- Easier troubleshooting  
- Improved cost visibility  

---

## 3. Resource Groups Created

### Production Environment

- RG-Network-Prod  
- RG-Compute-Prod  
- RG-Storage-Prod  
- RG-Monitoring-Prod  

### Development Environment

- RG-Network-Dev  
- RG-Compute-Dev  

---

## 4. Tagging Strategy

Each Resource Group includes the following tags:

| Key         | Value         |
|-------------|--------------|
| Environment | Prod / Dev   |
| Project     | CloudSchool  |

Tags are used for:

- Cost tracking  
- Resource filtering  
- Governance policies (Azure Policy)  

---

## 5. Key Learning

- Resource Groups are **logical containers**, not dependency boundaries  
- Resources in different Resource Groups can still communicate with each other  
- Proper design improves scalability, management, and cost control  
- Using a consistent naming and tagging strategy is critical in production environments  

---

## 6. Automation Approach

Resource Groups are created using:

- PowerShell (Az module)  
- CSV-driven input (`resource-groups.csv`)  
- Idempotent script (Create / Skip logic)  

This ensures:

- No duplicate resources  
- Easy updates through CSV  
- Reusable automation  

---