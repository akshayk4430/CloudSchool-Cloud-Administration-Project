# ============================================================
# 05-create-administrative-units.ps1
# CloudSchool - Administrative Units Creation & Member Assignment
# 
# Creates 17 AUs total:
#   - 1  AU-All-Students        (all 500 students)
#   - 6  AU-Grade-01 to 06      (students by grade)
#   - 10 AU-Dept-*              (staff by department)
#
# Dependencies: Microsoft.Graph module, connected session
# Run 01-connect-mggraph.ps1 first
# ============================================================

# ── IMPORTANT ───────────────────────────────────────────────
# AU-Grade-01 was already created manually in the portal.
# This script will SKIP creating it but WILL add members to it.
# ────────────────────────────────────────────────────────────

# ============================================================
# SECTION 1 — AU Definitions
# ============================================================

$auDefinitions = @(

    # --- All Students ---
    @{
        Name        = "AU-All-Students"
        Description = "Contains all 500 students across Grade 1 to Grade 6. Used for IT-wide student management without touching staff accounts."
        Departments = @("Grade1","Grade2","Grade3","Grade4","Grade5","Grade6")
        UserType    = "Student"
    },

    # --- Grade AUs ---
    @{
        Name        = "AU-Grade-01"
        Description = "Grade 1 students (Divisions A, B, C). Scoped boundary for Grade 1 management and future role delegation to Grade 1 Coordinator."
        Departments = @("Grade1")
        UserType    = "Student"
        AlreadyExists = $true
    },
    @{
        Name        = "AU-Grade-02"
        Description = "Grade 2 students (Divisions A, B, C). Scoped boundary for Grade 2 management and future role delegation to Grade 2 Coordinator."
        Departments = @("Grade2")
        UserType    = "Student"
    },
    @{
        Name        = "AU-Grade-03"
        Description = "Grade 3 students (Divisions A, B, C). Scoped boundary for Grade 3 management and future role delegation to Grade 3 Coordinator."
        Departments = @("Grade3")
        UserType    = "Student"
    },
    @{
        Name        = "AU-Grade-04"
        Description = "Grade 4 students (Divisions A, B, C). Scoped boundary for Grade 4 management and future role delegation to Grade 4 Coordinator."
        Departments = @("Grade4")
        UserType    = "Student"
    },
    @{
        Name        = "AU-Grade-05"
        Description = "Grade 5 students (Divisions A, B, C). Scoped boundary for Grade 5 management and future role delegation to Grade 5 Coordinator."
        Departments = @("Grade5")
        UserType    = "Student"
    },
    @{
        Name        = "AU-Grade-06"
        Description = "Grade 6 students (Divisions A, B, C). Scoped boundary for Grade 6 management and future role delegation to Grade 6 Coordinator."
        Departments = @("Grade6")
        UserType    = "Student"
    },

    # --- Staff Department AUs ---
    @{
        Name        = "AU-Dept-Management"
        Description = "Staff in Management department. Includes: Principal, Vice Principal, and senior leadership. 5 members."
        Departments = @("Management")
        UserType    = "Staff"
    },
    @{
        Name        = "AU-Dept-IT"
        Description = "Staff in IT department. Includes: IT administrators and support personnel. 5 members."
        Departments = @("IT")
        UserType    = "Staff"
    },
    @{
        Name        = "AU-Dept-Academics"
        Description = "Staff in Academics department. Includes: teaching and academic coordination staff. 6 members."
        Departments = @("Academics")
        UserType    = "Staff"
    },
    @{
        Name        = "AU-Dept-Administration"
        Description = "Staff in Administration department. Includes: school administrative staff. 4 members."
        Departments = @("Administration")
        UserType    = "Staff"
    },
    @{
        Name        = "AU-Dept-Accounts"
        Description = "Staff in Accounts department. Includes: finance and accounts personnel. 4 members."
        Departments = @("Accounts")
        UserType    = "Staff"
    },
    @{
        Name        = "AU-Dept-HR"
        Description = "Staff in HR department. Includes: human resources personnel. 2 members."
        Departments = @("HR")
        UserType    = "Staff"
    },
    @{
        Name        = "AU-Dept-Operations"
        Description = "Staff in Operations and Transport departments (consolidated). Includes: operations staff and transport personnel. 6 members."
        Departments = @("Operations","Transport")
        UserType    = "Staff"
    },
    @{
        Name        = "AU-Dept-Sports"
        Description = "Staff in Sports and Activities departments (consolidated). Includes: sports coordinators and activities personnel. 7 members."
        Departments = @("Sports","Activities")
        UserType    = "Staff"
    },
    @{
        Name        = "AU-Dept-StudentSupport"
        Description = "Staff in Student Support and Medical departments (consolidated). Includes: student counsellors, support staff, and medical personnel. 6 members."
        Departments = @("Student Support","Medical")
        UserType    = "Staff"
    },
    @{
        Name        = "AU-Dept-LibraryAndLab"
        Description = "Staff in Library and Lab departments (consolidated). Includes: librarians and laboratory staff. 5 members."
        Departments = @("Library","Lab")
        UserType    = "Staff"
    }
)

# ============================================================
# SECTION 2 — Pre-load All Users (one Graph call each type)
# ============================================================

Write-Host "`n[INFO] Fetching all students from Entra..." -ForegroundColor Cyan
$allStudents = Get-MgUser -All -Property Id,DisplayName,UserPrincipalName,Department,EmployeeType `
    | Where-Object { $_.EmployeeType -eq "Student" }
Write-Host "[INFO] Students fetched: $($allStudents.Count)" -ForegroundColor Cyan

Write-Host "[INFO] Fetching all staff from Entra..." -ForegroundColor Cyan
$allStaff = Get-MgUser -All -Property Id,DisplayName,UserPrincipalName,Department,EmployeeType `
    | Where-Object { $_.EmployeeType -eq "Staff" }
Write-Host "[INFO] Staff fetched: $($allStaff.Count)" -ForegroundColor Cyan

# ============================================================
# SECTION 3 — Create AUs and Assign Members
# ============================================================

foreach ($au in $auDefinitions) {

    Write-Host "`n========================================" -ForegroundColor Yellow
    Write-Host "Processing: $($au.Name)" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow

    # --- Step 1: Get or Create the AU ---
    $existingAU = Get-MgDirectoryAdministrativeUnit -All `
        | Where-Object { $_.DisplayName -eq $au.Name }

    if ($existingAU) {
        Write-Host "[SKIP] AU already exists: $($au.Name)" -ForegroundColor Green
        $auId = $existingAU.Id
    } else {
        Write-Host "[CREATE] Creating AU: $($au.Name)" -ForegroundColor Cyan
        $newAU = New-MgDirectoryAdministrativeUnit -DisplayName $au.Name -Description $au.Description
        $auId = $newAU.Id
        Write-Host "[OK] Created AU: $($au.Name) | ID: $auId" -ForegroundColor Green
    }

    # --- Step 2: Determine users to add ---
    if ($au.UserType -eq "Student") {
        $usersToAdd = $allStudents | Where-Object { $au.Departments -contains $_.Department }
    } else {
        $usersToAdd = $allStaff | Where-Object { $au.Departments -contains $_.Department }
    }

    Write-Host "[INFO] Users matched for $($au.Name): $($usersToAdd.Count)" -ForegroundColor Cyan

    # --- Step 3: Get existing AU members to avoid duplicates ---
    $existingMembers = Get-MgDirectoryAdministrativeUnitMember -AdministrativeUnitId $auId -All
    $existingMemberIds = $existingMembers | ForEach-Object { $_.Id }

    # --- Step 4: Add members ---
    $added = 0
    $skipped = 0

    foreach ($user in $usersToAdd) {
        if ($existingMemberIds -contains $user.Id) {
            $skipped++
            continue
        }

        try {
            $odataBody = @{
                "@odata.id" = "https://graph.microsoft.com/v1.0/users/$($user.Id)"
            }
            New-MgDirectoryAdministrativeUnitMemberByRef `
                -AdministrativeUnitId $auId `
                -BodyParameter $odataBody
            $added++
        } catch {
            Write-Host "[ERROR] Failed to add $($user.DisplayName): $_" -ForegroundColor Red
        }
    }

    Write-Host "[DONE] $($au.Name) — Added: $added | Skipped (already member): $skipped" -ForegroundColor Green
}

# ============================================================
# SECTION 4 — Summary
# ============================================================

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "AU Creation and Member Assignment Complete" -ForegroundColor Cyan
Write-Host "Total AUs processed: $($auDefinitions.Count)" -ForegroundColor Cyan
Write-Host "Expected total: 17" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
