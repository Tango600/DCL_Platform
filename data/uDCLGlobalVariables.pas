unit uDCLGlobalVariables;

interface

uses
  uDCLGlobalConfigTable;

var
  GPT: TGPT;
  Path, AppConfigDir, UserProfileDir: string;

implementation


Initialization

  GPT.StringTypeChar:='''';
  GPT.DialogsSettings:=True;
end.

