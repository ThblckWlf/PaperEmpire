param(
	[Parameter(ValueFromRemainingArguments = $true)]
	[string[]] $GodotArgs
)

$ErrorActionPreference = "Stop"

function Resolve-GodotExecutable {
	$candidates = @()

	if ($env:GODOT4) {
		$candidates += $env:GODOT4
	}

	if ($env:GODOT) {
		$candidates += $env:GODOT
	}

	foreach ($commandName in @("godot4", "godot")) {
		$command = Get-Command $commandName -ErrorAction SilentlyContinue
		if ($command) {
			$candidates += $command.Source
		}
	}

	$candidates += @(
		"$env:USERPROFILE\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe",
		"$env:USERPROFILE\Downloads\Godot_v4.6.2-stable_win64_console.exe",
		"$env:USERPROFILE\Downloads\Godot_v4.6.2-stable_win64.exe"
	)

	foreach ($candidate in $candidates) {
		if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
			return (Resolve-Path -LiteralPath $candidate).Path
		}
	}

	throw "Godot executable not found. Set GODOT4 to the Godot console executable path."
}

$godotExecutable = Resolve-GodotExecutable
& $godotExecutable @GodotArgs
exit $LASTEXITCODE
