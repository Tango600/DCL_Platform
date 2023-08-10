unit uDCLConfig;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils, Forms,
{$IFDEF MSWINDOWS}
  uDCLOfficeUtils,
{$ENDIF}
  uDCLData, uDCLConst, uDCLUtils, uStringParams;

type

  { TDCLConfig }

  TDCLConfig=class(TComponent)
  private
    Params: TStringList;
    lPath: String;

    procedure LoadConfig(FileName: String);
  public
    constructor Create; overload;

    procedure GetParamsStructure;

    property Path: String read lPath;
  end;

implementation

uses
  uDCLValuesParser, uDCLGlobalVariables;

{ TDCLConfig }

procedure TDCLConfig.LoadConfig(FileName: String);
begin
  if FileExists(FileName) then
  begin
    Params.LoadFromFile(FileName);
  end;
end;

constructor TDCLConfig.Create;
var
  i: Integer;
begin
  inherited Create(Application);
  Params:=TStringList.Create;
  lPath:=ExtractFilePath(Application.ExeName);
  SetCurrentDir(lPath);
  If GPT.IniFileName='' Then
    GPT.IniFileName:=lPath+'DCL.ini';

  For i:=1 to ParamCount do
  Begin
    If PosEx('-ini', ParamStr(i))<>0 Then
      GPT.IniFileName:=ParamStr(i+1);
    If PosEx('-user', ParamStr(i))<>0 Then
      GPT.DCLUserName:=ParamStr(i+1);
    If PosEx('-password', ParamStr(i))<>0 Then
      GPT.EnterPass:=ParamStr(i+1);
    If PosEx('-scr', ParamStr(i))<>0 Then
      GPT.LaunchScrFile:=ParamStr(i+1);
    If PosEx('-dialog', ParamStr(i))<>0 Then
      GPT.LaunchForm:=ParamStr(i+1);
  End;

  LoadConfig(GPT.IniFileName);

  GetParamsStructure;

  //LoadLangRes(LangName, Path);

  {$IFDEF FPC}
  {$IFDEF UNIX}
  FormatSettings.DateSeparator:=GPT.DateSeparator;
  FormatSettings.ShortDateFormat:=GPT.DateFormat;
  FormatSettings.LongTimeFormat:=GPT.TimeFormat;
  FormatSettings.TimeSeparator:=GPT.TimeSeparator;
  {$ENDIF}
  {$ENDIF}
end;

procedure TDCLConfig.GetParamsStructure;
Var
  i: Integer;
  Parser: TDCLValuseParser;
  cs: String;
Begin
  If Params.Count>0 Then
  begin
    Parser:=TDCLValuseParser.Create('', nil);

    For i:=0 To Params.Count-1 Do
    Begin
      If Pos('//', TrimLeft(Params[i]))<>1 Then
      Begin
        cs:=Params[i];
        Parser.RePlaseVariables('', cs, nil);

{$IFDEF ADO}
        If PosEx('ConnectionString=', cs)=1 Then
          GPT.ConnectionString:=Copy(cs, 18, Length(cs));
{$ENDIF}
{$IFDEF SERVERDB}
        If PosEx('UserName=', cs)=1 Then
          GPT.DBUserName:=FindParam('UserName=', cs);
        If PosEx('Password=', cs)=1 Then
          GPT.DBPassword:=FindParam('Password=', cs);
        If PosEx('DBPath=', cs)=1 Then
          GPT.DBPath:=FindParam('DBPath=', cs);
        If PosEx('ServerName=', cs)=1 Then
          GPT.ServerName:=FindParam('ServerName=', cs);
        If PosEx('Port=', cs)=1 Then
          GPT.Port:=StrToIntEx(FindParam('Port=', cs));
        If PosEx('DBType=', cs)=1 Then
          GPT.DBType:=FindParam('DBType=', cs);
        If PosEx('SQLDialect=', cs)=1 Then
          GPT.SQLDialect:=StrToIntEx(FindParam('SQLDialect=', cs));
{$ENDIF}
        If PosEx('DBTypeIB=', cs)=1 Then
          GPT.IBAll:=FindParam('DBTypeIB=', cs)='1';
        If PosEx('CodePage=', cs)=1 Then
          GPT.ServerCodePage:=FindParam('CodePage=', cs);
        If PosEx('StringTypeChar=', cs)=1 Then
          GPT.StringTypeChar:=Trim(FindParam('StringTypeChar=', cs));
        If PosEx('Viewer=', cs)=1 Then
          GPT.Viewer:=FindParam('Viewer=', cs);
        If PosEx('MainFormCaption=', cs)=1 Then
          GPT.MainFormCaption:=FindParam('MainFormCaption=', cs);

        If PosEx('DCLUserName=', cs)=1 Then
          GPT.DCLUserName:=FindParam('DCLUserName=', cs);
        If PosEx('DCLUserPass=', cs)=1 Then
          GPT.EnterPass:=FindParam('DCLUserPass=', cs);

{$IFDEF DEVELOPERMODE}
        If PosEx('GeneratorName=', cs)=1 Then
          GPT.GeneratorName:=FindParam('GeneratorName=', cs);
{$ENDIF}
        If PosEx('DisableFieldsList=', cs)=1 Then
          If Trim(FindParam('DisableFieldsList=', cs))='1' Then
            GPT.DisableFieldsList:=True;
        If PosEx('GetValueSeparator=', cs)=1 Then
          GPT.GetValueSeparator:=FindParam('GetValueSeparator=', cs);

        If PosEx('MultiRoles=', cs)=1 Then
        Begin
          If Trim(FindParam('MultiRoles=', cs))='1' Then
            GPT.MultiRolesMode:=True;
        End;

        If PosEx('Debug=', cs)=1 Then
        Begin
          If Trim(FindParam('Debug=', cs))='1' Then
          Begin
            GPT.DebugOn:=True;
          End
          Else
            GPT.DebugOn:=False;
        End;

        If PosEx('SQLMonitor=1', cs)=1 Then
        Begin
          // SQLMonActions.StartSQLTrace;
        End;

        If PosEx('DebugMesseges=', cs)=1 Then
        Begin
          If Trim(FindParam('DebugMesseges=', cs))='1' Then
            GPT.DebugMesseges:=True
          Else
            GPT.DebugMesseges:=False;
        End;

        If PosEx('UpperBase=', cs)=1 Then
        Begin
          If Trim(FindParam('UpperBase=', cs))='1' Then
          Begin
            GPT.UpperString:=' upper(';
            GPT.UpperStringEnd:=') ';
          End
          Else
          Begin
            GPT.UpperString:=' ';
            GPT.UpperStringEnd:=' ';
          End;
        End;

        If PosEx('HashPass=', cs)=1 Then
        Begin
          If Trim(FindParam('HashPass=', cs))='1' Then
          Begin
            GPT.HashPass:=True;
          End
          Else
          Begin
            GPT.HashPass:=False;
          End;
        End;

        If PosEx('UseMessages=', cs)=1 Then
        Begin
          If Trim(FindParam('UseMessages=', cs))='1' Then
            GPT.UseMessages:=True
          Else
            GPT.UseMessages:=False;
        End;

        If PosEx('ConfirmExit=', cs)=1 Then
        Begin
          If Trim(FindParam('ConfirmExit=', cs))='1' Then
            GPT.ExitCnf:=True
          Else
            GPT.ExitCnf:=False;
        End;

        If PosEx('ShowPicture=', cs)=1 Then
        Begin
          If Trim(FindParam('ShowPicture=', cs))='1' Then
            GPT.ShowPicture:=True
          Else
            GPT.ShowPicture:=False;
        End;
        If PosEx('DialogsSettings=', cs)=1 Then
        Begin
          If Trim(FindParam('DialogsSettings=', cs))='1' Then
            GPT.DialogsSettings:=True
          Else
            GPT.DialogsSettings:=False;
        End;
        If PosEx('DisableColors=', cs)=1 Then
        Begin
          If Trim(FindParam('DisableColors=', cs))='1' Then
            GPT.DisableColors:=True
          Else
            GPT.DisableColors:=False;
        End;
        If PosEx('OneCopy=', cs)=1 Then
        Begin
          GPT.OneCopy:=Trim(FindParam('OneCopy=', cs))='1';
        End;

        If PosEx('DisableIniPasword=1', cs)=1 Then
        Begin
          GPT.DisableIniPasword:=True;
        End;

{$IFDEF CPU32}
        If PosEx('LibPath=', cs)=1 Then
        Begin
          GPT.LibPath:=FindParam('LibPath=', cs);
        End;
{$ENDIF}
{$IFDEF CPU64}
        If PosEx('LibPath_x64=', cs)=1 Then
        Begin
          GPT.LibPath:=FindParam('LibPath_x64=', cs);
        End;
{$ENDIF}
        If PosEx('UserLogging=1', cs)=1 Then
        Begin
          GPT.UserLogging:=True;
        End;

        If PosEx('UserLoggingHistory=1', cs)=1 Then
        Begin
          GPT.UserLoggingHistory:=True;
        End;

        {If PosEx('UseUTF8=', cs)=1 Then
        Begin
          If Trim(FindParam('UseUTF8=', cs))='1' Then
            DecodeBase:=True
          Else
            DecodeBase:=False;
        End;}

        If PosEx('DateFormat=', cs)=1 Then
        Begin
          GPT.DateFormat:=Trim(FindParam('DateFormat=', cs));
        End;

        If PosEx('Language=', cs)=1 Then
        Begin
          ///LangName:=Trim(FindParam('Language=', cs));
        End;

        If PosEx('DateSeparator=', cs)=1 Then
        Begin
          GPT.DateFormat:=Trim(FindParam('DateSeparator=', cs));
        End;

        If PosEx('TimeFormat=', cs)=1 Then
        Begin
          GPT.TimeFormat:=Trim(FindParam('TimeFormat=', cs));
        End;

        If PosEx('TimeSeparator=', cs)=1 Then
        Begin
          GPT.TimeFormat:=Trim(FindParam('TimeSeparator=', cs));
        End;

        {$IFDEF MSWINDOWS}
        If PosEx('OfficeType=', cs)=1 Then
        Begin
          GPT.OfficeFormat:=ConvertOfficeType(Trim(FindParam('OfficeType=', cs)));
        End;

        If PosEx('OfficeDocumentFormat=', cs)=1 Then
        Begin
          GPT.OfficeDocumentFormat:=GetDocumentType(Trim(FindParam('OfficeDocumentFormat=', cs)));
        End;
        {$ENDIF}

        If PosEx('UserLocalProfile=', cs)=1 Then
        Begin
          AppConfigDir:=Trim(FindParam('UserLocalProfile=', cs));
          AppConfigDir:=IncludeTrailingPathDelimiter(AppConfigDir);
        End;

        If PosEx('WordOLEExtension=', cs)=1 Then
        Begin
          GPT.WordOLEExtension:=Trim(FindParam('WordOLEExtension=', cs));
        End;

        If PosEx('ExcelOLEExtension=', cs)=1 Then
        Begin
          GPT.ExcelOLEExtension:=Trim(FindParam('ExcelOLEExtension=', cs));
        End;
      End;
    End;
  end;
End;

end.

