unit uDCLGlobalVariables;
{$mode Delphi}

interface

uses
  Classes, SysUtils,
  uDCLData, uDCLFormsNotifier;

var
  GPT: TGPT;
  Path, AppConfigDir, UserProfileDir: string;
  FormsNotifier: TDCLFormsNotifier;

implementation


Initialization

  GPT.StringTypeChar:='''';
  GPT.DialogsSettings:=True;
end.

