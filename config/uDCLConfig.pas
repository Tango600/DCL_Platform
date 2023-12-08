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
    procedure LoadExternalParams(var ExtParams: TStringList);

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

  if ParamCount>0 then
  begin
    if FileExists(ParamStr(1)) and (LowerCase(ExtractFileExt(ParamStr(1)))='.ini') then
      GPT.IniFileName:=ParamStr(1);
  end;

  For i:=1 to ParamCount do
  Begin
    If PosEx('-ini', ParamStr(i))<>0 Then
      GPT.IniFileName:=ParamStr(i+1);
    If PosEx('-user', ParamStr(i))<>0 Then
      GPT.DCLUserName:=ParamStr(i+1);
    If PosEx('-password', ParamStr(i))<>0 Then
      GPT.EnterPass:=ParamStr(i+1);
  End;

  LoadConfig(GPT.IniFileName);

  GetParamsStructure;
end;

procedure TDCLConfig.GetParamsStructure;
Var
  i: Integer;
  Parser: TDCLValuseParser;
  cs, s: String;

function IsParameter(ParamName, ParamLine: String): Boolean;
begin
  Result:=PosEx(ParamName, ParamLine)=1;
end;

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

{$IFDEF ODBC}
        If IsParameter('DSN=', cs) then
          GPT.DataBaseName:=FindParam('DSN=', cs);
{$ENDIF}

{$IFDEF SERVERDB}
        If IsParameter('UserName=', cs) then
          GPT.DBUserName:=FindParam('UserName=', cs);
        If IsParameter('Password=', cs) then
          GPT.DBPassword:=FindParam('Password=', cs);
        If IsParameter('DBPath=', cs) then
          GPT.DBPath:=FindParam('DBPath=', cs);
        If IsParameter('ServerName=', cs) then
          GPT.ServerName:=FindParam('ServerName=', cs);
        If IsParameter('Port=', cs) then
          GPT.Port:=StrToIntEx(FindParam('Port=', cs));
        If IsParameter('DBType=', cs) then
          GPT.DBType:=FindParam('DBType=', cs);
        If IsParameter('SQLDialect=', cs) then
          GPT.SQLDialect:=StrToIntEx(FindParam('SQLDialect=', cs));
{$ENDIF}
        If IsParameter('DBTypeIB=', cs) then
          GPT.IBAll:=FindParam('DBTypeIB=', cs)='1';
        If IsParameter('CodePage=', cs) then
          GPT.ServerCodePage:=FindParam('CodePage=', cs);
        If IsParameter('StringTypeChar=', cs) then
          GPT.StringTypeChar:=Trim(FindParam('StringTypeChar=', cs));
        If IsParameter('Viewer=', cs) then
          GPT.Viewer:=FindParam('Viewer=', cs);
        If IsParameter('MainFormCaption=', cs) then
          GPT.MainFormCaption:=FindParam('MainFormCaption=', cs);

        If IsParameter('DCLUserName=', cs) then
          GPT.DCLUserName:=FindParam('DCLUserName=', cs);
        If IsParameter('DCLUserPass=', cs) then
          GPT.EnterPass:=FindParam('DCLUserPass=', cs);

        If IsParameter('DisableFieldsList=', cs) then
          If Trim(FindParam('DisableFieldsList=', cs))='1' then
            GPT.DisableFieldsList:=True;

        If IsParameter('GetValueSeparator=', cs) then
          GPT.GetValueSeparator:=FindParam('GetValueSeparator=', cs);

        If IsParameter('SQLMonitor=1', cs) then
        Begin
          // SQLMonActions.StartSQLTrace;
        End;

        If IsParameter('DebugMesseges=', cs) then
        Begin
          GPT.DebugMesseges:=Trim(FindParam('DebugMesseges=', cs))='1';
        End;

        If IsParameter('UseMessages=', cs) then
        Begin
          GPT.UseMessages:=Trim(FindParam('UseMessages=', cs))='1';
        End;

        If IsParameter('ConfirmExit=', cs) then
        Begin
          GPT.ExitCnf:=Trim(FindParam('ConfirmExit=', cs))='1';
        End;

        If IsParameter('DialogsSettings=', cs) then
        Begin
          GPT.DialogsSettings:=Trim(FindParam('DialogsSettings=', cs))='1';
        End;

        If IsParameter('DisableColors=', cs) then
        Begin
          GPT.DisableColors:=Trim(FindParam('DisableColors=', cs))='1';
        End;

        If IsParameter('OneCopy=', cs) then
        Begin
          GPT.OneCopy:=StrToInt(FindParam('OneCopy=', cs));
        End;

        If IsParameter('DisableIniPasword=', cs) then
        Begin
          GPT.DisableIniPasword:=Trim(FindParam('DisableIniPasword=', cs))='1';
        End;

{$IFDEF CPU32}
        If IsParameter('LibPath=', cs) then
        Begin
          GPT.LibPath:=FindParam('LibPath=', cs);
        End;
{$ENDIF}
{$IFDEF CPU64}
        If IsParameter('LibPath_x64=', cs) then
        Begin
          GPT.LibPath:=FindParam('LibPath_x64=', cs);
        End;
{$ENDIF}

        If IsParameter('DateFormat=', cs) then
        Begin
          GPT.DateFormat:=Trim(FindParam('DateFormat=', cs));
        End;

        If IsParameter('Language=', cs) then
        Begin
          ///LangName:=Trim(FindParam('Language=', cs));
        End;

        If IsParameter('DateSeparator=', cs) then
        Begin
          s:=FindParam('DateSeparator=', cs);
          if s<>'' then
            GPT.DateSeparator:=s[1];
        End;

        If IsParameter('TimeFormat=', cs) then
        Begin
          GPT.TimeFormat:=Trim(FindParam('TimeFormat=', cs));
        End;

        If IsParameter('TimeSeparator=', cs) then
        Begin
          s:=FindParam('TimeSeparator=', cs);
          if s<>'' then
            GPT.TimeSeparator:=s[1];
        End;

        If IsParameter('ThousandSeparator=', cs) then
        Begin
          s:=FindParam('ThousandSeparator=', cs);
          if s<>'' then
            GPT.ThousandSeparator:=s[1];
        End;

        If IsParameter('DecimalSeparator=', cs) then
        Begin
          s:=FindParam('DecimalSeparator=', cs);
          if s<>'' then
            GPT.DecimalSeparator:=s[1];
        End;

        {$IFDEF MSWINDOWS}
        If IsParameter('OfficeType=', cs) then
        Begin
          GPT.OfficeFormat:=ConvertOfficeType(Trim(FindParam('OfficeType=', cs)));
        End;

        If IsParameter('OfficeDocumentFormat=', cs) then
        Begin
          GPT.OfficeDocumentFormat:=GetDocumentType(Trim(FindParam('OfficeDocumentFormat=', cs)));
        End;
        {$ENDIF}

        If IsParameter('UserLocalProfile=', cs) then
        Begin
          AppConfigDir:=IncludeTrailingPathDelimiter(Trim(FindParam('UserLocalProfile=', cs)));
        End;

        If IsParameter('WordOLEExtension=', cs) then
        Begin
          GPT.WordOLEExtension:=Trim(FindParam('WordOLEExtension=', cs));
        End;

        If IsParameter('ExcelOLEExtension=', cs) then
        Begin
          GPT.ExcelOLEExtension:=Trim(FindParam('ExcelOLEExtension=', cs));
        End;
      End;
    End;
  end;
End;

procedure TDCLConfig.LoadExternalParams(var ExtParams: TStringList);
begin
  Params.AddStrings(ExtParams);
end;

end.

