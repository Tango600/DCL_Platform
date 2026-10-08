unit fDCLLoginForm;
{$mode Delphi}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  uDCLConst, uDCLDBConnector, uDCLDBAwareTypes, uDCLDBStructure;

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
    Tryes: Byte;
    FDBConnector: TDCLDBConnector;
    FQuery: TDCLDialogQuery;

    procedure FillUsersList;
    function CheckPassword: Boolean;
  public
    constructor Create(const DBConnector: TDCLDBConnector); overload;
  end;

implementation

uses
  fChangePasswordForm, uDCLGlobalVariables, uDCLUtils;

{$R *.lfm}

{ TLoginForm }

procedure TLoginForm.btLoginClick(Sender: TObject);
begin
  ModalResult:=mrNone;

  if CheckPassword then
  begin
    ModalResult:=mrOK;

    FQuery:=TDCLDialogQuery.Create(Self);
    FDBConnector.SetConnector(FQuery);
    FQuery.Params.Clear;
    FQuery.SQL.Text:='select '+UserIDField+', '+UserAdminField+' from '+UsersTable+' where lower('+UserNameField+')=lower(:User)';
    FQuery.Params.ParamByName('User').AsString:=cbLogin.Text;
    FQuery.Open;
    FQuery.First;
    GPT.UserID:=FQuery.FieldByName(UserIDField).AsString;
    GPT.AccessLevel:=TranslateDigitToUserLevel(FQuery.FieldByName(UserAdminField).AsInteger);
    FQuery.Close;
    FreeAndNil(FQuery);
  end
  else
  begin
    Inc(Tryes);
    if Tryes>3 then
      ModalResult:=mrClose;
  end;
end;

procedure TLoginForm.FormCreate(Sender: TObject);
begin
  Tryes:=0;
end;

procedure TLoginForm.FormShow(Sender: TObject);
begin
  FillUsersList;
end;

procedure TLoginForm.FillUsersList;
begin
  FQuery:=TDCLDialogQuery.Create(Self);
  FDBConnector.SetConnector(FQuery);
  FQuery.SQL.Text:='select * from '+UsersTable+' where '+ShowInListField+' is not null';
  FQuery.Open;
  while not FQuery.EOF do
  begin
    cbLogin.Items.Append(FQuery.FieldByName(UserNameField).AsString);

    FQuery.Next;
  end;
  FQuery.Close;

  FreeAndNil(FQuery);
end;

function TLoginForm.CheckPassword: Boolean;
begin
  FQuery:=TDCLDialogQuery.Create(Self);
  FDBConnector.SetConnector(FQuery);
  FQuery.Params.Clear;
  FQuery.SQL.Text:='select '+UserPassField+' from '+UsersTable+' where lower('+UserNameField+')=lower(:User)';
  FQuery.Params.ParamByName('User').AsString:=cbLogin.Text;
  FQuery.Open;
  FQuery.First;
  Result:=not FQuery.IsEmpty;
  if Result then
    Result:=(edPassword.Text=FQuery.FieldByName(UserPassField).AsString);

  FQuery.Close;
  FreeAndNil(FQuery);
end;

constructor TLoginForm.Create(const DBConnector: TDCLDBConnector);
begin
  FDBConnector:=DBConnector;
  inherited Create(Application);
end;

procedure TLoginForm.btCancelClick(Sender: TObject);
begin
  ModalResult:=mrClose;
end;

procedure TLoginForm.btChangePassClick(Sender: TObject);
var
  PassForm: TFormChangePassword;
begin
  if CheckPassword then
  begin
    PassForm:=TFormChangePassword.Create(Self);
    if PassForm.ShowModal=mrOk then
    begin
      if PassForm.edPassword1.Text=PassForm.edPassword2.Text then
      begin
        FQuery:=TDCLDialogQuery.Create(Self);
        FDBConnector.SetConnector(FQuery);
        FQuery.Params.Clear;
        FQuery.SQL.Text:='update '+UsersTable+' set '+UserPassField+'=:pass where lower('+UserNameField+')=lower(:User)';
        FQuery.Params.ParamByName('User').AsString:=cbLogin.Text;
        FQuery.Params.ParamByName('pass').AsString:=PassForm.edPassword1.Text;
        FQuery.ExecSQL;
        FreeAndNil(FQuery);
      end;
      PassForm.Release;
    end;
  end;
end;

end.

