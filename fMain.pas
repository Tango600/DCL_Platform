unit fMain;
{$I DefineType.pas}

interface

uses
  {$IFDEF MSWINDOWS}
  Windows, Messages, LazUTF8,
  {$ENDIF}
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls,
  uDCLConst, uDCLData, uDCLMultiLang;

type

  { TMainForm }

  TMainForm = class(TForm)
    StatusBar1: TStatusBar;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    procedure ShowAbout;
    {$IFDEF MSWINDOWS}
    procedure WMSysCommand(var message: TWMSysCommand); message WM_SysCommand;
    {$ENDIF}
  public

  end;

{$IFDEF MSWINDOWS}
Const
  AboutMenuItem=WM_USER+1;
  LockMenuItem=AboutMenuItem+1;
{$ENDIF}

implementation

uses
  fAbout, IniFiles, uDCLGlobalVariables, uDCLMeasurements, uDCLVersion;

{$R *.lfm}

{ TMainForm }

{$IFDEF MSWINDOWS}
procedure TMainForm.WMSysCommand(var message: TWMSysCommand);
begin
  Case message.CmdType of
  AboutMenuItem: ShowAbout;
  //LockMenuItem: DCLMainLogOn.Lock;
  Else
    inherited;
  End;
end;
{$ENDIF}

procedure TMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
var
  ConfigPath, SectionName: String;
  Settings: TIniFile;
begin
  if GPT.DialogsSettings and (Self.WindowState=wsNormal) then
  begin
    ConfigPath:=AppConfigDir+FormConfigDir+'Base_'+GPT.BaseID+PathDelim;
    if not DirectoryExists(ConfigPath) then
      ForceDirectories(ConfigPath);

    SectionName:='Position';
    if Self.FormStyle=fsMDIForm then
      SectionName:=SectionName+'MDI';

    Settings:=TIniFile.Create(ConfigPath+'MainForm.ini', TEncoding.UTF8);
    Settings.WriteInteger(SectionName, 'Top', Self.Top);
    Settings.WriteInteger(SectionName, 'Left', Self.Left);
    Settings.WriteInteger(SectionName, 'Height', Self.Height+AddHeight);
    Settings.WriteInteger(SectionName, 'Width', Self.Width);

    FreeAndNil(Settings);
  end;
end;

function FindCommandStrParam(Str: String): String;
var
  i: Byte;
begin
  For i:=1 to ParamCount do
  begin
    if Pos(LowerCase(Str), LowerCase(ParamStr(i)))<>0 then
    begin
      Result:=Copy(ParamStr(i), Length(Str)+1, Length(ParamStr(i)));
      break;
    end;
  end;
end;

function FindMDI: Boolean;
begin
  Result:=FindCommandStrParam('MDI=')='1';
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  MDI: Boolean;
  S: String;
  T: TextFile;
begin
  Caption:='DCL Platform '+DCLVersion;

  MDI:=False;
  if FileExists('interface.ini') then
  begin
    AssignFile(T, 'interface.ini');
    ReSet(T);
    While not EOF(T) do
    begin
      ReadLn(T, S);
      if Pos('mdi', LowerCase(S))<>0 then
        MDI:=True;
    end;
    CloseFile(T);
  end;

  if MDI or FindMDI then
  begin
    FormStyle:=fsMDIForm;

    Height:=600;
  end;
end;

procedure TMainForm.FormShow(Sender: TObject);
var
  ConfigPath, SectionName: String;
  Settings: TIniFile;
begin
  if GPT.DialogsSettings then
  begin
    ConfigPath:=AppConfigDir+FormConfigDir+'Base_'+GPT.BaseID+PathDelim;
    if DirectoryExists(ConfigPath) and FileExists(ConfigPath+'MainForm.ini') then
    begin
      Settings:=TIniFile.Create(ConfigPath+'MainForm.ini', TEncoding.UTF8);

      SectionName:='Position';
      if Self.FormStyle=fsMDIForm then
        SectionName:=SectionName+'MDI';

      Self.Top:=Settings.ReadInteger(SectionName, 'Top', Self.Top);
      Self.Left:=Settings.ReadInteger(SectionName, 'Left', Self.Left);
      Self.Height:=Settings.ReadInteger(SectionName, 'Height', Self.Height+AddHeight);
      Self.Width:=Settings.ReadInteger(SectionName, 'Width', Self.Width);

      FreeAndNil(Settings);
    end;
  end;

  {$IFDEF MSWINDOWS}
  AppendMenu(GetSystemMenu(Handle, False), MF_SEPARATOR, 0, '');
  AppendMenu(GetSystemMenu(Handle, False), MF_STRING, AboutMenuItem,
    Pchar(UTF8ToWinCP('DCL '+GetDCLMessageString(msVersion)+' : '+DCLVersion)));
  //AppendMenu(GetSystemMenu(Handle, False), MF_STRING, LockMenuItem, PChar(UTF8ToWinCP(GetDCLMessageString(msLock)+'...')));
  {$ENDIF}
end;

procedure TMainForm.ShowAbout;
var
  About: TAboutForm;
begin
  About:=TAboutForm.Create(Self);

  About.ShowModal;
  About.Release;
end;

end.

