unit uDCLButtonLayoutManger;
{$mode Delphi}

interface

uses
  Classes, SysUtils, Controls,
  uDCLBaseLayoutManger, uDCLMeasurements;

type

  { TDCLButtonLayoutManger }

  TDCLButtonLayoutManger<T>=class(TDCLBaseLayoutManger<T>)
  private

  protected
    procedure ProcessControlFromList(Control: T); override;
    procedure ProcessBeforeNextControl(CurrentControl: T); override;
  public
    procedure InitMeasurements; override;

  end;

implementation

{ TDCLButtonLayoutManger }

procedure TDCLButtonLayoutManger<T>.InitMeasurements;
begin
  FTop:=ButtonsTop;
end;

procedure TDCLButtonLayoutManger<T>.ProcessControlFromList(Control: T);
begin
end;

procedure TDCLButtonLayoutManger<T>.ProcessBeforeNextControl(CurrentControl: T);
var
  h: Integer;
begin
  if FParent.Width<FLeft+CurrentControl.Width+ButtonsInterval then
  begin
    Inc(FTop, (ButtonsInterval+CurrentControl.Button.Height)*FTopDirect);
  end;

  h:=FTop+CurrentControl.Button.Height+ButtonsTop;
  FParent.Height:=h;
end;

end.

