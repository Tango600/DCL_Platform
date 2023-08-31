unit fAbout;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  uDCLDBConnector;

type

  { TAboutForm }

  TAboutForm = class(TForm)
    ButtonOK: TButton;
    GroupBox1: TGroupBox;
    ImageLogo: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    lbConfigVersion: TLabel;
    lbConfigVersionText: TLabel;
    lbBuildDate: TLabel;
    lbBuildType: TLabel;
    lbCompillerName: TLabel;
    lbDBLibVersion: TLabel;
    lbDBLib: TLabel;
    lbProduct: TLabel;
    lbProductName: TLabel;
    lbVersion: TLabel;
    memConfigInfo: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure ImageLogoClick(Sender: TObject);

    constructor Create(Owner: TComponent; DBConnector: TDCLDBConnector); overload;
  private
    LogoClickCount: Integer;
    FDBConnector: TDCLDBConnector;

    function GetConfigInfo: String;
    function GetConfigVersion: String;
  end;

var
  AboutForm: TAboutForm;

implementation

uses
  uDCLTypes, uDCLConst, uDCLVersion, uDCLDBStructure;

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

constructor TAboutForm.Create(Owner: TComponent; DBConnector: TDCLDBConnector);
begin
  inherited Create(Owner);
  FDBConnector:=DBConnector;

  memConfigInfo.Text:=GetConfigInfo;
  lbConfigVersion.Caption:=GetConfigVersion;
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

