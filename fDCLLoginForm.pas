unit fDCLLoginForm;

{$mode Delphi}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  uDCLConst, uDCLDBConnector, uDCLTypes, uDCLDBStructure;

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
    procedure btLoginClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);

  private
    Tryes: Byte;
    FDBConnector: TDCLDBConnector;
    FQuery: TDCLDialogQuery;

    procedure FillUsersList;
  public
    constructor Create(DBConnector: TDCLDBConnector); overload;

    property DBConnector: TDCLDBConnector read FDBConnector write FDBConnector;
  end;

implementation

{$R *.lfm}

{ TLoginForm }

procedure TLoginForm.btLoginClick(Sender: TObject);
var
  ok:Boolean;
begin
  ModalResult:=mrNone;
  FQuery:=TDCLDialogQuery.Create(Self);
  FDBConnector.SetConnector(FQuery);
  FQuery.Params.Clear;
  FQuery.SQL.Text:='select '+UserPassField+' from '+UsersTable+' where lower('+UserNameField+')=lower(:User)';
  FQuery.Params.ParamByName('User').AsString:=cbLogin.Text;
  FQuery.Open;
  FQuery.First;
  ok:=(edPassword.Text=FQuery.FieldByName(UserPassField).AsString) and not FQuery.IsEmpty;
  FQuery.Close;
  FreeAndNil(FQuery);

  if ok then
    ModalResult:=mrOK
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
  FQuery.SQL.Text:='select * from '+UsersTable+' where SHOWINLIST is not null';
  FQuery.Open;
  while not FQuery.EOF do
  begin
    cbLogin.Items.Append(FQuery.FieldByName(UserNameField).AsString);

    FQuery.Next;
  end;
  FQuery.Close;

  FreeAndNil(FQuery);
end;

constructor TLoginForm.Create(DBConnector: TDCLDBConnector);
begin
  FDBConnector:=DBConnector;
  inherited Create(Application);
end;

procedure TLoginForm.btCancelClick(Sender: TObject);
begin
  ModalResult:=mrClose;
end;

end.

