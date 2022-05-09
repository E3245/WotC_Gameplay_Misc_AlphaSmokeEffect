//
// FILE:	X2Effect_SmokeMortar
// AUTHOR:	E3245, Iridar
// DESC:	Advanced Smoke Detector
//			Removes smoke effect on soldiers contextually instead of normally just checking if the soldier is on a tile.
//			This means that once the soldier leaves the smoke clouds, the effect is removed, down to the non-smoked tile.
//

class X2Effect_AlphaSmoke extends X2Effect_SmokeGrenade;

var int AimBonus;
var bool bAimBonusAffectsMelee;

var localized string AlphaSmokeEffectFlyoverText;
var localized string AlphaSmokeEffectAcquiredString;
var localized string AlphaSmokeEffectLostString;

var localized string AlphaSmokeEffectTitle;

// This will remove effects that are on the unit that's in smoke. Effects with Shooter/Target will be cleansed for both.
// Note: This only works with persistent effects
var array<name>		 EffectsToRemove;

//=====================================================
//
// BEGIN EVENT LISTENERS
//
//=====================================================

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
    local X2EventManager        EventMgr;
    local XComGameState_Unit    UnitState;
    local Object                EffectObj;
    local XComGameStateHistory  History;
 
    History = `XCOMHISTORY;
    EffectObj = EffectGameState;
 
    //  Unit State of unit in smoke
    UnitState = XComGameState_Unit(History.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
 
	// Don't constantly activate if the unit is already affected by the effect
	if (UnitState != none)
	{
		EventMgr = `XEVENTMGR;
 
		//  EventMgr.RegisterForEvent(EffectObj, 'EventID', EventFn, Deferral, Priority, PreFilterObject,, CallbackData);
		//  EffectObj - Effect State of this particular effect.
		//  PreFilterObject - only listen to Events triggered by this object. Typically, UnitState of the unit this effect was applied to.
		//  CallbackData - any arbitrary object you want to pass along to EventFn. Often it is the Effect State so you can access its ApplyEffectParameters in the EventFn.
 
		//  When this Event is triggered (somewhere inside this Effect), the game will display the Flyover of the ability that has applied this effect.
		EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', CleanseSmokeEffectListener,				ELD_Immediate,, UnitState);
		EventMgr.RegisterForEvent(EffectObj, 'UnitMoveFinished', CleanseSmokeEffectListener_MoveFinished,	ELD_Immediate,, UnitState);

		`LOG("SUCCESS, Unit State found and registered for AbilityActivated and UnitMoveFinished! ObjectID:" @ UnitState.ObjectID $ " Name: " $ UnitState.GetFullName() $ " of " $ UnitState.GetMyTemplateName() ,, 'WotC_Gameplay_Misc_AlphaSmokeEffect');
    }
    else `LOG("ERROR, Could not find UnitState of Object ID: " $ EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID $ "!",, 'WotC_Gameplay_Misc_AlphaSmokeEffect');
}

static function EventListenerReturn CleanseSmokeEffectListener(Object EventData, Object EventSource, XComGameState NewGameState, Name EventID, Object CallbackData)
{
    local XComGameStateContext_Ability  AbilityContext;
    local XComGameState_Ability         AbilityState;
    local XComGameState_Unit            UnitState;
	local XComWorldData					WorldData;
	local XComGameState_Effect          EffectState;
	local TTile							Tile;
	local int i;

    //    AbilityState of the ability that was just activated.
    AbilityState = XComGameState_Ability(EventData);
	//    Unit that activated the ability.
    UnitState = XComGameState_Unit(EventSource);
    AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
	EffectState = UnitState.GetUnitAffectedByEffectState(default.EffectName);

	if (AbilityState == none || UnitState == none || AbilityContext == none || EffectState == none)
    {
        //    Something went wrong, exit listener.
        return ELR_NoInterrupt;
    }
	
	`LOG("Move ability activated by the unit:" @ UnitState.GetFullName(),, 'WotC_Gameplay_Misc_AlphaSmokeEffect');

	WorldData = `XWORLD;
	
	//	Interrupt stage, before the ability has actually gone through
	if (AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
	{
		for (i = 0; i < AbilityContext.InputContext.MovementPaths[0].MovementTiles.Length; i++)
		{
			Tile = AbilityContext.InputContext.MovementPaths[0].MovementTiles[i];

			// Test if the tile that we're on is not affected by our custom smoke effect, exit if false
			if (!WorldData.TileContainsWorldEffect(Tile, class'X2Effect_ApplyAlphaSmokeToWorld'.default.Class.Name))
			{
				`LOG("Path takes the unit" @ UnitState.GetFullName() @ "outside Smoke on tile #:" @ i @ ", removing effect.",, 'WotC_Gameplay_Misc_AlphaSmokeEffect');

				EffectState.RemoveEffect(NewGameState, NewGameState, true);
			}
			`LOG("Path DOES NOT take the unit" @ UnitState.GetFullName() @ "outside Smoke. NOT removing effect.",, 'WotC_Gameplay_Misc_AlphaSmokeEffect');
		}
	}

    return ELR_NoInterrupt;
}

// Cleaned up the function a bit for better readability
// Basically removes the effect if the unit moves to a tile that isn't affected by our custom smoke effect
static function EventListenerReturn CleanseSmokeEffectListener_MoveFinished(Object EventData, Object EventSource, XComGameState NewGameState, Name EventID, Object CallbackData)
{
    local XComGameState_Unit            UnitState, UnitInSmoke;
    local XComGameState_Effect          EffectState;

    //    Unit that finished moving.
    UnitState = XComGameState_Unit(EventSource);

    `LOG("X2Effect_SmokeMortar: CleanseSmokeEffectListener_MoveFinished:" @ UnitState.GetFullName(),, 'WotC_Gameplay_Misc_AlphaSmokeEffect');
    
    if (UnitState != none )
    {
		UnitInSmoke = XComGameState_Unit(NewGameState.GetGameStateForObjectID(UnitState.ObjectID));

		// Don't process if the unit is invalid
        if ( UnitInSmoke == none)
			return ELR_NoInterrupt;

		EffectState = UnitInSmoke.GetUnitAffectedByEffectState(default.EffectName);
		
		// Don't process if invalid or already removed
		if (EffectState == none || EffectState.bRemoved)
		    return ELR_NoInterrupt;

		// Test if the unit is the one that recently moved, exit if it's mismatched
		if (EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID != UnitInSmoke.ObjectID)
		    return ELR_NoInterrupt;

		// Test if the unit is in the custom smoke tile
		if (!UnitInSmoke.IsInWorldEffectTile(class'X2Effect_ApplyAlphaSmokeToWorld'.default.Class.Name) )
        {    
            `LOG("X2Effect_SmokeMortar: CleanseSmokeEffectListener_MoveFinished: unit is not in smoke, removing effect",, 'WotC_Gameplay_Misc_AlphaSmokeEffect');

            EffectState.RemoveEffect(NewGameState, NewGameState, true);
        } 
        else 
			`LOG("X2Effect_SmokeMortar: CleanseSmokeEffectListener_MoveFinished: unit is on a smoked tile.",, 'WotC_Gameplay_Misc_AlphaSmokeEffect');
    }

    return ELR_NoInterrupt;
}

//=====================================================
//
// END EVENT LISTENERS
//
//=====================================================

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
    local XComGameState_Unit            UnitInSmoke;
    local XComGameState_Effect          SuppressionEffectState;

	UnitInSmoke = XComGameState_Unit(kNewTargetState);

	// Clear any reserved action points
	UnitInSmoke.ReserveActionPoints.Length = 0;              //  remove overwatch et. al

	RemoveEffectStates(NewGameState, UnitInSmoke);

	// Apply effect as normal
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

simulated function RemoveEffectStates(XComGameState NewGameState, XComGameState_Unit UnitInSmoke)
{
	local name					EffectNameToRemove;
	local XComGameState_Effect	EffectStateToRemove;

	foreach EffectsToRemove(EffectNameToRemove)
	{
		EffectStateToRemove.RemoveEffect(NewGameState, NewGameState);
		break;
	}
}

/*
	Effect changes the chance to hit on itself that's given the effect

*/
function GetToHitAsTargetModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo ShotMod;

	if (Target.IsInWorldEffectTile(class'X2Effect_ApplyAlphaSmokeToWorld'.default.Class.Name))
	{
		ShotMod.ModType = eHit_Success;
		ShotMod.Value = HitMod;
		ShotMod.Reason = FriendlyName;
		ShotModifiers.AddItem(ShotMod);
	}
}

/*

	Effect changes the chance to hit to target

*/
function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo ShotInfo;

	if (Attacker.IsInWorldEffectTile(class'X2Effect_ApplyAlphaSmokeToWorld'.default.Class.Name))
	{
		if ( (bAimBonusAffectsMelee && bMelee) || (!bMelee) )
		{
			ShotInfo.ModType = eHit_Success;
			ShotInfo.Value = AimBonus;
			ShotInfo.Reason = FriendlyName;
			ShotModifiers.AddItem(ShotInfo);
		}
	}
}

function bool IsEffectCurrentlyRelevant(XComGameState_Effect EffectGameState, XComGameState_Unit TargetUnit)
{
	return TargetUnit.IsInWorldEffectTile(class'X2Effect_ApplyAlphaSmokeToWorld'.default.Class.Name);
}

static function SmokeGrenadeVisualizationTickedOrRemoved(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if (UnitState == none)
		return;

	// dead units, incap units, cosmetic units, or units removed from play should not be reported
	if (!UnitState.IsAlive() || UnitState.IsUnconscious() || UnitState.GetMyTemplate().bIsCosmetic || UnitState.bRemovedFromPlay)
	{
		return;
	}

	class'X2StatusEffects'.static.UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());
}

simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	SmokeGrenadeVisualizationTickedOrRemoved(VisualizeGameState, ActionMetadata, EffectApplyResult);
}

function bool SmokeEffectTicked(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_Effect kNewEffectState, XComGameState NewGameState, bool FirstApplication)
{
    local XComGameState_Unit SourceUnit;

    SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
    if (SourceUnit != none)
	{
		//Obviously, remove the effect if the Source Unit is not in the proper smoked tile
		if (!SourceUnit.IsInWorldEffectTile(class'X2Effect_ApplyAlphaSmokeToWorld'.default.Class.Name))
		{
		    `LOG("[SmokeEffectTicked()] Effect was removed since the unit was not in smoke",, 'WotC_Gameplay_Misc_AlphaSmokeEffect');
			return true;
		}
	}

	 `LOG("[SmokeEffectTicked()] Effect Tick continues",, 'WotC_Gameplay_Misc_AlphaSmokeEffect');

    return false; //  do not end the effect
}

DefaultProperties
{
	EffectName = "AlphaSmoke"
	DuplicateResponse = eDupe_Refresh
	bRemoveWhenTargetDies		 =	true
	EffectRemovedVisualizationFn = SmokeGrenadeVisualizationTickedOrRemoved;
	EffectTickedFn				 = SmokeEffectTicked;
}