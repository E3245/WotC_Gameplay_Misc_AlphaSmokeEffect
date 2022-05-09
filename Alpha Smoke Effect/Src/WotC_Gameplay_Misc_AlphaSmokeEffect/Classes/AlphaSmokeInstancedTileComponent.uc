class AlphaSmokeInstancedTileComponent extends X2TargetingMethod;

var bool bIsActive;

function CustomInit()
{
    AOEMeshActor = `XWORLDINFO.Spawn(class'AlphaSmokeInstancedTileActor');
}

function SetMesh(StaticMesh Mesh)
{
    AOEMeshActor.InstancedMeshComponent.SetStaticMesh(Mesh);
}

// X2TargetingMethod requires that Ability is set. Do it with this function.
function SetMockParameters(XComGameState_Ability AbilityState)
{
	Ability = AbilityState;
}

function SetTiles(const out array<TTile> Tiles)
{
    DrawAOETiles(Tiles);

	bIsActive = true;
}

function ToggleActive(bool bSetActive)
{
	bIsActive = bSetActive;
}

function Dispose()
{
    AOEMeshActor.Destroy();
}

function SetVisible(bool Visible)
{
	AOEMeshActor.SetVisible(Visible);
}