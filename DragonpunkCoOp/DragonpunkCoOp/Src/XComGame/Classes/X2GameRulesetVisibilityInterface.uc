interface X2GameRulesetVisibilityInterface native(Core);

enum EForceVisibilitySetting
{
	eForceNone,
	eForceVisible,
	eForceNotVisible
};

/// <summary>
/// Used to determine whether a target is in range or not
/// </summary>
event float GetVisibilityRadius();

/// <summary>
//Apply state object specific logic to the visibility info describing the relationship between a source and a target. In order for this function to run, a state object must
//set bRequiresVisibilityUpdate set to TRUE in any state object that is submitted with changes that this function would pick up. While running 'UpdateGameplayVisibility' all
//the time to pick up any possible changes would be safer, it is not practical for performance reasons.
//
//Example use: 
//Units might check to see whether the target is affected by stealth. If the target was hidden by stealth, they would set InOutVisibilityInfo.bVisibleGameplay to FALSE and 
//then add an item: 'Stealth' to the bVisibleGameplayContext list.
/// </summary>
event UpdateGameplayVisibility(out GameRulesCache_VisibilityInfo InOutVisibilityInfo);

/// <summary>
/// Applies to queries that need to know whether a given target is an 'enemy' of the source
/// </summary>
event bool TargetIsEnemy(int TargetObjectID, int HistoryIndex = -1);

/// <summary>
/// Applies to queries that need to know whether a given target is an 'ally' of the source
/// </summary>
event bool TargetIsAlly(int TargetObjectID, int HistoryIndex = -1);

/// <summary>
/// Returns the ObjectID of the player controlling / associated with this visibility viewer
/// </summary>
event int GetAssociatedPlayerID();

/// <summary>
/// Used to supply a tile location set to the visibility system to use for visibility checks
/// </summary>
function GetVisibilityLocation(out array<TTile> VisibilityLocation);

function GetKeystoneVisibilityLocation(out TTile VisibilityLocation);

/// <summary>
/// Used to supply a the visible extents of this state object visibility location
/// </summary>
event GetVisibilityExtents(out Box VisibilityExtents);

/// <summary>
/// Used by the visibility system to manipulate this state object's VisibilityLocation while analyzing game state changes
/// </summary>
event SetVisibilityLocation(const out TTile VisibilityLocation);

/// <summary>
/// Returns whether the visibility of this entity should be forced
/// </summary>
event EForceVisibilitySetting ForceModelVisible();

/// <summary>
/// Returns TRUE if the object should act as if in high cover even when in functional low cover
/// </summary>
event bool ShouldTreatLowCoverAsHighCover();

cpptext
{
	// True if this object requires visibility updates as a Source object (ie. this object can see other objects)
	virtual UBOOL CanEverSee() const
	{
		return FALSE;
	}

	// True if this object can be included in another viewer's visibility updates (ie. this object can be seen by other objects)
	virtual UBOOL CanEverBeSeen() const
	{
		return FALSE;
	}

	virtual void NativeGetVisibilityLocation(TArray<struct FTTile>& VisibilityTiles) const = 0;
	virtual void NativeGetKeystoneVisibilityLocation(struct FTTile& VisibilityTile) const = 0;
};