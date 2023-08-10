unit fAbout;
{$mode Delphi}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls;

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
    lbBuildDate: TLabel;
    lbBuildType: TLabel;
    lbCompillerName: TLabel;
    lbDBLibVersion: TLabel;
    lbDBLib: TLabel;
    lbProduct: TLabel;
    lbProductName: TLabel;
    lbVersion: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure ImageLogoClick(Sender: TObject);
  private
    LogoClickCount: Integer;
    FConfigInfo, FConfigVersion: String;
  public

    property ConfigInfo: String read FConfigInfo write FConfigInfo;
    property ConfigVersion: String read FConfigVersion write FConfigVersion;
  end;

var
  AboutForm: TAboutForm;

implementation

uses
  uDCLConst, uDCLVersion;

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

procedure TAboutForm.FormCreate(Sender: TObject);
begin
  lbVersion.Caption:=DCLVersion;
  lbDBLib.Caption:=DBEngineType;
  lbDBLibVersion.Caption:=AccessLibVersion;

  lbCompillerName.Caption:=InternalAppNameSuffix+' '+fpcVersion;
  lbBuildType.Caption:=TargetOS+'_'+TargetCPU;
  lbBuildDate.Caption:=AppBuildDate;
end;

end.

