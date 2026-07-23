unit fDCLProtectionForm;
{$mode Delphi}

interface

uses
  {$IFDEF MSWINDOWS}
  Windows, Messages, LazUTF8,
  {$ENDIF}
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  Menus, ExtCtrls, ActnList, uIDCLProtectionEngine, uIDCLMain;

type

  { TProtectionForm }

  TProtectionForm = class(TForm)
    aExitByEsc: TAction;
    ActionList: TActionList;
    btApplay: TButton;
    edRegistrationKey: TEdit;
    edProgramKey: TEdit;
    ImageList1: TImageList;
    imKeyValid: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    lbExpire: TLabel;
    MainMenu1: TMainMenu;
    miAbout: TMenuItem;
    sbCopyKey: TSpeedButton;
    procedure aExitByEscExecute(Sender: TObject);
    procedure btApplayClick(Sender: TObject);
    procedure edRegistrationKeyChange(Sender: TObject);
    procedure edRegistrationKeyClick(Sender: TObject);
    procedure edRegistrationKeyExit(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure miAboutClick(Sender: TObject);
    procedure sbCopyKeyClick(Sender: TObject);
  private
    FDCLMain: IDCLMain;
    FProtectionEngine: IDCLProtectionEngine;

    procedure ShowAbout;
    {$IFDEF MSWINDOWS}
    procedure WMSysCommand(var message: TWMSysCommand); message WM_SysCommand;
    {$ENDIF}
  public
    constructor Create(AOwner: TComponent; const DCLMain: IDCLMain; FromAbout: Boolean); overload;

  end;

implementation

uses
  Clipbrd, {$IFDEF LINUX}gtk2, gdk2,{$ENDIF}
  uDCLConst, uDCLMultiLang, uDCLVersion, uKeyData;

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

constructor TProtectionForm.Create(AOwner: TComponent; const DCLMain: IDCLMain; FromAbout: Boolean);
var
  Key: TKeyData;
begin
  inherited Create(AOwner);
  FDCLMain:=DCLMain;
  FProtectionEngine:=DCLMain.GetProtectionEngine;

  miAbout.Visible:=not FromAbout;
  lbExpire.Caption:='-';
  edProgramKey.Text:=FProtectionEngine.GetProtectionKey;
  Key:=FProtectionEngine.GetKeyData;
  if Key.IsValid then
  begin
    imKeyValid.ImageIndex:=0;
    edRegistrationKey.TextHint:='<ключ введён>';
    if Key.RemainDays>0 then
      lbExpire.Caption:=IntToStr(Key.RemainDays)+' ('+Key.KeyType+')'
    else
      lbExpire.Caption:='Бессрочно';
  end
  else
  begin
    imKeyValid.ImageIndex:=1;
    edRegistrationKey.TextHint:='<введите ключ защиты>';
  end;
end;

procedure TProtectionForm.edRegistrationKeyChange(Sender: TObject);
begin
  if FProtectionEngine.ValidateKey(edRegistrationKey.Text) then
    imKeyValid.ImageIndex:=0
  else
    imKeyValid.ImageIndex:=1;
end;

procedure TProtectionForm.edRegistrationKeyClick(Sender: TObject);
begin
  if not FProtectionEngine.ValidateKey(edRegistrationKey.Text) then
    edRegistrationKey.Clear;
end;

procedure TProtectionForm.edRegistrationKeyExit(Sender: TObject);
var
  Key: TKeyData;
begin
  Key:=FProtectionEngine.GetKeyData;
  if Key.IsValid then
    edRegistrationKey.TextHint:='<ключ введён>'
  else
    edRegistrationKey.TextHint:='<введите ключ защиты>';

  if (Key.IsValid and (edRegistrationKey.Text='')) or FProtectionEngine.ValidateKey(edRegistrationKey.Text) then
  begin
    imKeyValid.ImageIndex:=0;
  end
  else
  begin
    imKeyValid.ImageIndex:=1;
  end;

  if not FProtectionEngine.ValidateKey(edRegistrationKey.Text) then
    edRegistrationKey.Clear;
end;

procedure TProtectionForm.FormShow(Sender: TObject);
begin
  {$IFDEF MSWINDOWS}
  AppendMenu(GetSystemMenu(Handle, False), MF_SEPARATOR, 0, '');
  AppendMenu(GetSystemMenu(Handle, False), MF_STRING, AboutMenuItem,
    Pchar(UTF8ToWinCP('DCL '+GetDCLMessageString(msVersion)+' : '+DCLVersion)));
  {$ENDIF}
  btApplay.SetFocus;
end;

procedure TProtectionForm.miAboutClick(Sender: TObject);
begin
  ShowAbout;
end;

procedure TProtectionForm.sbCopyKeyClick(Sender: TObject);
{$IFDEF LINUX}
var
  c: PGtkClipboard;
  t: String;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  Clipboard.AsText:=edProgramKey.Text;
  {$ENDIF}
  {$IFDEF LINUX}
  c:=gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
  t:=edProgramKey.Text;
  gtk_clipboard_set_text(c, PChar(t), Length(t));
  gtk_clipboard_store(c);
  {$ENDIF}
end;

procedure TProtectionForm.ShowAbout;
begin
  FDCLMain.About;
end;

procedure TProtectionForm.btApplayClick(Sender: TObject);
var
  Key: TKeyData;
  Answer: Boolean;
begin
  Key:=FProtectionEngine.GetKeyData;
  Answer:=True;
  if Key.IsValid then
    Answer:=MessageDlg('Заменить существующий действующий ключ?', mtConfirmation, mbOKCancel, 0)=1;

  if Answer then
  begin
    if FProtectionEngine.ApplaySoftwareKey(edRegistrationKey.Text) then
    begin
      imKeyValid.ImageIndex:=0;
      MessageDlg('Ok', 'Ключ защиты принят!', mtInformation, [mbOK], 0);
      Close;
    end
    else
    begin
      MessageDlg('Ключ защиты', 'Ключ защиты не принят!', mtError, [mbOK], 0);
      edRegistrationKey.Clear;
    end;
  end;
end;

procedure TProtectionForm.aExitByEscExecute(Sender: TObject);
begin
  Close;
end;

end.

