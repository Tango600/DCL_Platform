unit fAbout;
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
    ImageLogo: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
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
    miCopy: TMenuItem;
    PageControl1: TPageControl;
    pmPackages: TPopupMenu;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure ImageLogoClick(Sender: TObject);

    constructor Create(Owner: TComponent; IDCLMain: IDCLMain); overload;
    procedure miCopyClick(Sender: TObject);
  private
    LogoClickCount: Integer;
    FIDCLMain: IDCLMain;
    FDBConnector: TDCLDBConnector;

    function GetConfigInfo: String;
    function GetConfigVersion: String;
  end;

var
  AboutForm: TAboutForm;

implementation

uses
  ClipBrd,
  uDCLTypes, uDCLConst, uDCLVersion, uDCLDBStructure, uDCLScriptsPackage;

{$R *.lfm}

{ TAboutForm }

procedure TAboutForm.FormResize(Sender: TObject);
begin
  if Assigned(ButtonOK) then
  begin
    ButtonOK.Left:=(Width-ButtonOK.Width) div 2;
  end;
end;

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
    lbPackagesList.Items.Append(pi.Name+' ('+pi.Sign+')');
  end;
end;

procedure TAboutForm.miCopyClick(Sender: TObject);
begin
  Clipboard.AsText:=lbPackagesList.GetSelectedText;
end;

function TAboutForm.GetConfigInfo: String;
var
  Q: TDCLDialogQuery;
begin
  Result:='';
  if Assigned(FDBConnector) then
  begin
    Q:=TDCLDialogQuery.Create(Self);
    FDBConnector.SetConnector(Q);
    Q.SQL.Text:='select '+ScriptField+' from '+DCLTable+' where '+IdentifyField+'=60000';
    Q.Open;
    Result:=Q.Fields[0].AsString;
    Q.Close;

    FreeAndNil(Q);
  end;
end;

function TAboutForm.GetConfigVersion: String;
var
  Q: TDCLDialogQuery;
begin
  Result:='1';
  if Assigned(FDBConnector) then
  begin
    Q:=TDCLDialogQuery.Create(Self);
    FDBConnector.SetConnector(Q);
    Q.SQL.Text:='select '+ScriptField+' from '+DCLTable+' where '+IdentifyField+'=60001';
    Q.Open;
    Result:=Q.Fields[0].AsString;
    Q.Close;

    FreeAndNil(Q);
  end;
end;

procedure TAboutForm.FormCreate(Sender: TObject);
begin
  lbVersion.Caption:=DCLVersion;
  lbDBLib.Caption:=DBEngineType;
  lbDBLibVersion.Caption:=AccessLibVersion;

  lbCompillerName.Caption:=InternalAppNameSuffix{$IFDEF FPC}+' '+fpcVersion{$ENDIF};
  lbBuildType.Caption:=TargetOS+'_'+TargetCPU;
  {$IFDEF FPC}
  lbBuildDate.Caption:=AppBuildDate;
  {$ENDIF}
end;

end.

