$Script:ManifestPath = "$env:USERPROFILE\.cedanl-devsetup\state.json"

function Test-PreviousSetup {
    return Test-Path $Script:ManifestPath
}
