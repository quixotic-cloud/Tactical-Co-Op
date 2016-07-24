class XGParamTag extends XGLocalizeTag native(Core);

var int IntValue0;
var int IntValue1;
var int IntValue2;

var string StrValue0;
var string StrValue1;
var string StrValue2;

native function bool Expand(string InString, out string OutString);

DefaultProperties
{
	Tag = "XGParam"
}
