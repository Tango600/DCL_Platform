unit fDCLLoginForm;
{$mode Delphi}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  uIAuthForm;

type

  { TLoginForm }

  TLoginForm = class(TForm, IAuthForm)
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
    function GetFormResult: RAuthData;
    function GetLogin: String;
    function GetPassword: String;
  public
    constructor Create(var UsersList: TStringList); overload;

    function ShowAuthForm: RAuthData;

    property Login: String read GetLogin;
    property Password: String read GetPassword;
    property FormResult: RAuthData read GetFormResult;
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
  cbLogin.SetFocus;
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

function TLoginForm.GetFormResult: RAuthData;
begin
  if FIsChange then
    Result.Accept:=afrChangePassword
  else
    Result.Accept:=afrAccept;
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

function TLoginForm.ShowAuthForm: RAuthData;
begin
  Result.Clear;
  if ShowModal=mrOK then
  begin
    Result.Login:=cbLogin.Text;
    Result.Password:=edPassword.Text;
    Result.Accept:=afrAccept;
  end;
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

