//
// Observer class based on robojumper's DazedMesh commit for Long War of the Chosen. https://github.com/Grobobobo/lwotc/commit/4ccdb651eee955f7bf267a8c925f092bc6d7fc81
// However, the similarities end there as this class uses an Event Listener to add/remove tiles based on submitted context, instead of the provided Observer Interface.
// We still use the Observer interface since it's an actor class that can instantiate a mesh, unlike Object classes.
//
class AlphaSmokeTileListener extends Actor implements(X2VisualizationMgrObserverInterface);

var AlphaSmokeInstancedTileComponent	TileComp;

// List of References to currently rendered Tiles from these World Effects. Wiped when the Player starts their turn.
var array<StateObjectReference>			ActiveGameplayTileUpdates;

event PostBeginPlay()
{
	local Object ThisObj;

	// Create the tile component that the X2TargetMethod will use
	TileComp = new class'AlphaSmokeInstancedTileComponent';
	TileComp.CustomInit();
	TileComp.SetMesh(StaticMesh(DynamicLoadObject("UILibrary_Icons_AlphaSmoke.Meshes.SmokeTile_Safe_Enter", class'StaticMesh')));

	// Listen on every GameplayTileEffectUpdate event
	// Trigger this event when the visualization starts
	ThisObj = self;

	`XEVENTMGR.RegisterForEvent(ThisObj, 'GameplayTileEffectUpdate', OnGameplayTileEffectUpdate, ELD_OnVisualizationBlockCompleted, 50);

	`XCOMVISUALIZATIONMGR.RegisterObserver(self);

	//`LOG("[PostBeginPlay()] Observer registered", false, 'WotC_Gameplay_Misc_AlphaSmokeEffect');
}

// Waits for any gameplay changes to any tiles and creates the tile mesh on the affected tiles within XComGameState_WorldEffectTileData
function EventListenerReturn OnGameplayTileEffectUpdate(Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
	local XComGameStateHistory						History;
	local XComGameState_WorldEffectTileData			GameplayTileUpdate;
	local array<XComGameState_WorldEffectTileData>	arrGameplayTileUpdates;
	local StateObjectReference						TileUpdateRef;

	History = `XCOMHISTORY;

	// Reset variables
	arrGameplayTileUpdates.Length = 0;

	// Only newly created world effects by X2Effect_World go here
	GameplayTileUpdate = XComGameState_WorldEffectTileData(EventData);

	// X2Effect_World path.
	if ( GameplayTileUpdate != none && GameplayTileUpdate.WorldEffectClassName == 'X2Effect_ApplyAlphaSmokeToWorld' )
	{
		arrGameplayTileUpdates.AddItem(GameplayTileUpdate);

		// Append the contents of the previous array that will get rendered by this class.
		if (ActiveGameplayTileUpdates.Length > 0)
		{
			foreach ActiveGameplayTileUpdates(TileUpdateRef)
			{
				GameplayTileUpdate = XComGameState_WorldEffectTileData(`XCOMHISTORY.GetGameStateForObjectID(TileUpdateRef.ObjectID));
				arrGameplayTileUpdates.AddItem(GameplayTileUpdate);
			}
		}
	}
	// XComGameStateContext_UpdateWorldEffects path.
	// Otherwise we check the GameState and find them ourselves
	// XComGameStateContext_UpdateWorldEffects does not send any gamestate over EventData or EventSource
	else if (GameplayTileUpdate == none )
	{
		foreach NewGameState.IterateByClassType(class'XComGameState_WorldEffectTileData', GameplayTileUpdate)
		{
			if ( GameplayTileUpdate.WorldEffectClassName != 'X2Effect_ApplyAlphaSmokeToWorld' ) 
				continue;
			
			arrGameplayTileUpdates.AddItem(GameplayTileUpdate);
		}
	}

	// Update regardless of tiles left
	UpdateAlphaSmokedTiles(arrGameplayTileUpdates);

	return ELR_NoInterrupt;
}

// The actual function that creates the tiles
function UpdateAlphaSmokedTiles(array<XComGameState_WorldEffectTileData> arrGameplayTileUpdates)
{
	local XComGameStateHistory				History;
	local XComGameState_Ability				Ability;
	local XComGameState_WorldEffectTileData SingletonTileUpdateState;

	local array<TTile>						Tiles;
	local WorldEffectTileDataContainer		IterWETDC;

	// Wipe the array because it is stale now
	ActiveGameplayTileUpdates.Length = 0;

	//`LOG("[" $ GetFuncName() $ "] Creating Tiles for " $ arrGameplayTileUpdates.Length $ " world effects", true, 'WotC_Gameplay_Misc_AlphaSmokeEffect');
	
	// Reset tiles
	Tiles.Length = 0;

	foreach arrGameplayTileUpdates(SingletonTileUpdateState)
	{
		//`LOG("[" $ GetFuncName() $ "] Alpha Smoke World Effect ObjectID: " $ SingletonTileUpdateState.ObjectID $ ", UnitState ObjectID: " $ SingletonTileUpdateState.StoredTileData[0].Data.SourceStateObjectID $ ", ItemState ObjectID: " $ SingletonTileUpdateState.StoredTileData[0].Data.ItemStateObjectID, true, 'WotC_Gameplay_Misc_AlphaSmokeEffect');
	
		// Only tiles that do not have -1 Turns and have tiles in them are valid
		if(SingletonTileUpdateState.StoredTileData[0].Data.NumTurns >= 0 && SingletonTileUpdateState.StoredTileData.Length > 0)
		{
			`LOG("[" $ GetFuncName() $ "] Object ID " $ SingletonTileUpdateState.ObjectID $ " has " $ SingletonTileUpdateState.StoredTileData[0].Data.NumTurns $ " turns left!" , true, 'WotC_Gameplay_Misc_AlphaSmokeEffect');
			
			foreach SingletonTileUpdateState.StoredTileData(IterWETDC)
			{
				Tiles.AddItem(IterWETDC.Tile);
			}
		}

		//`LOG("[" $ GetFuncName() $ "] Added " $ Tiles.Length $ " tiles to array" , true, 'WotC_Gameplay_Misc_AlphaSmokeEffect');

		// Set reference
		ActiveGameplayTileUpdates.AddItem(SingletonTileUpdateState.GetReference());
	}

	// Grab the first ability used as a mock
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Ability', Ability, , , `XCOMVISUALIZATIONMGR.LastStateHistoryVisualized)
	{
		break;
	}

	// Set tile component regardless of results
	SetTilesForComponent(Ability, Tiles);
}

function SetTilesForComponent(const XComGameState_Ability AbilityState, const array<TTile> Tiles)
{
	TileComp.SetMockParameters(AbilityState);
	TileComp.SetTiles(Tiles);
	TileComp.SetMockParameters(none);
}

/// <summary>
/// Called when an active visualization block is marked complete 
/// </summary>
event OnVisualizationBlockComplete(XComGameState AssociatedGameState) { }

/// <summary>
/// Called when the visualizer runs out of active and pending blocks, and becomes idle
/// </summary>
event OnVisualizationIdle() { }

/// <summary>
/// Called when the active unit selection changes
/// </summary>
event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit) { }