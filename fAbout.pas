unit fAbout;
{$mode Delphi}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls;

type

  { TAboutForm }

  TAboutForm = class(TForm)
    Button1: TButton;
    GroupBox1: TGroupBox;
    Image1: TImage;
    Label1: TLabel;
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
  private

  public

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
  if Assigned(Button1) then
  begin
    Button1.Left:=(Width-Button1.Width) div 2;
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

