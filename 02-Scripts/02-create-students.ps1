# 02-create-students.ps1

param(
       [string]$CsvPath = ".\03-CSV-Templates\students.csv"
)
$students = Import-Csv $CsvPath -Delimiter ','

$results = @()

foreach ($student in $students) {
	
	Write-Host "Processing $($student.DisplayName)"

	$user = @{DisplayName = "Wrong Name"}

	if (-not $user) {
		$action = "Create"
		$notes = "User does not exist"
	}
	else{
		if ($user.DisplayName -ne $student.DisplayName){
			
			$action = "Update"
			$notes = "DisplayName Mismatch"
		}
		else {
			$action = "Skip"
			$notes = "Already Correct"
		}
	}

	$results +=[pscustomobject]@{
		UserPrincipalName = $student.UserPrincipalName
		DisplayName	  = $student.DisplayName
		Action		  = $action
		Status		  = "Success"
		Notes		  = $notes
	}
}

$results | Export-Csv ".\05-Outputs\students-test-results.csv"	-NoTypeInformation
Write-Host "Script completed. Results exported." -ForegroundColor Green	