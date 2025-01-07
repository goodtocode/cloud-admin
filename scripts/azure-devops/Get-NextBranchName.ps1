# A script for generating the git commands for production releases

$branchPrefix = "release/production" # eg $branchPrefix-$thisTuesday-$nextSprint
$sprintPrefix = "Sprint"

# returns the commands for next release branch name, eg release/production-2024.11.12-Sprint-22 e65a6199f3c902e99a9e18cc4aa1b2f18e1261aa
function generateGitCommands {
    _isConfigured
    git -C $Env:MONOLITH_PATH switch main --quiet
    git -C $Env:MONOLITH_PATH pull --quiet
    $thisTuesday = thisTuesdayBranchDate
    $rawSprint = deriveNextSprint
    $lastHash = lastTuesdayCommitHash
    $nextSprint = "$($rawSprint)".Trim() # always has a leading space
    $branchName = "$branchPrefix-$thisTuesday-$nextSprint"
    $branchNameWithHash = "$branchPrefix-$thisTuesday-$nextSprint $lastHash"
    $linebreak = $("" | Out-String)
    #TODO: if we already made our branch, detect and return that instead of foolishly incrementing the sprint
    $gitCommands = "  git -C $Env:MONOLITH_PATH switch -c $branchNameWithHash $linebreak  git -C $Env:MONOLITH_PATH push --set-upstream origin $branchName main"
    return $gitCommands
}

# check if the script can find the monolith
# to unset for testing: $Env:MONOLITH_PATH = [NullString]::Value
function _isConfigured {
    if ($Env:MONOLITH_PATH -ne $null) {
        Write-Host "configured for monolith at $Env:MONOLITH_PATH"
    } else {
        throw $monolithNotConfiguredError
    }
}

# returns git hash eg "e65a6199f3c902e99a9e18cc4aa1b2f18e1261aa"
function thisTuesdayBranchDate {
    # Get today's date
    $today = Get-Date

    # Calculate the number of days until the next Tuesday
    $daysUntilTuesday = (7 + [DayOfWeek]::Tuesday - $today.DayOfWeek) % 7

    # Get the date of the next Tuesday
    $nextTuesday = $today.AddDays($daysUntilTuesday)

    # Format the date as "YYYY.MM.DD"
    $formattedDate = $nextTuesday.ToString("yyyy.MM.dd")

    # Output the formatted date
    return $formattedDate.Trim()
}

#returns Sprint-XX where XX is incremented from the last release branch name
function deriveNextSprint {
    git -C $Env:MONOLITH_PATH switch main --quiet
    git -C $Env:MONOLITH_PATH pull --quiet
    $rawGitOutput = git -C $Env:MONOLITH_PATH ls-remote --sort=-v:refname --quiet | select-string -pattern "$sprintPrefix-\d+" | Select-Object -First 1
    if ($rawGitOutput -match "$sprintPrefix-(\d+)") {
        $sprintNumber = [int]$matches[1] + 1
        $currentSprint = "$sprintPrefix-$sprintNumber"
        return "$($currentSprint)".Trim()
    } else {
        Write-Output "can't parse sprint from $rawGitOutput"
        return 99
    }
}

# returns the most recently passed tuesday's last git hash before midnight
function lastTuesdayCommitHash {
    # Get the current date
    $currentDate = Get-Date

    # Calculate the number of days to subtract to get to the last Tuesday
    $daysToSubtract = ($currentDate.DayOfWeek - [System.DayOfWeek]::Tuesday + 7) % 7
    if ($daysToSubtract -eq 0) {
        $daysToSubtract = 7
    }

    # Get the date of the last Tuesday
    $lastTuesday = $currentDate.AddDays(-$daysToSubtract)

    #try to clamp between the last sprint
    $fortnight = 14
    $lastSprint = $lastTuesday.AddDays(-$fortnight)
    $lastSprintCutoff = [datetime]::ParseExact($lastSprint.ToString("yyyy-MM-dd"), "yyyy-MM-dd", $null).AddDays(1).AddSeconds(-1)
    git -C $Env:MONOLITH_PATH switch main --quiet
    git -C $Env:MONOLITH_PATH pull --quiet
    # git log --before="$lastTuesdayMidnightFormatted" --after="$lastSprintCutoff" | Select-String -Pattern 'commit (\w+)'
    # Set the time to midnight
    $lastTuesdayMidnight = [datetime]::ParseExact($lastTuesday.ToString("yyyy-MM-dd"), "yyyy-MM-dd", $null).AddDays(1).AddSeconds(-1)
    
    # Format the date as needed
    $lastTuesdayMidnightFormatted = $lastTuesdayMidnight.ToString("yyyy-MM-dd HH:mm:ss")
    
    # $cmd = "git log --before=`"$lastTuesdayMidnightFormatted`" --after=`"$lastSprintCutoff`" | Select-String -Pattern 'commit (\w+)'" | ConvertFrom-StringData -Delimiter ' ' | ForEach-Object {Write-Output $_.commit}
    # return $cmd
    # Switch to main, pull latest changes, and get the commit hash
    git -C $Env:MONOLITH_PATH switch main --quiet
    git -C $Env:MONOLITH_PATH pull --quiet
    $lastCommit = git -C $Env:MONOLITH_PATH log --before="$lastTuesdayMidnightFormatted" -1 | Select-String -Pattern 'commit (\w+)' | ForEach-Object { $_.Matches[0].Groups[1].Value }
    return $lastCommit.Trim()
}
