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
    procedure ProcessPostNextControl; override;
  public
    procedure InitMeasurements; override;

  end;

implementation

{ TDCLButtonLayoutManger }

procedure TDCLButtonLayoutManger<T>.InitMeasurements;
begin
  FLeftDirect:=1;
  FTopDirect:=1;

  FStepTop:=ButtonsInterval+ButtonHeight;

  FTop:=ButtonsTop;
  FLeft:=BeginStepLeft;
end;

procedure TDCLButtonLayoutManger<T>.ProcessControlFromList(Control: T);
begin
  if Assigned(Control.Button) then
  begin
    //Control.Button.Top:=FTop;
    //Control.Button.Left:=FLeft;
    //Control.Button.Height:=ButtonHeight;

    Inc(FLeft, (Control.Width+ButtonsInterval)*FLeftDirect);
  end;
end;

procedure TDCLButtonLayoutManger<T>.ProcessPostNextControl;
var
  h: Integer;
begin
  if FParent.Width<FLeft+FullButtonWidth+ButtonsInterval then
  begin
    FLeft:=BeginStepLeft;
    Inc(FTop, FStepTop*FTopDirect);
  end;

  h:=FTop+ButtonHeight+ButtonsTop*2;
  FParent.Height:=h;
end;

end.

