# Map tab to accept suggestion when it's at the end of current editing line
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab `
    -BriefDescription ForwardCharAndAcceptNextSuggestionWord `
    -LongDescription "Hi Tab in the current editing line and accept the next word in suggestion when it's at the end of current editing line" `
    -ScriptBlock { 
    param($key, $arg)    
    $line = $null    
    $cursor = $null    
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)    
    if ($cursor -lt $line.Length) { [Microsoft.PowerShell.PSConsoleReadLine]::ForwardChar($key, $arg) } 
    else { [Microsoft.PowerShell.PSConsoleReadLine]::AcceptSuggestion($key, $arg) } 
} 