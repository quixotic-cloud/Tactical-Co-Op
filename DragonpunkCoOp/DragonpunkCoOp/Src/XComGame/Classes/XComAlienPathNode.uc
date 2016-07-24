//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComAlienPathNode.uc    
//  AUTHOR:  Alex Cheng  --  2/08/2011
//  PURPOSE: XComAlienPathNode, container for Pod Patrol Path Nodes.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComAlienPathNode extends actor
	native(AI)
	hidecategories(Display, Attachment, Collision, Physics, Debug, Actor)
	placeable
	implements(X2SpawnNode);

enum EPathNodeType
{
	PATH_NODE_TYPE_DEFAULT<DisplayName=Standard Path Node>,
	PATH_NODE_TYPE_DOOR_OPEN_LOCATION<DisplayName=Door Node (Alien will open door from this location)>
};

enum EPathNodeScopeConfiguration
{
	EPNSC_ParcelToPlotLinkNode<DisplayName=Link Node: The nearest Plot Node within range will replace this node>,
	EPNSC_ParcelNode,
	EPNSC_PlotNode,
};

enum EPathNodeScope
{
	EPNS_Disabled,
	EPNS_ParcelNode,
	EPNS_PlotNode,
};

struct native NodeScopeConfigurationVisualization
{
	var Texture2D NodeIcon;
	var Color NodeColor;
};

var deprecated bool ValidStartLocation; // Can be used as a valid starting location for DynamicAI aliens
var deprecated EPathNodeType Type;
var deprecated XComInteractiveLevelActor InteractActor; // Door or Window object associated with this node.
var deprecated int WaitTurns; // 0=no pause, 1=pause the remainder of the turn, 2=pause remainder of turn and next turn, etc.
var deprecated bool m_bTerminal; // For forward/backward loops, designates the start and end.
var editoronly array<ArrowComponent> m_arrArrow;
var editoronly ArrowComponent m_kArrow;
var editoronly SpriteComponent m_kSprite, m_kSpriteStart;
var editoronly array<XComAlienPathNode> OldLinkedNodes; // To keep track of node removals and maintain symmetry.
var editoronly array<NodeScopeConfigurationVisualization> EditorNodeVisuals;  // editor-only visualization information per scope configuration
var() array<XComAlienPathNode> LinkedNodes;
var deprecated bool m_bIsPlotPath<DisplayName=Is Plot Path>; // Changing this value also updates all connected Node values.
var() EPathNodeScopeConfiguration ScopeConfiguration; // defines the scope of this path node
var EPathNodeScope Scope; // This path node is only available for pathing when the scope matches the requirements of the pathing unit

cpptext
{
	virtual void PreEditChange(UProperty* PropertyThatWillChange);
	virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent);
	virtual void PostEditMove(UBOOL bFinished);
	virtual void PostLoad();
	void UpdateRelatedPodArrows( UBOOL bOnLoad=FALSE );
	void PropagateScope( BYTE Scope );
	void PropagateScopeConfiguration( BYTE ScopeConfiguration );
	UBOOL IsLinkedTo( const AXComAlienPathNode* kNode ) const;

	/////////////////////////////////////
	// X2SpawnNode implementation
	virtual const FVector& GetSpawnLocation() const;
	virtual AXGAIGroup* CreateSpawnGroup() const;
}

native function GetAllConnectedNodes( out array<XComAlienPathNode> arrNodeList_out );
native function bool IsPlotPath() const;
native function bool IsEnabled() const;

defaultproperties
{
	Begin Object Class=SpriteComponent Name=Sprite
		Sprite=Texture2D'EditorResources.S_NavP'
		HiddenGame=true
		HiddenEditor=false
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
	End Object
	Components.Add(Sprite)
	m_kSprite=Sprite;
	Begin Object Class=SpriteComponent Name=Sprite2
		Sprite=Texture2D'EditorResources.S_Pickup'
		HiddenGame=true
		HiddenEditor=true
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
	End Object
	Components.Add(Sprite2)
	m_kSpriteStart=Sprite2;

	Begin Object Class=ArrowComponent Name=Arrow0
		ArrowColor=(R=255,G=228,B=0)
		ArrowSize=1
		bTreatAsASprite=True
		HiddenGame=true
		HiddenEditor=true
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
	End Object
	Begin Object Class=ArrowComponent Name=Arrow1
		ArrowColor=(R=255,G=228,B=0)
		ArrowSize=1
		bTreatAsASprite=True
		HiddenGame=true
		HiddenEditor=true
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
	End Object
	Begin Object Class=ArrowComponent Name=Arrow2
		ArrowColor=(R=255,G=228,B=0)
		ArrowSize=1
		bTreatAsASprite=True
		HiddenGame=true
		HiddenEditor=true
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
	End Object
	Begin Object Class=ArrowComponent Name=Arrow3
		ArrowColor=(R=255,G=228,B=0)
		ArrowSize=1
		bTreatAsASprite=True
		HiddenGame=true
		HiddenEditor=true
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
	End Object
	Begin Object Class=ArrowComponent Name=Arrow4
	ArrowColor=(R=255,G=228,B=0)
	ArrowSize=1
	bTreatAsASprite=True
	HiddenGame=true
	HiddenEditor=true
	AlwaysLoadOnClient=False
	AlwaysLoadOnServer=False
	End Object
	Begin Object Class=ArrowComponent Name=Arrow5
	ArrowColor=(R=255,G=228,B=0)
	ArrowSize=1
	bTreatAsASprite=True
	HiddenGame=true
	HiddenEditor=true
	AlwaysLoadOnClient=False
	AlwaysLoadOnServer=False
	End Object
	
	Components.Add(Arrow0)
	Components.Add(Arrow1)
	Components.Add(Arrow2)
	Components.Add(Arrow3)
	Components.Add(Arrow4)
	Components.Add(Arrow5)
	m_arrArrow(0)=Arrow0;
	m_arrArrow(1)=Arrow1;
	m_arrArrow(2)=Arrow2;
	m_arrArrow(3)=Arrow3;
	m_arrArrow(4)=Arrow4;
	m_arrArrow(5)=Arrow5;

	Begin Object Class=CylinderComponent Name=CollisionCylinder 
		CollisionRadius=+0050.000000
		CollisionHeight=+0050.000000
	End Object
	CollisionComponent=CollisionCylinder
	Components.Add(CollisionCylinder)

	bStatic=true
	bNoDelete=true

	bHidden=FALSE

	bCollideWhenPlacing=FALSE
	bCollideActors=false

	Type=PATH_NODE_TYPE_DEFAULT
	ValidStartLocation=true
	InteractActor=none
	bEdShouldSnap=True

	Layer=Markup
	ScopeConfiguration=EPNSC_ParcelNode

	EditorNodeVisuals(0)=(NodeIcon=Texture2D'LayerIcons.Editor.pathnode_green',NodeColor=(R=0,G=255,B=0))
	EditorNodeVisuals(1)=(NodeIcon=Texture2D'LayerIcons.Editor.pathnode_blue',NodeColor=(R=0,G=0,B=255))
	EditorNodeVisuals(2)=(NodeIcon=Texture2D'LayerIcons.Editor.pathnode_red',NodeColor=(R=255,G=0,B=0))
}