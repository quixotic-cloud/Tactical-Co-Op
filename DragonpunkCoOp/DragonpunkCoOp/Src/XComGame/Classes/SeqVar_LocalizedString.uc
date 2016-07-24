class SeqVar_LocalizedString extends SeqVar_String
	native(Level);

cpptext
{
	virtual FString* GetRef()
	{
		eventLocalizeString();
		return &StrValue;
	}

	FString GetValueStr()
	{
		eventLocalizeString();
		return StrValue;
	}

	virtual void PublishValue(USequenceOp *Op, UProperty *Property, FSeqVarLink &VarLink);
	virtual void PopulateValue(USequenceOp *Op, UProperty *Property, FSeqVarLink &VarLink);
}

var() string strLookup; // localized key of the form "Package.Section.Name" 


event LocalizeString()
{
	StrValue = ParseLocalizedPropertyPath(strLookup);
}

defaultproperties
{
	ObjName="Localized String"
	ObjColor=(R=0,G=128,B=0,A=255)			// dark green
}