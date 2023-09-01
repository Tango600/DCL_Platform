unit uDCLMessages;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils, Dialogs;

  Function ShowErrorMessage(ErrorCode: Integer; AddText: String=''): Integer;

implementation

uses
  uDCLConst, uDCLData, uDCLMultiLang, uDCLGlobalVariables;

Function ShowErrorMessage(ErrorCode: Integer; AddText: String=''): Integer;
Var
  MessageText: String;
Begin
  Result:=0;
  MessageText:=GetDCLErrorString(ErrorCode, AddText);

  If ErrorCode<0 Then
  Begin
    If GPT.CurrentRunningScrString>0 Then
      MessageText:=MessageText+' / '+AddText+CR+
        GetDCLMessageString(msIn)+' '+GetDCLMessageString(msStringNum)+'('+GetDCLMessageString(msVisualCommand)+') : '+
        IntToStr(GPT.CurrentRunningScrString)+'/-1';

    Result:=MessageDlg(MessageText, mtError, [mbOK], 0);
  End
  Else
    Case ErrorCode Of
    1:
      Result:=MessageDlg(MessageText, mtWarning, [mbOK], 0);
    0:
      Result:=MessageDlg(MessageText, mtError, [mbOK], 0);
    9:
      Result:=MessageDlg(MessageText, mtInformation, [mbOK], 0);
    10:
      If MessageDlg(MessageText, mtConfirmation, mbOKCancel, 0)=1 Then
        Result:=1;
    End;
end;

end.

