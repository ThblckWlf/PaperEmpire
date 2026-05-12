extends PanelContainer


signal returnToMainMenuRequested

const UI_ASSET_THEME := preload("res://scenes/ui/ui_asset_theme.gd")

# Displays run loss rewards and summary data provided by the game-over event.
var titleLabel: Label
var subtitleLabel: Label
var crownsLabel: Label
var summaryLabel: Label
var returnButton: Button


func _ready() -> void:
	_buildLayout()
	_applyAssetTheme()
	returnButton.pressed.connect(_onReturnPressed)


func setData(data: Dictionary) -> void:
	var runStatsValue: Variant = data.get("runStats", {})
	var runStats := {}
	if runStatsValue is Dictionary:
		runStats = runStatsValue as Dictionary
	var monthsSurvived := maxi(0, int(runStats.get("monthsSurvived", 0)))
	var years := int(monthsSurvived / 12)
	var months := monthsSurvived % 12
	titleLabel.text = "Game Over"
	subtitleLabel.text = "Du besitzt kein Land mehr."
	crownsLabel.text = "Kronen erhalten: %d" % int(data.get("crownsEarned", 0))

	var lines := PackedStringArray()
	lines.append("Überlebt: %d Jahre, %d Monate" % [years, months])
	lines.append("Länder erobert: %d" % int(runStats.get("countriesConquered", 0)))
	lines.append("Max. Länderbesitz: %d" % int(runStats.get("maxCountriesOwned", 0)))
	lines.append("Kämpfe gewonnen: %d" % int(runStats.get("battlesWon", 0)))
	lines.append("Höchste Bedrohung: %.0f%%" % float(runStats.get("highestThreatReached", 0.0)))
	var summaryText := ""
	for line in lines:
		if summaryText != "":
			summaryText += "\n"
		summaryText += line
	summaryLabel.text = summaryText


func _buildLayout() -> void:
	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	add_child(margin)

	var column := VBoxContainer.new()
	column.name = "VBoxContainer"
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	titleLabel = Label.new()
	titleLabel.name = "TitleLabel"
	titleLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(titleLabel)

	subtitleLabel = Label.new()
	subtitleLabel.name = "SubtitleLabel"
	subtitleLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(subtitleLabel)

	crownsLabel = Label.new()
	crownsLabel.name = "CrownsLabel"
	crownsLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(crownsLabel)

	summaryLabel = Label.new()
	summaryLabel.name = "SummaryLabel"
	summaryLabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(summaryLabel)

	returnButton = Button.new()
	returnButton.name = "ReturnToMainMenuButton"
	returnButton.text = "Zurück zum Hauptmenü"
	column.add_child(returnButton)


func _applyAssetTheme() -> void:
	UI_ASSET_THEME.applyPanel(self, UI_ASSET_THEME.PANEL_MODAL_PATH, 42.0, 14.0)
	UI_ASSET_THEME.applyTitleLabel(titleLabel, 28)
	UI_ASSET_THEME.applyLabel(subtitleLabel, 18)
	UI_ASSET_THEME.applyTitleLabel(crownsLabel, 22)
	UI_ASSET_THEME.applyLabel(summaryLabel, 18)
	UI_ASSET_THEME.applyTextButton(returnButton, false, false)
	UI_ASSET_THEME.applyButtonIcon(returnButton, UI_ASSET_THEME.ICON_BACK_PATH, "Return to main menu", 28)


func _onReturnPressed() -> void:
	returnToMainMenuRequested.emit()
