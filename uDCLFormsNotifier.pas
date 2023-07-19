unit uDCLFormsNotifier;
{$mode Delphi}

interface

uses
  Classes, SysUtils, Forms, Generics.Collections,
  uDCLData, uDCLConst, uDCLForm, uDCLGrid;

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
  fnaRefresh: Form.RefreshForm;
  fnaClose: Form.Close;
  fnaHide: Form.Hide;
  fnaShow: begin
    if not Form.Showing then
      Form.Show;
    Form.SetFocus;
    end;
  //fnaStopAutoRefresh, fnaStartAutoRefresh, fnaPauseAutoRefresh, fnaResumeAutoRefresh
  end;
end;

end.

