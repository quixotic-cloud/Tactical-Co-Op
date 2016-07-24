class SeqAct_ForceLOD extends SequenceAction;

var Actor   TargetActor;
var() Name Tag;               // Apply to all actors with this tag, only if TargetActor == none

var() int iLOD;

event Activated()
{
	local Actor curActor;
	local StaticMeshComponent StaticMeshComp;
	local SkeletalMeshComponent SkeletalMeshComp;

	if (TargetActor != none)
	{
		foreach TargetActor.ComponentList( class'StaticMeshComponent', StaticMeshComp )
		{
			StaticMeshComp.ForcedLodModel = iLOD;
			
			if( StaticMeshComp.Owner != none )
			{
				StaticMeshComp.Owner.ReattachComponent( StaticMeshComp );
			}
		}

		foreach TargetActor.ComponentList( class'SkeletalMeshComponent', SkeletalMeshComp )
		{
			SkeletalMeshComp.ForcedLodModel = iLOD;

			if( SkeletalMeshComp.Owner != none )
			{
				SkeletalMeshComp.Owner.ReattachComponent( SkeletalMeshComp );
			}
		}
	}
	else
	{
		foreach class'Engine'.static.GetCurrentWorldInfo().AllActors(class'Actor', curActor)
		{
			if (curActor.Tag == Tag)
			{
				foreach curActor.ComponentList( class'StaticMeshComponent', StaticMeshComp )
				{
					StaticMeshComp.ForcedLodModel = iLOD;

					if( StaticMeshComp.Owner != none )
					{
						StaticMeshComp.Owner.ReattachComponent( StaticMeshComp );
					}
				}

				foreach curActor.ComponentList( class'SkeletalMeshComponent', SkeletalMeshComp )
				{
					SkeletalMeshComp.ForcedLodModel = iLOD;

					if( SkeletalMeshComp.Owner != none )
					{
						SkeletalMeshComp.Owner.ReattachComponent( SkeletalMeshComp );
					}
				}
			}
		}
	}
}

defaultproperties
{
	ObjCategory="Level"
	ObjName="Force LOD"
	bCallHandler=false

	VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="Target Actor",PropertyName=TargetActor)

}
