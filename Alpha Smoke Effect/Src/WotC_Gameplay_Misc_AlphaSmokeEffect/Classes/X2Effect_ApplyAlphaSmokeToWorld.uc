//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_ApplyAlphaSmokeToWorld.uc
//  AUTHOR:  Joshua Bouscher
//	EDITS:	 E3245
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_ApplyAlphaSmokeToWorld extends X2Effect_ApplySmokeGrenadeToWorld;

var string								SmokeParticleSystemFill_Path;
var bool								bUseMk2Smoke;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
}

event array<X2Effect> GetTileEnteredEffects()
{
	local array<X2Effect> TileEnteredEffects;

	if (bUseMk2Smoke)
		TileEnteredEffects.AddItem(class'XComDownloadableContentInfo_AlphaSmokeEffect'.static.AlphaSmokeEffectMk2());
	else
		TileEnteredEffects.AddItem(class'XComDownloadableContentInfo_AlphaSmokeEffect'.static.AlphaSmokeEffectMk1());

	return TileEnteredEffects;
}

event array<ParticleSystem> GetParticleSystem_Fill()
{
	local array<ParticleSystem> ParticleSystems;
	ParticleSystems.AddItem(none);
	ParticleSystems.AddItem(ParticleSystem(DynamicLoadObject(SmokeParticleSystemFill_Path, class'ParticleSystem')));
	return ParticleSystems;
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, name EffectApplyResult)
{
	local X2Action_UpdateWorldEffects_Smoke AddSmokeAction;
	if( ActionMetadata.StateObject_NewState.IsA('XComGameState_WorldEffectTileData') )
	{
		AddSmokeAction = X2Action_UpdateWorldEffects_Smoke(class'X2Action_UpdateWorldEffects_Smoke'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		AddSmokeAction.bCenterTile = bCenterTile;
		AddSmokeAction.SetParticleSystems(GetParticleSystem_Fill());
	}
}

simulated function AddX2ActionsForVisualization_Tick(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const int TickIndex, XComGameState_Effect EffectState)
{
}

static simulated function bool FillRequiresLOSToTargetLocation( ) { return true; }

static simulated function int GetTileDataNumTurns() 
{ 
	return default.Duration; 
}

defaultproperties
{
	bCenterTile = true;
}