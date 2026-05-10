extends RefCounted


const META_PROGRESS_SIMULATION := preload("res://src/core/simulation/meta_progress_simulation.gd")


static func createShopPanelData(metaProgressData: Dictionary, metaUpgradeRows: Array[Dictionary]) -> Dictionary:
	return {
		"crowns": int(metaProgressData.get("crowns", 0)),
		"rows": META_PROGRESS_SIMULATION.createShopRows(metaProgressData, metaUpgradeRows),
	}
