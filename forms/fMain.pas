unit fMain;
{$mode Delphi}

interface

uses
  {$IFDEF MSWINDOWS}
  Windows, Messages, LazUTF8,
  {$ENDIF}
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls,
  uDCLConst, uDCLData, uIDCLMain;

type

  { TMainForm }

  TMainForm = class(TForm)
    StatusBar1: TStatusBar;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FIMain: IDCLMain;

    procedure ShowAbout;
    {$IFDEF MSWINDOWS}
    procedure WMSysCommand(var message: TWMSysCommand); message WM_SysCommand;
    {$ENDIF}
  public
    property DCLMain: IDCLMain write FIMain;
  end;

{$IFDEF MSWINDOWS}
Const
  AboutMenuItem=WM_USER+1;
  LockMenuItem=AboutMenuItem+1;
{$ENDIF}

implementation

uses
  IniFiles, uDCLGlobalVariables, uDCLMessages, uDCLMultiLang, uDCLVersion,
  uSystemUtils;

{$R *.lfm}

{ TMainForm }

{$IFDEF MSWINDOWS}
procedure TMainForm.WMSysCommand(var message: TWMSysCommand);
begin
  Case message.CmdType of
  AboutMenuItem: ShowAbout;
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
  FIMain.CloseAllDialogs;

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
    Settings.WriteInteger(SectionName, 'Height', Self.Height);
    Settings.WriteInteger(SectionName, 'Width', Self.Width);

    FreeAndNil(Settings);
  end;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if GPT.ExitCnf then
  begin
    CanClose:=ShowErrorMessage(10, GetDCLMessageString(msClose))=1;
  end;
end;

function FindMDI: Boolean;
begin
  {$IFDEF MSWINDOWS}
  Result:=FindCommandStrParam('MDI')='1';
  {$ELSE}
  Result:=False;
  {$ENDIF}
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  MDI: Boolean;
  S: String;
  T: TextFile;
begin
  Caption:='DCL Platform '+DCLVersion;

  MDI:=False;
  {$IFDEF MSWINDOWS}
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
  {$ENDIF}

  if MDI or FindMDI then
  begin
    FormStyle:=fsMDIForm;
    Height:=600;
  end
  else
  begin
    if GPT.MenuType=mtClassic then
      BorderIcons:=BorderIcons-[biMaximize];
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
      Self.Height:=Settings.ReadInteger(SectionName, 'Height', Self.Height);
      Self.Width:=Settings.ReadInteger(SectionName, 'Width', Self.Width);

      FreeAndNil(Settings);
    end;
  end;

  {$IFDEF MSWINDOWS}
  AppendMenu(GetSystemMenu(Handle, False), MF_SEPARATOR, 0, '');
  AppendMenu(GetSystemMenu(Handle, False), MF_STRING, AboutMenuItem,
    Pchar(UTF8ToWinCP('DCL '+GetDCLMessageString(msVersion)+' : '+DCLVersion)));
  {$ENDIF}
end;

procedure TMainForm.ShowAbout;
begin
  FIMain.About;
end;

end.

