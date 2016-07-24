//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComSpawnPoint extends XComSpawnPointNativeBase
	placeable;

var() EUnitType             UnitType;
var   XComBuildingVolume    m_kVolume;
var   bool                  m_bInside;
var   bool                  m_bInit;

// NOTE: this has to be manually set by the spawner code. it is not automatically set by this spawn point -tsmith
var   Actor                 m_kLastActorSpawned; 

simulated event EUnitType GetUnitType()
{
	return UnitType;
}


//------------------------------------------------------------------------------------------------
function bool IsInside()
{
	local XComBuildingVolume kVolume;
	if (m_bInit)
	{
		return m_bInside;
	}
	foreach WorldInfo.AllActors(class 'XComBuildingVolume', kVolume )
	{
		if( kVolume != none && kVolume.IsInside )   // Hack to eliminate tree break
		{
			if (kVolume.Encompasses(self))
			{
				m_kVolume = kVolume;
				m_bInside = true;
				m_bInit = true;
				return m_bInside;
			}
		}
	}
	m_bInit = true;
	return false;
}
//------------------------------------------------------------------------------------------------
// SpawnPoint function override, shorter trace distance and offset by a half-meter.
simulated function bool SnapToGround( optional float Distance = 128.0f )
{
	local vector HitLocation, HitNormal;

	if ( Trace( HitLocation, HitNormal, Location + vect(0,0,-1) * Distance, Location, false ) != none )
	{
		SetLocation( HitLocation + vect(0,0,32) );

		return true;
	}

	return false;
}

//------------------------------------------------------------------------------------------------
function Init()
{
	m_bInside = IsInside();
}
//------------------------------------------------------------------------------------------------

function Vector GetSpawnPointLocation()
{
	return Location;
}

defaultproperties
{
	UnitType=UNIT_TYPE_Soldier

	Begin Object Class=ArrowComponent Name=Arrow
		ArrowColor=(R=150,G=200,B=255)
		ArrowSize=0.5
		bTreatAsASprite=True
		HiddenGame=true
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
	End Object
	Components.Add(Arrow)

	bMovable=false

	// original.
	bStatic=false
	bTickIsDisabled=true
	bNoDelete=FALSE

	// navpoint
	bHidden=FALSE

	bCollideWhenPlacing=true
	bCollideActors=false
}
