// This is an Unreal Script
class UIScreenListener_UITacticalHUD_AlphaSmokeTiles extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local UITacticalHUD TacticalHUD;

	TacticalHUD = UITacticalHUD(Screen);

	// Do nothing if we're not in the tactical hud screen
	if (TacticalHUD == none)
		return;

	// Spawn Alpha Smoke Pathing visualization if set in config
	if (class'XComDownloadableContentInfo_AlphaSmokeEffect'.default.bEnableTileVisualization)
		`XWORLDINFO.Spawn(class'AlphaSmokeTileListener');
}