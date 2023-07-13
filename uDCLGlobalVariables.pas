unit uDCLGlobalVariables;
{$mode Delphi}

interface

uses
  Classes, SysUtils,
  uDCLData, uDCLFormsNotifier;

var
  GPT: TGPT;
  ConnectErrorCode: Byte;
  Path, AppConfigDir, UserProfileDir: string;
  EvalResultScript: string;
  FormsNotifier: TDCLFormsNotifier;

implementation


Initialization

  GPT.StringTypeChar:='''';
  GPT.DialogsSettings:=True;
end.

