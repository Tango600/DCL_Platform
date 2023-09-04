unit uDCLFormsNotifier;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils, Forms, Generics.Collections,
  uDCLData, uDCLConst, uDCLForm;

type

  { TDCLFormsNotifier }

  TDCLFormsNotifier=class
  private
    FForms: TList<TForm>;
  public
    constructor Create(Forms: TList<TForm>); overload;

    procedure NotifyForms(Action: TFormsNotifyAction);
    procedure NotifyForm(Form: TDCLForm; Action: TFormsNotifyAction);
  end;

implementation

{ TDCLFormsNotifier }

constructor TDCLFormsNotifier.Create(Forms: TList<TForm>);
begin
  FForms:=Forms;
end;

procedure TDCLFormsNotifier.NotifyForms(Action: TFormsNotifyAction);
var
  F: TForm;
begin
  for F in FForms do
  begin
    NotifyForm(F as TDCLForm, Action);
  end;
end;

procedure TDCLFormsNotifier.NotifyForm(Form: TDCLForm;
  Action: TFormsNotifyAction);
begin
  case Action of
  fnaMinimize: Form.WindowState:=wsMinimized;
  fnaMaximaze: Form.WindowState:=wsMaximized;
  fnaRefresh: Form.RefreshForm;
  fnaClose: Form.Close;
  fnaHide: Form.Hide;
  fnaShow: begin
    if not Form.Showing then
      Form.Show;
    Form.SetFocus;
    end;
  end;
end;

end.

