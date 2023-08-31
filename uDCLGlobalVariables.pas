unit uDCLGlobalVariables;
{$I DefineType.pas}

interface

uses
  uDCLGlobalConfigTable, uDCLFormsNotifier;

var
  GPT: TGPT;
  Path, AppConfigDir, UserProfileDir: string;
  FormsNotifier: TDCLFormsNotifier;

implementation


Initialization

  GPT.StringTypeChar:='''';
  GPT.DialogsSettings:=True;
end.

