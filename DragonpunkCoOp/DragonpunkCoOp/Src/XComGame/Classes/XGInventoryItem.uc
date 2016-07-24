class XGInventoryItem extends XGItem
	native(Core);

// Instance Variables
var	ELocation 			        m_eSlot;    		    // Slot that this item is loaded into
var	ELocation                   m_eReservedSlot;	    // Slot that this item must be unequipped to
var XGUnit						m_kOwner;			    // Unit that owns this item
var MeshComponent               m_kMeshComponent;       // graphical component
var Actor						m_kEntity;	            // graphical entity;
var bool                        m_bSpawnEntity;

var ELocation m_eEquipLocation; // The location this item goes when equipped (normally Right Hand)
var ELocation m_eReserveLocation; // The location this item reserves when we're adding it directly to equipped location.


simulated function Init(optional XComGameState_Item ItemState=none)
{
}

simulated event PreBeginPlay()
{
	// jbouscher:  since items are now created from templates, there's additional leg work that has to happen after PreBeginPlay before we are ready to create the entity

	//if( m_bSpawnEntity && m_kEntity == none && !`ONLINEEVENTMGR.bPerformingStandardLoad ) //Defer spawning the weapon until the resources are ready ( when loading )
	//	m_kEntity = CreateEntity();
}

simulated event Actor CreateEntity(optional XComGameState_Item ItemState)
{
	return none;
}

simulated function AttachEntityMesh(Actor kEntity);

simulated function bool IsGrenade()
{
	local XComGameState_Item ItemState;
	local X2WeaponTemplate WeaponTemplate;
	
	ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));
	WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());
	if (WeaponTemplate != none)
	{
		return WeaponTemplate.WeaponCat == 'grenade';
	}

	return false;
}

// NOTE: removed replication of slot, owner, size, etc as they are set via simulated functions.
// the reason for this was there were cases when the server would replicate the variable before the 
// client accessed the old, yet correct for the time, value and the client would get out of wack.
// if we need to replicate properties here we should look into doing it via the yet un-implemented bNetNewTurn condition. -tsmith 

defaultproperties
{
 	m_eEquipLocation=eSlot_RightHand
	m_eReserveLocation=eSlot_RightBack
	m_bSpawnEntity=true
}
