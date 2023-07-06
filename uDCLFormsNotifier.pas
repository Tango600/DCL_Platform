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
begin

end;

procedure TDCLFormsNotifier.NotifyForm(Form: TDCLForm;
  Action: TFormsNotifyAction);
begin
  Form.RefreshForm;
end;

end.

