unit fDCLProtectionForm;
{$mode Delphi}

interface

uses
  {$IFDEF MSWINDOWS}
  Windows, Messages, LazUTF8,
  {$ENDIF}
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  uIDCLProtectionEngine, uIDCLMain;

type

  { TProtectionForm }

  TProtectionForm = class(TForm)
    btApplay: TButton;
    edRegistrationKey: TEdit;
    edProgramKey: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    sbCopyKey: TSpeedButton;
    procedure btApplayClick(Sender: TObject);
    constructor Create(AOwner: TComponent; ProtectionEngine: IDCLProtectionEngine; DCLMain: IDCLMain); overload;
    procedure FormShow(Sender: TObject);
    procedure sbCopyKeyClick(Sender: TObject);
  private
    FDCLMain: IDCLMain;
    FProtectionEngine: IDCLProtectionEngine;

    procedure ShowAbout;
    {$IFDEF MSWINDOWS}
    procedure WMSysCommand(var message: TWMSysCommand); message WM_SysCommand;
    {$ENDIF}
  public

  end;

implementation

uses
  Clipbrd,
  uDCLConst, uDCLMultiLang, uDCLVersion;

{$R *.lfm}

{$IFDEF MSWINDOWS}
const
  AboutMenuItem=WM_USER+1;
{$ENDIF}

{ TProtectionForm }

{$IFDEF MSWINDOWS}
procedure TProtectionForm.WMSysCommand(var message: TWMSysCommand);
begin
  Case message.CmdType of
  AboutMenuItem: ShowAbout;
  Else
    inherited;
  End;
end;
{$ENDIF}

constructor TProtectionForm.Create(AOwner: TComponent; ProtectionEngine: IDCLProtectionEngine; DCLMain: IDCLMain);
begin
  inherited Create(AOwner);
  FProtectionEngine:=ProtectionEngine;
  FDCLMain:=DCLMain;

  edProgramKey.Text:=FProtectionEngine.GetProtectionKey;
end;

procedure TProtectionForm.FormShow(Sender: TObject);
begin
  {$IFDEF MSWINDOWS}
  AppendMenu(GetSystemMenu(Handle, False), MF_SEPARATOR, 0, '');
  AppendMenu(GetSystemMenu(Handle, False), MF_STRING, AboutMenuItem,
    Pchar(UTF8ToWinCP('DCL '+GetDCLMessageString(msVersion)+' : '+DCLVersion)));
  {$ENDIF}
end;

procedure TProtectionForm.sbCopyKeyClick(Sender: TObject);
begin
  Clipboard.AsText:=edProgramKey.Text;
end;

procedure TProtectionForm.ShowAbout;
begin
  FDCLMain.About;
end;

procedure TProtectionForm.btApplayClick(Sender: TObject);
begin
  if FProtectionEngine.ApplaySoftwareKey(edRegistrationKey.Text) then
  begin
    MessageDlg('Ok', 'Protection is ok!', mtInformation, [mbOK], 0);
    Close;
  end;
end;

end.

