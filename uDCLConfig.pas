unit uDCLConfig;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils, Forms,
  uDCLData, uDCLTypes, uDCLConst, uDCLUtils, uStringParams, uDCLOfficeUtils;

type

  { TDCLConfig }

  TDCLConfig=class(TComponent)
  private
    FConnector: TDBConnector;
    Params: TStringList;
    lPath: String;

    procedure LoadConfig(FileName: String);
  public
    constructor Create; overload;

    procedure GetParamsStructure;

    property Path: String read lPath;
    property DBConnector: TDBConnector read FConnector write FConnector;
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
  end
  else
  begin

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
Begin
  If Params.Count>0 Then
  begin
    Parser:=TDCLValuseParser.Create('', nil);

    For i:=0 To Params.Count-1 Do
    Begin
      If Pos('//', TrimLeft(Params[i]))<>1 Then
      Begin
{$IFDEF ADO}
        If PosEx('ConnectionString=', Params[i])=1 Then
          GPT.ConnectionString:=Copy(Params[i], 18, Length(Params[i]));
{$ENDIF}
{$IFDEF SERVERDB}
        If PosEx('UserName=', Params[i])=1 Then
          GPT.DBUserName:=FindParam('UserName=', Params[i]);
        If PosEx('Password=', Params[i])=1 Then
          GPT.DBPassword:=FindParam('Password=', Params[i]);
        If PosEx('DBPath=', Params[i])=1 Then
          GPT.DBPath:=FindParam('DBPath=', Params[i]);
        If PosEx('ServerName=', Params[i])=1 Then
          GPT.ServerName:=FindParam('ServerName=', Params[i]);
        If PosEx('Port=', Params[i])=1 Then
          GPT.Port:=StrToIntEx(FindParam('Port=', Params[i]));
        If PosEx('DBType=', Params[i])=1 Then
          GPT.DBType:=FindParam('DBType=', Params[i]);
        If PosEx('SQLDialect=', Params[i])=1 Then
          GPT.SQLDialect:=StrToIntEx(FindParam('SQLDialect=', Params[i]));
{$ENDIF}
        If PosEx('DBTypeIB=', Params[i])=1 Then
          GPT.IBAll:=FindParam('DBTypeIB=', Params[i])='1';
        If PosEx('CodePage=', Params[i])=1 Then
          GPT.ServerCodePage:=FindParam('CodePage=', Params[i]);
        If PosEx('StringTypeChar=', Params[i])=1 Then
          GPT.StringTypeChar:=Trim(FindParam('StringTypeChar=', Params[i]));
        If PosEx('Viewer=', Params[i])=1 Then
          GPT.Viewer:=FindParam('Viewer=', Params[i]);
        If PosEx('MainFormCaption=', Params[i])=1 Then
          GPT.MainFormCaption:=FindParam('MainFormCaption=', Params[i]);

        If PosEx('DCLUserName=', Params[i])=1 Then
          GPT.DCLUserName:=FindParam('DCLUserName=', Params[i]);
        If PosEx('DCLUserPass=', Params[i])=1 Then
          GPT.EnterPass:=FindParam('DCLUserPass=', Params[i]);

{$IFDEF DEVELOPERMODE}
        If PosEx('GeneratorName=', Params[i])=1 Then
          GPT.GeneratorName:=FindParam('GeneratorName=', Params[i]);
{$ENDIF}
        If PosEx('DisableFieldsList=', Params[i])=1 Then
          If Trim(FindParam('DisableFieldsList=', Params[i]))='1' Then
            GPT.DisableFieldsList:=True;
        If PosEx('GetValueSeparator=', Params[i])=1 Then
          GPT.GetValueSeparator:=FindParam('GetValueSeparator=', Params[i]);

        If PosEx('MultiRoles=', Params[i])=1 Then
        Begin
          If Trim(FindParam('MultiRoles=', Params[i]))='1' Then
            GPT.MultiRolesMode:=True;
        End;

        If PosEx('Debug=', Params[i])=1 Then
        Begin
          If Trim(FindParam('Debug=', Params[i]))='1' Then
          Begin
            GPT.DebugOn:=True;
          End
          Else
            GPT.DebugOn:=False;
        End;

        If PosEx('SQLMonitor=1', Params[i])=1 Then
        Begin
          // SQLMonActions.StartSQLTrace;
        End;

        If PosEx('DebugMesseges=', Params[i])=1 Then
        Begin
          If Trim(FindParam('DebugMesseges=', Params[i]))='1' Then
            GPT.DebugMesseges:=True
          Else
            GPT.DebugMesseges:=False;
        End;

        If PosEx('UpperBase=', Params[i])=1 Then
        Begin
          If Trim(FindParam('UpperBase=', Params[i]))='1' Then
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

        If PosEx('HashPass=', Params[i])=1 Then
        Begin
          If Trim(FindParam('HashPass=', Params[i]))='1' Then
          Begin
            GPT.HashPass:=True;
          End
          Else
          Begin
            GPT.HashPass:=False;
          End;
        End;

        If PosEx('UseMessages=', Params[i])=1 Then
        Begin
          If Trim(FindParam('UseMessages=', Params[i]))='1' Then
            GPT.UseMessages:=True
          Else
            GPT.UseMessages:=False;
        End;

        If PosEx('ConfirmExit=', Params[i])=1 Then
        Begin
          If Trim(FindParam('ConfirmExit=', Params[i]))='1' Then
            GPT.ExitCnf:=True
          Else
            GPT.ExitCnf:=False;
        End;

        If PosEx('ShowPicture=', Params[i])=1 Then
        Begin
          If Trim(FindParam('ShowPicture=', Params[i]))='1' Then
            GPT.ShowPicture:=True
          Else
            GPT.ShowPicture:=False;
        End;
        If PosEx('DialogsSettings=', Params[i])=1 Then
        Begin
          If Trim(FindParam('DialogsSettings=', Params[i]))='1' Then
            GPT.DialogsSettings:=True
          Else
            GPT.DialogsSettings:=False;
        End;
        If PosEx('DisableColors=', Params[i])=1 Then
        Begin
          If Trim(FindParam('DisableColors=', Params[i]))='1' Then
            GPT.DisableColors:=True
          Else
            GPT.DisableColors:=False;
        End;
        If PosEx('OneCopy=', Params[i])=1 Then
        Begin
          If Trim(FindParam('OneCopy=', Params[i]))='1' Then
            GPT.OneCopy:=True
          Else
            GPT.OneCopy:=False;
        End;

        If PosEx('DisableIniPasword=1', Params[i])=1 Then
        Begin
          GPT.DisableIniPasword:=True;
        End;

{$IFDEF CPU32}
        If PosEx('LibPath=', Params[i])=1 Then
        Begin
          GPT.LibPath:=FindParam('LibPath=', Params[i]);
        End;
{$ENDIF}
{$IFDEF CPU64}
        If PosEx('LibPath_x64=', Params[i])=1 Then
        Begin
          GPT.LibPath:=FindParam('LibPath_x64=', Params[i]);
        End;
{$ENDIF}
        If PosEx('UserLogging=1', Params[i])=1 Then
        Begin
          GPT.UserLogging:=True;
        End;

        If PosEx('UserLoggingHistory=1', Params[i])=1 Then
        Begin
          GPT.UserLoggingHistory:=True;
        End;

        {If PosEx('UseUTF8=', Params[i])=1 Then
        Begin
          If Trim(FindParam('UseUTF8=', Params[i]))='1' Then
            DecodeBase:=True
          Else
            DecodeBase:=False;
        End;}

        If PosEx('DateFormat=', Params[i])=1 Then
        Begin
          GPT.DateFormat:=Trim(FindParam('DateFormat=', Params[i]));
        End;

        If PosEx('Language=', Params[i])=1 Then
        Begin
          ///LangName:=Trim(FindParam('Language=', Params[i]));
        End;

        If PosEx('DateSeparator=', Params[i])=1 Then
        Begin
          GPT.DateFormat:=Trim(FindParam('DateSeparator=', Params[i]));
        End;

        If PosEx('TimeFormat=', Params[i])=1 Then
        Begin
          GPT.TimeFormat:=Trim(FindParam('TimeFormat=', Params[i]));
        End;

        If PosEx('TimeSeparator=', Params[i])=1 Then
        Begin
          GPT.TimeFormat:=Trim(FindParam('TimeSeparator=', Params[i]));
        End;

        If PosEx('OfficeType=', Params[i])=1 Then
        Begin
          GPT.OfficeFormat:=ConvertOfficeType(Trim(FindParam('OfficeType=', Params[i])));
        End;

        If PosEx('OfficeDocumentFormat=', Params[i])=1 Then
        Begin
          GPT.OfficeDocumentFormat:=GetDocumentType(Trim(FindParam('OfficeDocumentFormat=', Params[i])));
        End;

        If PosEx('UserLocalProfile=', Params[i])=1 Then
        Begin
          AppConfigDir:=Trim(FindParam('UserLocalProfile=', Params[i]));
          Parser.RePlaseVariables('', AppConfigDir, nil);
          AppConfigDir:=IncludeTrailingPathDelimiter(AppConfigDir);
        End;

        If PosEx('WordOLEExtension=', Params[i])=1 Then
        Begin
          GPT.WordOLEExtension:=Trim(FindParam('WordOLEExtension=', Params[i]));
        End;

        If PosEx('ExcelOLEExtension=', Params[i])=1 Then
        Begin
          GPT.ExcelOLEExtension:=Trim(FindParam('ExcelOLEExtension=', Params[i]));
        End;
      End;
    End;
  end;
End;

end.

