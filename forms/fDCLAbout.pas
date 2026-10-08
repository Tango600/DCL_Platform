unit fDCLAbout;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, Menus, uDCLDBConnector, uIDCLMain;

type

  { TAboutForm }

  TAboutForm = class(TForm)
    ButtonOK: TButton;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    imgNoMessages: TImage;
    ImageLogo: TImage;
    imgNoCheckSign: TImage;
    imgNoConfig: TImage;
    imgProtectionOn: TImage;
    Label1: TLabel;
    lbIniFile: TLabel;
    lbProtectionKey: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label9: TLabel;
    lbBuildDate: TLabel;
    lbBuildType: TLabel;
    lbCompillerName: TLabel;
    lbConfigVersion: TLabel;
    lbConfigVersionText: TLabel;
    lbDBLib: TLabel;
    lbDBLibVersion: TLabel;
    lbProduct: TLabel;
    lbProductName: TLabel;
    lbVersion: TLabel;
    lbPackagesList: TListBox;
    memConfigInfo: TMemo;
    MenuItem1: TMenuItem;
    miCopy: TMenuItem;
    PageControl1: TPageControl;
    FeaturesIconsPanel: TPanel;
    pnProtectionStatus: TPanel;
    pmPackages: TPopupMenu;
    pmProtectionInfo: TPopupMenu;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    procedure FormCreate(Sender: TObject);
    procedure ImageLogoClick(Sender: TObject);

    constructor Create(Owner: TComponent; IDCLMain: IDCLMain); overload;
    procedure MenuItem1Click(Sender: TObject);
    procedure miCopyClick(Sender: TObject);
  private
    LogoClickCount: Integer;
    FIDCLMain: IDCLMain;
    FDBConnector: TDCLDBConnector;

    function GetConfigInfo: String;
    function GetConfigVersion: String;
  end;

implementation

uses
  ClipBrd,
  uDCLConst, uDCLVersion, fDCLProtectionForm, uDCLData, uDCLScriptsPackage,
  uDCLGlobalVariables;

{$R *.lfm}

{ TAboutForm }

procedure TAboutForm.ImageLogoClick(Sender: TObject);
begin
  Inc(LogoClickCount);

  if LogoClickCount>=4 then
  begin
    ImageLogo.Hint:='Скоро всё будет хорошо!';
    ImageLogo.ShowHint:=True;

    ButtonOK.Hint:='Скоро всё будет хорошо!';
    ButtonOK.ShowHint:=True;
  end;
end;

constructor TAboutForm.Create(Owner: TComponent; IDCLMain: IDCLMain);
var
  pi: TPackageInfo;
begin
  inherited Create(Owner);
  FIDCLMain:=IDCLMain;
  FDBConnector:=IDCLMain.GetDBConnector;

  memConfigInfo.Text:=GetConfigInfo;
  lbConfigVersion.Caption:=GetConfigVersion;

  lbPackagesList.Clear;
  for pi in FIDCLMain.GetPackages do
  begin
    lbPackagesList.Items.Append(pi.Name+' ('+pi.Hash+')');
  end;
  {$IFDEF PROTECTION}
  imgProtectionOn.Visible:=True;
  pnProtectionStatus.Visible:=True;
  lbProtectionKey.Caption:=IDCLMain.GetProtectionEngine.GetProtectionKey;
  {$ENDIF}
  {$IFDEF ALLOWNODCL}
  imgNoConfig.Visible:=True;
  {$ENDIF}
  {$IFDEF NOCHECKSIGN}
  imgNoCheckSign.Visible:=True;
  {$ENDIF}
  {$IFDEF NODCLMESSAGES}
  imgNoMessages.Visible:=True;
  {$ENDIF}
end;

procedure TAboutForm.MenuItem1Click(Sender: TObject);
var
  ProtectionForm: TProtectionForm;
begin
  ProtectionForm:=TProtectionForm.Create(Application, FIDCLMain, True);
  ProtectionForm.ShowModal;
end;

procedure TAboutForm.miCopyClick(Sender: TObject);
begin
  Clipboard.AsText:=lbPackagesList.GetSelectedText;
end;

function TAboutForm.GetConfigInfo: String;
var
  Script: TDCLScript;
begin
  Result:='';
  Script:=FIDCLMain.GetScriptByIdent(60000, True);

  if Assigned(Script) then
  begin
    Result:=Script.ScriptText.Text;
  end;
end;

function TAboutForm.GetConfigVersion: String;
var
  Script: TDCLScript;
begin
  Result:='';
  Script:=FIDCLMain.GetScriptByIdent(60001, True);

  if Assigned(Script) then
  begin
    Result:=Script.ScriptText.Text;
  end;
end;

procedure TAboutForm.FormCreate(Sender: TObject);
begin
  lbVersion.Caption:=DCLVersion;
  lbDBLib.Caption:=DBEngineType;
  lbDBLibVersion.Caption:=AccessLibVersion;
  lbIniFile.Caption:=GPT.IniFileName;

  lbCompillerName.Caption:=InternalAppNameSuffix{$IFDEF FPC}+' '+fpcVersion{$ENDIF};
  lbBuildType.Caption:=TargetOS+'_'+TargetCPU;
  {$IFDEF FPC}
  lbBuildDate.Caption:=AppBuildDate;
  {$ENDIF}
end;

end.

