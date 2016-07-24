/** XComFloorComponent 
 *  Overhauled 10/19/2012 - Jeremy Shopf
 *  
 *  The purpose of this component is to control transitions between a level actor's various visibility states. It
 *      effectively acts as a wrapper around level/frac level actors..
 *      
 *   The floor component only ticks when a transition for it's owner's primtivies is in progress. Note that the actual
 *      setting of the fade values are set by the renderthread in UpdatePrimitiveCutoutFade(). The floor component's job 
 *      is to make sure the state of the primitive (bCutoutMask, etc.) doesn't change until the fade is finished. */

class XComFloorComponent extends ActorComponent
	hidecategories(Object)
	native(Level);

/** Whether the actor should be cutdown when it is finished fading. */
var native transient bool bCutdown;
/** Whether the actor should be cutout when it is finished fading. */
var native transient bool bCutout;
/** Whether the actor should hidden when it is done fading. */
var native transient bool bHidden;
/** Whether the actor should "toggle hidden" when it is done fading. This means it renders to the Occluded render
 *     channel but not to the Main render channel. */
var native transient bool bToggleHidden;

/** Will be true inside of any frame in which the cutout flag is changed. */
var native transient bool bCutoutStateChanged;
var native transient bool bCutdownStateChanged;
var native transient bool bHeightStateChanged;
var native transient bool bHiddenStateChanged;
var native transient bool bToggleHiddenStateChanged;
var native transient bool bVisStateChanged;

/** Cached target fade value */
var native transient float fTargetFade;

/** Cached target opacity mask heights. The previous opacity mask height is the cutout or cutdown height when the current transition
 *  began. The opacity mask height is last cutdown or cutout height set during the transition.  */
var native float fTargetOpacityMaskHeight;

var native float fTargetCutoutMaskHeight;
var native float fTargetCutdownMaskHeight;

/** Whether a cutout transition is currently occuring. */
var transient bool bFadeTransition;
/** Whether the last trigger transition was a fade out, or not. */
var transient bool bCurrentFadeOut;

var native transient bool bComponentNeedsTick;

/* If true, don't allow the component to be cutout from cutout boxes or vis traces. */
var transient bool bIsCutoutFromExternalMeshGroup;

/** The owner actor is transitioning to/from a cutdown state. 
 *  Note that the target height is set direction on the primitive by ::ChangeVisibility*() **/
native simulated function SetTargetCutdown( bool bInCutdown );

/** The owner actor is transitioning to/from a cutout state. **/
native simulated function SetTargetCutout( bool bInCutout );

/** The owner actor is transition to a hidden state. **/
native simulated function SetTargetHidden( bool bInHidden );

native simulated function SetIsHidingFromExternalMeshGroup(bool bIsHidingFromExternalMeshGroup);
native simulated function bool IsHidingFromExternalMeshGroup();

/** The owner actor is transition to a "toggle hidden" state. **/
native simulated function SetTargetToggleHidden( bool bInToggleHidden );

/** Cache cutdown/cutout heights. */
native simulated function SetTargetVisHeights( float fInTargetCutdownHeight, float fInTargetCutoutHeight );
native simulated function GetTargetVisHeights( out float fOutTargetCutdownHeight, out float fOuttargetCutoutHeight );

native simulated private function PreTransition();

//native simulated private function PostTransition();

/** Perform actions when a cutout transition is requested. **/
native simulated private function OnBeginFadeTransition( bool bFadeOut, bool bResetFade, out float fCutoutFade, out float fTargetCutoutFade );

/** Perform actions when we've finished our transition to the cutout state **/
native simulated private function OnFinishedFadeTransition( float fCutdownHeight, float fCutoutHeight );

native simulated private function StopTransition();

cpptext
{
	virtual void PostLoad();
	virtual void Tick(FLOAT DeltaTime);
	virtual UBOOL InStasis();
}

defaultproperties
{
	bCutout=false
	bCutdown=false
	bHidden=false
	bToggleHidden=false
	bFadeTransition=false
	bCurrentFadeOut=true // initialize this to true because the first transition will be out
	bComponentNeedsTick=false

	bIsCutoutFromExternalMeshGroup=false

	fTargetOpacityMaskHeight=999999.0
	fTargetCutoutMaskHeight=999999.0
	fTargetCutdownMaskHeight=999999.0

	TickGroup=TG_PostAsyncWork
}
