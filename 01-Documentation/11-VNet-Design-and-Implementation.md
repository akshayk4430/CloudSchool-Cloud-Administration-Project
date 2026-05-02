# VNet Design and Implementation

## 1. Purpose

Virtual Networks provide private network boundaries for Azure resources.

In this project, VNets are used to separate Production and Development environments and prepare the foundation for future compute, storage, private endpoints, and security controls.

---

## 2. Design Approach

The network design follows environment isolation:

- Separate VNets for Prod and Dev
- No communication between environments by default
- Clean address space separation to avoid overlap

This ensures:
- Better security
- Easier troubleshooting
- Clear separation of workloads

---

## 3. Address Space Design

Production:
- VNet-CloudSchool-Prod → 10.10.0.0/16

Development:
- VNet-CloudSchool-Dev → 10.20.0.0/16

Reason:
- Non-overlapping ranges
- Easy future expansion
- Industry standard private IP usage

---

## 4. Subnet Design

### Production

- SNet-Management-Prod → 10.10.1.0/24
- SNet-Workload-Prod → 10.10.2.0/24
- SNet-PrivateEndpoint-Prod → 10.10.3.0/24

### Development

- SNet-Management-Dev → 10.20.1.0/24
- SNet-Workload-Dev → 10.20.2.0/24

---

## 5. Subnet Purpose

Management:
- For administrative access (jump box, bastion later)

Workload:
- Application servers, VMs, services

Private Endpoint (Prod only):
- For secure private access to PaaS services (Storage, SQL, etc.)

---

## 6. Implementation (PowerShell)

Key commands used:

- New-AzVirtualNetwork
- Add-AzVirtualNetworkSubnetConfig
- Set-AzVirtualNetwork

Process followed:

1. Create VNet
2. Add subnets (local object)
3. Apply configuration using Set-AzVirtualNetwork
4. Validate using Get-AzVirtualNetwork

---

## 7. Validation

Verified using:

- Get-AzVirtualNetwork
- AddressSpace confirmation
- Subnet listing

Both VNets:
- ProvisioningState = Succeeded
- Correct address spaces applied
- Subnets deployed as designed

---

## 8. Key Learning

- VNets are region-bound
- Subnets are created locally first, then applied
- Address planning is critical before deployment
- Environment separation improves real-world design quality