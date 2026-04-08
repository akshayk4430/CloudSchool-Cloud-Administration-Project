# 02-create-students.ps1

$students = Import-Csv ".\data\students.csv"

foreach ($student in $students) {

    $passwordProfile = @{
        Password = "P@ssw0rd123!"
        ForceChangePasswordNextSignIn = $true
    }

    New-MgUser -DisplayName $student.DisplayName `
        -UserPrincipalName $student.UPN `
        -AccountEnabled $true `
        -MailNickname ($student.UPN.Split("@")[0]) `
        -PasswordProfile $passwordProfile `
        -AdditionalProperties @{
            "extensionAttribute1" = $student.Grade
            "extensionAttribute2" = $student.Division
            "employeeType" = "Student"
        }

    Write-Host "Created student: $($student.DisplayName)"
}
