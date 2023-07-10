unit uWindowsScript;
{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, Variants, ComObj,
  uDCLConst;

Procedure ExecuteStatement(Code: String);
Function RunScript(Code: String): String;
procedure ExecVBS(VBSScript: String);
Procedure AddCodeScript(Code: TStringList);


implementation

var
  ScriptRunCreated: Boolean;
  ScriptRun: Variant;

Procedure CreateScriptRun;
Begin
  If Not ScriptRunCreated Then
  Begin
    ScriptRun:=CreateOleObject('ScriptControl');
    ScriptRun.Language:=ScriptControlLanguage;
    ScriptRun.UseSafeSubset:=False;
    ScriptRun.Timeout:=-1;
    ScriptRunCreated:=True;
  End;
End;

Function RunScript(Code: String): String;
Begin
  CreateScriptRun;
  Result:=ScriptRun.Eval(Code);
End;

Procedure ExecuteStatement(Code: String);
Begin
  CreateScriptRun;
  ScriptRun.ExecuteStatement(Code);
End;

Procedure ResetScript;
Begin
  If ScriptRunCreated Then
    ScriptRun.Reset;
End;

Procedure AddCodeScript(Code: TStringList);
Begin
  CreateScriptRun;
  ScriptRun.AddCode(Code.Text);
End;

procedure ExecVBS(VBSScript: String);
Var
  VBSText: TStringList;
  tmpVBSText: String;
Begin
  VBSText:=TStringList.Create;
  VBSText.Text:=VBSScript;
  If VBSText.Count>0 Then
  Begin
    tmpVBSText:=VBSText.Text;
    ExecuteStatement(tmpVBSText);
  End;
  FreeAndNil(VBSText);
End;

Procedure DestroyScript;
Begin
  If ScriptRunCreated Then
  Begin
    //FreeAndNil(ScriptRun);
    ScriptRun:=Unassigned;
    ScriptRunCreated:=False;
  End;
End;

end.

