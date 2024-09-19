unit fChangePasswordForm;
{$mode Delphi}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls;

type

  { TFormChangePassword }

  TFormChangePassword = class(TForm)
    btOk: TButton;
    chbShowPasswords: TCheckBox;
    edPassword1: TEdit;
    edPassword2: TEdit;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Panel1: TPanel;
    procedure btOkClick(Sender: TObject);
    procedure chbShowPasswordsChange(Sender: TObject);
  private

  public

  end;

implementation

{$R *.lfm}

{ TFormChangePassword }

procedure TFormChangePassword.btOkClick(Sender: TObject);
begin
  if edPassword1.Text=edPassword2.Text then
  begin
    ModalResult:=mrOk;
  end
  else
  begin
    ShowMessage('Пароли не совпадают!');
  end;
end;

procedure TFormChangePassword.chbShowPasswordsChange(Sender: TObject);
begin
  if edPassword1.PasswordChar=#0 then
  begin
    edPassword1.PasswordChar:='#';
    edPassword2.PasswordChar:='#';
  end
  else
  begin
    edPassword1.PasswordChar:=#0;
    edPassword2.PasswordChar:=#0;
  end;
end;

end.

