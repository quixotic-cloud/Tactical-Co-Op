//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XGLevelNativeBase extends Actor 
	native(Level);

var array<XComBuildingVolume>     m_arrBuildings;

// Frac actors which have been damaged and need to update are added to this list. They are then removed
// then their update has completed ( may be several frames later )
var protected init array<XComFracLevelActor> m_arrUpdateFracActorsList;

// Destructible actors which have been damaged and need to update are added to this list. They are then removed
// then their update has completed ( may be several frames later )
var protected init array<XComDestructibleActor> m_arrUpdateDestructibleActorsList;

cpptext 
{
	const TArray<AXComBuildingVolume*>& GetBuildings() const { return m_arrBuildings;  }	
}

native protected function bool IsStreamingComplete();

native final function InitFractureSystems();

