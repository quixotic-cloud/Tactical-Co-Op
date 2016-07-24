//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMCController.uc
//  AUTHOR:  Samuel Batista
//  PURPOSE: Provides a low level API to communicate with Flash Panel.MovieClips
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIMCController extends Object
	native(UI);

const INDEX_MASK		= 0x000FFFFF; // WARNING: we can never have more than 1048575 panels in existence
const OP_MASK		    = 0x00F00000;
const FIELD_OP			= 0x00A00000;
const FUNCTION_OP		= 0x00B00000;
const CHILD_FIELD_OP	= 0x00C00000;
const CHILD_FUNCTION_OP	= 0x00D00000;
const CLEANUP_OP    	= 0x00E00000;

var UIPanel Panel;

// necessary for fast access to this Panel in actionscript - obtained in LoadControl()
var int CacheIndex;

// array of commands to be executed when this Panel is initialized
var Array<ASValue> CommandQueue;

simulated function InitController(UIPanel InitPanel)
{
	Panel = InitPanel;
	CacheIndex = Panel.Movie.CachePanel(Panel);
}

//==============================================================================
//		LOW LEVEL ACTIONSCRIPT API
//==============================================================================

// NOTE: Operations on controlled MCs are batched and use index based caching for rapid MC access.

// Function Accessors
simulated function FunctionVoid(string Func)
{
	BeginOp(FUNCTION_OP);		// queue opcode
	QueueString(Func);			// queue function name
	EndOp();					// add delimiter and process command
}
simulated function FunctionBool(string Func, bool Param)
{ 
	BeginOp(FUNCTION_OP);		// queue opcode
	QueueString(Func);			// queue function name
	QueueBoolean(Param);		// add boolean Parameter
	EndOp();					// add delimiter and process command
}
simulated function FunctionNum(string Func, float Param)
{
	BeginOp(FUNCTION_OP);		// queue opcode
	QueueString(Func);			// queue function name
	QueueNumber(Param);			// add number Parameter
	EndOp();					// add delimiter and process command
}
simulated function FunctionString(string Func, string Param)
{ 
	BeginOp(FUNCTION_OP);		// queue opcode
	QueueString(Func);			// queue function name
	QueueString(Param);			// add string Parameter
	EndOp();					// add delimiter and process command
}

// Variables Setters
simulated function SetBool(string Field, bool Value)
{
	BeginOp(FIELD_OP);			// queue opcode
	QueueString(Field);			// queue Field name
	QueueBoolean(Value);		// add boolean Value
	EndOp();					// add delimiter and process command
}
simulated function SetNum(string Field, float Value)
{
	BeginOp(FIELD_OP);			// queue opcode
	QueueString(Field);			// queue Field name
	QueueNumber(Value);			// add number Value
	EndOp();					// add delimiter and process command
}
simulated function SetString(string Field, string Value)
{
	BeginOp(FIELD_OP);			// queue opcode
	QueueString(Field);			// queue Field name
	QueueString(Value);			// add string Value
	EndOp();					// add delimiter and process command
}
simulated function SetNull(string Field)
{ 
	BeginOp(FIELD_OP);			// queue opcode
	QueueString(Field);			// queue Field name
	QueueNull();				// add null Value
	EndOp();					// add delimiter and process command
}

// WARNING: Child operations are considerably slower than operating directly on controlled MC (requires string parsing).

// Children Function Accessors, ex:
// AS_ChildFunctionVoid("string_of_child_mc.child_of_child", "function_string");
simulated function ChildFunctionVoid(string ChildPath, string Func)
{
	BeginOp(CHILD_FUNCTION_OP); // queue opcode
	QueueString(ChildPath);		// queue path to child mc
	QueueString(Func);			// queue function name
	EndOp();					// add delimiter and process command
}
simulated function ChildFunctionBool(string ChildPath, string Func, bool Param)
{
	BeginOp(CHILD_FUNCTION_OP); // queue opcode
	QueueString(ChildPath);		// queue path to child mc
	QueueString(Func);			// queue function name
	QueueBoolean(Param);		// add boolean Parameter
	EndOp();					// add delimiter and process command
}
simulated function ChildFunctionNum(string ChildPath, string Func, float Param)
{
	BeginOp(CHILD_FUNCTION_OP); // queue opcode
	QueueString(ChildPath);		// queue path to child mc
	QueueString(Func);			// queue function name
	QueueNumber(Param);			// add number Parameter
	EndOp();					// add delimiter and process command
}
simulated function ChildFunctionString(string ChildPath, string Func, string Param)
{
	BeginOp(CHILD_FUNCTION_OP); // queue opcode
	QueueString(ChildPath);		// queue path to child mc
	QueueString(Func);			// queue function name
	QueueString(Param);			// add string Parameter
	EndOp();					// add delimiter and process command
}

// Children Variable Setters, ex:
// AS_ChildSetBool("string_of_child_mc._visible", true);
simulated function ChildSetBool(string ChildPath, string Field, bool Value)
{
	BeginOp(CHILD_FIELD_OP);    // queue opcode
	QueueString(ChildPath);		// queue path to child mc
	QueueString(Field);			// queue Field name
	QueueBoolean(Value);		// add boolean Value
	EndOp();					// add delimiter and process command
}
simulated function ChildSetNum(string ChildPath, string Field, float Value)
{
	BeginOp(CHILD_FIELD_OP);    // queue opcode
	QueueString(ChildPath);		// queue path to child mc
	QueueString(Field);			// queue Field name
	QueueNumber(Value);			// add number Value
	EndOp();					// add delimiter and process command
}
simulated function ChildSetString(string ChildPath, string Field, string Value)
{
	BeginOp(CHILD_FIELD_OP);    // queue opcode
	QueueString(ChildPath);		// queue path to child mc
	QueueString(Field);			// queue Field name
	QueueString(Value);			// add string Value
	EndOp();					// add delimiter and process command
}
simulated function ChildSetNull(string ChildPath, string Field)
{
	BeginOp(CHILD_FIELD_OP);    // queue opcode
	QueueString(ChildPath);		// queue path to child mc
	QueueString(Field);			// queue Field name
	QueueNull();			    // add null Value
	EndOp();					// add delimiter and process command
}

// WARNING: Accessing variables is an immediate and blocking operation, doing this is very expensive, use sparingly

// Variables Getters (very expensive) - container MUST BE INITED
// Also works for to access fields in children, like so: GetNum("string_of_child_mc.field_string");
simulated function bool GetBool(string Field) { return Panel.Movie.GetVariableBool(Panel.MCPath $ "." $ Field); }
simulated function float GetNum(string Field) { return Panel.Movie.GetVariableNumber(Panel.MCPath $ "." $ Field); }
simulated function string GetString(string Field) { return Panel.Movie.GetVariableString(Panel.MCPath $ "." $ Field); }

//==============================================================================
//		BATCHING API
//==============================================================================

simulated function BeginFunctionOp(string Func)
{
	BeginOp(FUNCTION_OP);		// queue opcode
	QueueString(Func);			// queue function name
}

simulated function BeginChildFunctionOp(string ChildPath, string Func)
{
	BeginOp(CHILD_FUNCTION_OP); // queue opcode
	QueueString(ChildPath);		// queue path to child mc
	QueueString(Func);			// queue function name
}

// Combine CacheIndex with op command and queue it into the commandQueue
simulated native function BeginOp(int OpMask);

// Queue a String into CommandQueue - must be called between BeginOp() and EndOp() calls
simulated native function QueueString(string Param);

// Queue a Boolean into CommandQueue - must be called between BeginOp() and EndOp() calls
simulated native function QueueBoolean(bool Param);

// Queue a Number into CommandQueue - must be called between BeginOp() and EndOp() calls
simulated native function QueueNumber(float Param);

// Queue Null into CommandQueue - must be called between BeginOp() and EndOp() calls
simulated native function QueueNull();

// Add end of op delimiter (null) and queue commands for processing
simulated native function EndOp();

// Copy queued up commands into global command queue in UIPanel.Movie.m_CommandQueue. 
// Panel must not be marked for removal using this.  
simulated native function ProcessCommands(optional bool Force);

simulated native function bool IsIndexValid();

simulated function Remove()
{
	if(Panel.bIsInited)
	{
		// Screens get immediately removed through UIMovie, no need for remove call here
		// Don't invoke into removal call if the screen, or the parent Panel is already (or about about to be) removed
		if( Panel.ParentPanel != None &&
		   !Panel.ParentPanel.bIsRemoved &&
		   !Panel.Screen.bIsRemoved &&
		   !Panel.Screen.bIsPendingRemoval )
		{
			FunctionVoid("remove");
		}
	}
	else
	{
		Panel.Movie.PanelsPendingRemoval.AddItem(Panel.MCPath);
	}

	BeginOp(CLEANUP_OP); // queue removal command (clean up cached MC in flash)
	ProcessCommands();

 	Panel.Movie.RemoveCachedPanel(CacheIndex);
	CacheIndex = -1; // set CacheIndex to -1 to make sure no further operations occur on this MCController
}