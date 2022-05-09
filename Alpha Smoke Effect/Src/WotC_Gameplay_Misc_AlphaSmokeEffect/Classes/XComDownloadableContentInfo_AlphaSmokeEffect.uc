//---------------------------------------------------------------------------------------
//  FILE:   XComDownloadableContentInfo_*.uc                                    
//           
//	Use the X2DownloadableContentInfo class to specify unique mod behavior when the 
//  player creates a new campaign or loads a saved game.
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class XComDownloadableContentInfo_AlphaSmokeEffect extends X2DownloadableContentInfo config (DLC_AlphaSmoke);

struct CustomSmokeData
{
	var name TemplateName;
	var string CustomFillVFXPath;
	var bool UseMk2Stats;
};

var config array<CustomSmokeData> OverrideSmokeGrenadeItem;
var config int			AlphaSmoke_HitMod;
var config int			AlphaSmoke_AimMod;
var config bool			AlphaSmoke_AimBonusAffectsMelee;

var config int			AlphaSmokeMk2_HitMod;
var config int			AlphaSmokeMk2_AimMod;
var config bool			AlphaSmokeMk2_AimBonusAffectsMelee;

var localized string	AlphaSmoke_EffectDisplayName;
var localized string	AlphaSmoke_EffectDisplayDesc;

var localized string	AlphaSmokeMk2_EffectDisplayName;
var localized string	AlphaSmokeMk2_EffectDisplayDesc;

var config bool			bLog;

var config bool			bEnableTileVisualization;

var config array<name>	AbilitiesDisabledWhileInSmoke;
var config array<name>	EffectsToCleanse;

var localized string	Item_SmokeGrenade_FriendlyName;
var localized string	Item_SmokeGrenade_BriefSummary;
var localized string	Item_SmokeGrenade_TacticalText;
var localized string	Item_SmokeGrenade_ThrownAbilityHelpText;
var localized string	Item_SmokeGrenade_LaunchedAbilityHelpText;

var localized string	Item_SmokeGrenadeMk2_FriendlyName;
var localized string	Item_SmokeGrenadeMk2_BriefSummary;
var localized string	Item_SmokeGrenadeMk2_TacticalText;
var localized string	Item_SmokeGrenadeMk2_ThrownAbilityHelpText;
var localized string	Item_SmokeGrenadeMk2_LaunchedAbilityHelpText;

//Markup stuff
static function bool AbilityTagExpandHandler(string InString, out string OutString)
{
	local name Type;

	Type = name(InString);

	switch(Type)
	{
		case 'ALPHASMOKE_Mk1_HITMOD':
			OutString = LocSetSign(default.AlphaSmoke_HitMod);
			return true;
		case 'ALPHASMOKE_Mk1_AIMMOD':
			OutString = LocSetSign(default.AlphaSmoke_AimMod);
			return true;
		case 'ALPHASMOKE_Mk2_HITMOD':
			OutString = LocSetSign(default.AlphaSmokeMk2_HitMod);
			return true;
		case 'ALPHASMOKE_Mk2_AIMMOD':
			OutString = LocSetSign(default.AlphaSmokeMk2_AimMod);
			return true;
	}
	return false;
}

static function string LocSetSign(int Value)
{
	local string str;

	if (Value > 0)
		str = "+" $ Value;
	else 
		str = "" $ Value;

	return str;
}

/// <summary>
/// This method is run if the player loads a saved game that was created prior to this DLC / Mod being installed, and allows the 
/// DLC / Mod to perform custom processing in response. This will only be called once the first time a player loads a save that was
/// create without the content installed. Subsequent saves will record that the content was installed.
/// </summary>
static event OnLoadedSavedGame()
{

}

/// <summary>
/// Called when the player starts a new campaign while this DLC / Mod is installed
/// </summary>
static event InstallNewCampaign(XComGameState StartState)
{

}

//
// On post templates event that allows you to make changes to templates
//
static event OnPostTemplatesCreated()
{
	local X2AbilityTemplateManager	AbilityMgr;
	local name						AbilityName;
	local array<X2AbilityTemplate>	AbilityTemplates;
	local X2AbilityTemplate			AbilityTemplate;
	local X2Condition				Condition;
	local X2Condition_UnitEffects	UnitEffectCondition;
	local bool						bEffectFound;

	ApplyCustomSmokeEffectToItems();

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	// Apply EffectExclusions to the following abilities
	foreach default.AbilitiesDisabledWhileInSmoke(AbilityName)
	{
		AbilityMgr.FindAbilityTemplateAllDifficulties(AbilityName, AbilityTemplates);
		
		foreach AbilityTemplates(AbilityTemplate)
		{
            `LOG("[" $ default.class $ "::" $ GetFuncName() $ "()] Modifying Ability: " $ AbilityTemplate.DataName, true, 'WotC_Gameplay_Misc_AlphaSmokeEffect');

			bEffectFound = false;

			foreach AbilityTemplate.AbilityShooterConditions(Condition)
			{
				UnitEffectCondition = X2Condition_UnitEffects(Condition);

				// Only the first one is valid
				if ( UnitEffectCondition != none )
				{
					UnitEffectCondition.AddExcludeEffect(class'X2Effect_AlphaSmoke'.default.EffectName, 'AA_AbilityUnavailable');
					bEffectFound = true;
					break;
				}
			}

			if (!bEffectFound)
			{
				UnitEffectCondition = new class'X2Condition_UnitEffects';
				UnitEffectCondition.AddExcludeEffect(class'X2Effect_AlphaSmoke'.default.EffectName, 'AA_AbilityUnavailable');
				AbilityTemplate.AbilityShooterConditions.AddItem(UnitEffectCondition);
			}
		}
	}
}

//
// Given a set of weapon templates, removes the templates from being shown in the game.
//
static function ApplyCustomSmokeEffectToItems()
{
	local X2ItemTemplateManager TemplateManager;
	local X2GrenadeTemplate GrenadeTemplate;
	local array<X2DataTemplate> DataTemplates;
	local X2Effect SmokeEffectTemplate;
	local CustomSmokeData SmokeData;
	local int idx;

	TemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	foreach default.OverrideSmokeGrenadeItem(SmokeData)
	{
		TemplateManager.FindDataTemplateAllDifficulties(SmokeData.TemplateName, DataTemplates);
		for (idx = 0; idx < DataTemplates.Length; ++idx)
		{	
			GrenadeTemplate = X2GrenadeTemplate(DataTemplates[idx]);
			if (GrenadeTemplate != none)
			{
				//Reset ThrownGrenadeEffects
				GrenadeTemplate.ThrownGrenadeEffects.Length = 0;

				// Create the effect template
				if (SmokeData.UseMk2Stats)
				{
					GrenadeTemplate.ThrownGrenadeEffects.AddItem(AlphaSmokeEffectMk2());
					GrenadeTemplate.ThrownGrenadeEffects.AddItem(AlphaSmokeWorldEffect(true, SmokeData.CustomFillVFXPath));
				}
				else
				{
					GrenadeTemplate.ThrownGrenadeEffects.AddItem(AlphaSmokeEffectMk1());
					GrenadeTemplate.ThrownGrenadeEffects.AddItem(AlphaSmokeWorldEffect(false, SmokeData.CustomFillVFXPath));
				}

				//Copy Effects to Launched Grenade
				GrenadeTemplate.LaunchedGrenadeEffects = GrenadeTemplate.ThrownGrenadeEffects;

				switch(GrenadeTemplate.DataName)
				{
					case 'SmokeGrenade':
						GrenadeTemplate.FriendlyName				= default.Item_SmokeGrenade_FriendlyName;
						GrenadeTemplate.BriefSummary				= default.Item_SmokeGrenade_BriefSummary;
						GrenadeTemplate.TacticalText				= default.Item_SmokeGrenade_TacticalText;
						GrenadeTemplate.ThrownAbilityHelpText		= default.Item_SmokeGrenade_ThrownAbilityHelpText;
						GrenadeTemplate.LaunchedAbilityHelpText		= default.Item_SmokeGrenade_LaunchedAbilityHelpText;

						GrenadeTemplate.GameArchetype = "WP_Grenade_Smoke_White.WP_Grenade_Smoke";
						break;
					case 'SmokeGrenadeMk2':
						GrenadeTemplate.FriendlyName				= default.Item_SmokeGrenadeMk2_FriendlyName;
						GrenadeTemplate.BriefSummary				= default.Item_SmokeGrenadeMk2_BriefSummary;
						GrenadeTemplate.TacticalText				= default.Item_SmokeGrenadeMk2_TacticalText;
						GrenadeTemplate.ThrownAbilityHelpText		= default.Item_SmokeGrenadeMk2_ThrownAbilityHelpText;
						GrenadeTemplate.LaunchedAbilityHelpText		= default.Item_SmokeGrenadeMk2_LaunchedAbilityHelpText;

						GrenadeTemplate.GameArchetype = "WP_Grenade_Smoke_White.WP_Grenade_Smoke_Lv2";
						break;
					default:
						break;
				}

				`LOG("Replaced " $ SmokeData.TemplateName $ "'s Smoke effect... SUCCESS!", default.bLog, 'WotC_Gameplay_Misc_AlphaSmokeEffect');
			}
		}
	}
}

// Required for X2Effect_ApplyAlphaSmokeToWorld
static function X2Effect AlphaSmokeEffectMk1()
{
	return AlphaSmokeEffect(default.AlphaSmoke_HitMod, default.AlphaSmoke_AimMod, default.AlphaSmoke_AimBonusAffectsMelee, default.AlphaSmoke_EffectDisplayName, default.AlphaSmoke_EffectDisplayDesc);
}

static function X2Effect AlphaSmokeEffectMk2()
{
	return AlphaSmokeEffect(default.AlphaSmokeMk2_HitMod, default.AlphaSmokeMk2_AimMod, default.AlphaSmokeMk2_AimBonusAffectsMelee, default.AlphaSmokeMk2_EffectDisplayName, default.AlphaSmokeMk2_EffectDisplayDesc);
}

static function X2Effect AlphaSmokeEffect(int HitMod, int AimMod, bool bAffectsMelee, string LocDisplayName, string LocDesc)
{
	local X2Effect_AlphaSmoke Effect;

	Effect = new class'X2Effect_AlphaSmoke';
	//Must be at least as long as the duration of the smoke effect on the tiles. Will get "cut short" when the tile stops smoking or the unit moves. -btopp 2015-08-05
	Effect.BuildPersistentEffect(class'X2Effect_ApplyAlphaSmokeToWorld'.default.Duration + 1, false, false, false, eGameRule_PlayerTurnBegin);
	Effect.SetDisplayInfo(ePerkBuff_Bonus, LocDisplayName, LocDesc, "img:///UILibrary_PerkIcons.UIPerk_grenade_smoke");
	Effect.HitMod = HitMod;
	Effect.AimBonus = AimMod;
	Effect.bAimBonusAffectsMelee = bAffectsMelee;
	Effect.EffectsToRemove = default.EffectsToCleanse;
	return Effect;
}

static function X2Effect AlphaSmokeWorldEffect(bool bUseMk2, string CustomFillVFXPath)
{
	local X2Effect_ApplyAlphaSmokeToWorld Effect;

	Effect = new class'X2Effect_ApplyAlphaSmokeToWorld';
	Effect.SmokeParticleSystemFill_Path = CustomFillVFXPath;
	Effect.bUseMk2Smoke					= bUseMk2;

	return Effect;
}

