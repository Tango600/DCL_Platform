unit uDCLGlobalVariables;

interface

uses
  uDCLGlobalConfigTable;

var
  GPT: TGPT;
  Path, UserProfileDir: string;
  DialogResult: Boolean;

implementation

uses
  uDCLConst;

Initialization

  GPT.StringTypeChar:=DefaultStringDelimiter;
  GPT.DialogsSettings:=True;
end.

