class XComAnimTreeController extends Object
	native(Animation)
	config(Animation);

// Anim Nodes
var private AnimTree						TreeNode;
var private SkeletalMeshComponent			SkelComp;
var private AnimNode_MultiBlendPerBone      OpenCloseStateNode;
var private AnimNodeBlendPerBone            FlyingLegMaskNode;
var	private AnimNodeBlendList			    CrouchNode;
var private XComAnimNodeJetpack			    JetPackNode;
var private AnimNodeAdditiveBlending        GenderBlender;
var private XComAnimNodeBlendMasks          BlendChannelsNode;
var private XComAnimNodeBlendDynamic        FullBodyDynamicNode;
var private XComAnimNodeBlendDynamic        UpperBodyDynamicNode;
var private XComAnimNodeBlendDynamic		AdditiveDynamicNode;
var private AnimNodeBlendList				HeadToggle;
var private AnimNodeBlendList				HeadNode;
var private AnimNodeBlendPerBone			HeadPerBone;
var private AnimNodeAimOffset				StandingAimOffsetNode;
var private SkelControlLookAt				HeadLookAt;
var private AnimNodeAimOffset				HeadEyesAimNode;
var private AnimNodeAimOffset				HeadAimNode;
var private AnimNodeAimOffset				EyesAimNode;
var private AnimNodeAimOffset				EyelidsAimNode;

// General 
var private bool AllowNewAnimations;
var private init array<XComAnimTreeController> ChildControllers; // Animations will be played on itself and its children

// Debugging
var private array<String>	ArrLastPlayedAnims;
var private int				LastPlayedAnimCounter;

// Config
var public config float AimDifferenceTriggersBlend;
var public config float StepOutAngleThreshold;
var public config float DistanceNeededForMovingMelee;
var public config float RaiseWeaponHeightCheck;

// All Nodes
native function InitializeNodes(SkeletalMeshComponent SkelMeshComp);
native function DrawDebugLabels(Canvas kCanvas, out Vector vScreenPos);
native function DebugAnims(Canvas kCanvas, bool DisplayHistory, XComIdleAnimationStateMachine IdleStateMachine, out Vector vScreenPos);
native function float ComputeAnimationRMADistance(Name AnimName);
native function bool CanPlayAnimation(Name AnimName, optional bool SearchAnimName = true);
native function SetAllowNewAnimations(bool Allow);
native function bool GetAllowNewAnimations();
native function DisplayRelevantAnimNodes(AnimNode NodeToTraverse, float Weight, Canvas kCanvas, out Array<AnimNodeSequence> AlreadyDisplayedSequences, out Array<AnimNodeBlendBase> AlreadyDisplayedParents, out Vector vScreenPos);

// OpenCloseStateNode
native function bool IsOpenClosedStateClosed();
native function bool UpdateOpenCloseStateNode(EUnitPawn_OpenCloseState eDesiredState, optional bool bImmediate = false);

// FlyingLegMaskNode
native function EnableFlying(float BlendTime);
native function DisableFlying(float BlendTime);

// JetPackNode
native function SetJetPackNodeActiveChild(int ChildIndex, float BlendTime);

// GenderBlender
native function SetGenderBlenderBlendTarget(float BlendTarget, float BlendTime);

// DynamicNode
native function AnimNodeSequence PlayFullBodyDynamicAnim(out CustomAnimParams Params);
native function AnimNodeSequence PlayUpperBodyDynamicAnim(out CustomAnimParams Params);
native function AnimNodeSequence PlayAdditiveDynamicAnim(out CustomAnimParams Params);
native function RemoveAdditiveDynamicAnim(out CustomAnimParams Params);
native function bool RemoveAdditiveDynamicAnimBySequence(AnimNodeSequence PlayingSequence, float BlendTime);
native function BlendOutAdditiveDynamicNode(float BlendTime);
native function AnimNodeSequence TurnToTarget(const out Vector Target, optional bool TurnAwayFromCover = false);
native function int GetNumProjectileVolleys();
native function GetFireWeaponVolleyNotifies(out array<AnimNotify_FireWeaponVolley> OutNotifies, out array<float> OutNotifyTimes);
native function float GetFirstCustomFireNotifyTime(Name AnimName);
native function AnimNodeSequence DeathOnLoad(bool WillRagdoll, const out CustomAnimParams Params);
native function GetDesiredEndingAtomFromStartingAtom(out CustomAnimParams Params, const out BoneAtom DesiredStartingAtom);
native function AttachChildController(XComAnimTreeController ChildController);
native function DetachChildController(XComAnimTreeController ChildController);
native function float GetCurrentAnimationTime();
native function bool IsPlayingCurrentAnimation(Name AnimName);
native function RootMotionProcessed();

// samples the root bone at the specified time, and returns it either as an offset from the start of the animation (the default),
// or relative to some other time in the animation
native function bool GetRootAtom(AnimSequence AnimSeq, float AnimTime, out BoneAtom RootAtom, optional float RelativeToTime = -1.0f);

// StandingAimOffsetNode
native function SetStandingAimOffsetNodeProfile(Name Profile);
native function Name GetStandingAimOffsetNodeProfile();

// HeadNode - unique heads are created with additive blends from a ref head
native function SetHeadAnim(Name HeadAnim);

// HeadLookAt
native function SetHeadLookAtWeight(float Weight, float BlendTime);
native function SetHeadLookAtTarget(Vector TargetLocation);

cpptext
{
public:
	void SetActiveChild(UAnimNodeBlendList* Anim, INT ChildIndex, FLOAT BlendTime);
private:
	void SetAnim(UAnimNodeSequence* Anim, FName AnimName);
	void SetBlendTarget(UAnimNodeBlend* BlendNode, FLOAT BlendTarget, FLOAT BlendTime);
	void SetActiveProfileByName(UAnimNodeAimOffset* AnimAimOffset, FName Profile);
};

defaultproperties
{
	AllowNewAnimations = true;
}