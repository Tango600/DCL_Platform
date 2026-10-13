unit fDCLLoginForm;
{$mode Delphi}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls;

type

  { TLoginForm }

  TLoginForm = class(TForm)
    btLogin: TButton;
    btCancel: TButton;
    btChangePass: TButton;
    cbLogin: TComboBox;
    edPassword: TEdit;
    GroupBox1: TGroupBox;
    ImageLogo: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Panel1: TPanel;
    procedure btCancelClick(Sender: TObject);
    procedure btChangePassClick(Sender: TObject);
    procedure btLoginClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FUsersList: TStringList;
    FIsChange: Boolean;

    procedure FillUsersList;
    function GetIsChange: Boolean;
    function GetLogin: String;
    function GetPassword: String;
  public
    constructor Create(var UsersList: TStringList); overload;

    property Login: String read GetLogin;
    property Password: String read GetPassword;
    property IsChange: Boolean read GetIsChange;
  end;

implementation

{$R *.lfm}

{ TLoginForm }

procedure TLoginForm.btLoginClick(Sender: TObject);
begin
  FIsChange:=False;
  ModalResult:=mrOK;
end;

procedure TLoginForm.FormCreate(Sender: TObject);
begin
  FillUsersList;
  FIsChange:=False;
end;

procedure TLoginForm.FormShow(Sender: TObject);
begin
  FIsChange:=False;
  edPassword.Clear;
end;

procedure TLoginForm.FillUsersList;
var
  u: String;
begin
  cbLogin.Clear;
  for u in FUsersList do
  begin
    cbLogin.Items.Append(u);
  end;
  if cbLogin.Items.Count=1 then
    cbLogin.Text:=cbLogin.Items[0];
end;

function TLoginForm.GetIsChange: Boolean;
begin
  Result:=FIsChange;
end;

function TLoginForm.GetLogin: String;
begin
  Result:=cbLogin.Text;
end;

function TLoginForm.GetPassword: String;
begin
  Result:=edPassword.Text;
end;

constructor TLoginForm.Create(var UsersList: TStringList);
begin
  inherited Create(Application);
  FUsersList:=UsersList;
end;

procedure TLoginForm.btCancelClick(Sender: TObject);
begin
  FIsChange:=False;
  ModalResult:=mrClose;
end;

procedure TLoginForm.btChangePassClick(Sender: TObject);
begin
  FIsChange:=True;
  ModalResult:=mrOK;
end;

end.

