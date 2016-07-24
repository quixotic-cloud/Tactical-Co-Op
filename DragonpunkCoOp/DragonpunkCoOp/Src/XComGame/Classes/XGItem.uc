//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XGItem extends Actor
    dependson(XGGameData)
	abstract 
	native(Core);

var protected EItemType				m_eType;            // Animation specific type.
//var protected EItemType             m_eGameplayType;    // Gameplay override type.
var protected string				m_strUIImage;       // Final UI icon image of the object
var bool                            m_bDamaged;         // Is this item damaged?

//=======================================================================================
//X-Com 2 Refactoring
//
//Member variables go in here, everything else will be re-evaluated to see whether it 
//needs to be moved, kept, or removed.

var transient privatewrite int ObjectID;                  //Unique identifier for this object - used for network serialization and game state searches

//=======================================================================================


simulated static function EItemType ItemType()
{
	return default.m_eType;
}

/*
 *  Convert Alien Weapon GameplayType to base GameplayType
 */
native simulated static function EItemType GameplayType();

simulated static function string ItemUIImage()
{
	return default.m_strUIImage;
}

//=======================================================================================
//X-Com 2 Refactoring
//
//RAM - most everything in here is temporary until we can kill off all the of XG<classname>
//      types. Eventually the XComGameState_<classname> objects will replace them entirely
//

simulated static function XGItem CreateVisualizer(XComGameState_Item ItemState, bool bSetAsVisualizer=true, optional XComUnitPawn UnitPawnOverride = None)
{
	local class<XGItem> ItemClass;
	local XGItem CreatedItem;
	local XGWeapon CreatedWeapon;

	ItemClass = ItemState.GetMyTemplate().GetGameplayInstanceClass();

	if( ItemClass != none ) //Not every item has a visualizer - armor, for example, does not
	{
		CreatedItem = class'Engine'.static.GetCurrentWorldInfo().Spawn( ItemClass, `BATTLE  );
		CreatedItem.ObjectID = ItemState.ObjectID;
		CreatedWeapon = XGWeapon(CreatedItem);
		if( CreatedWeapon != none )
		{
			//UnitPawnOverride is used when making cosmetic soldiers for the UI (main menu, armory).
			//The owner's pawn won't actually be accessible through the history when the weapon is initialized - set it here.
			if (UnitPawnOverride != None)
				CreatedWeapon.UnitPawn = UnitPawnOverride;

			CreatedWeapon.Init(ItemState);
		}

		if(bSetAsVisualizer)
		{
			`XCOMHISTORY.SetVisualizer(ItemState.ObjectID, CreatedItem);
		}

		return CreatedItem;
	}

	return none;
}
//=======================================================================================

simulated function bool IsInitialReplicationComplete()
{
	return true;
}

replication
{

}

defaultproperties
{
//	m_eGameplayType = eItem_NONE

	bTickIsDisabled=true
	//bAlwaysRelevant = true;
	//RemoteRole = Role_SimulatedProxy;
	bAlwaysRelevant=false
	RemoteRole=ROLE_None
}
