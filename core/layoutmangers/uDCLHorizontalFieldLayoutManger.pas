unit uDCLHorizontalFieldLayoutManger;
{$mode Delphi}

interface

uses
  Classes, SysUtils, Controls, Generics.Collections,
  uDCLBaseLayoutManger, uDCLMeasurements, uDCLConst, uDCLField, uDCLData;

type

  { TDCLHorizontalFieldLayoutManger }

  TDCLHorizontalFieldLayoutManger<T: TDCLField>=class(TDCLBaseLayoutManger<T>)
  private
    FMaxColHeight, FCurrWidth, FCurrHeight, FLabelHeight: Integer;
  protected
    procedure ProcessControlFromList(Control: T); override;
    procedure ProcessBeforeNextControl(CurrentControl: T); override;
  public
    procedure InitMeasurements; override;
  end;

implementation

procedure TDCLHorizontalFieldLayoutManger<T>.InitMeasurements;
begin
  FLeftDirect:=1;
  FTopDirect:=1;

  FTop:=ButtonsTop;
  FLeft:=BeginStepLeft;
end;

procedure TDCLHorizontalFieldLayoutManger<T>.ProcessControlFromList(Control: T);
var
  cbw, i, maxWidth: Integer;
  cb: TContextFieldButton;
begin
  maxWidth:=0;
  FLabelHeight:=BeginStepTop;
  if Assigned(Control.FLabel) then
  begin
    Control.FLabel.Top:=FTop;
    Control.FLabel.Left:=FLeft;
    maxWidth:=Control.FLabel.Width;

    FLabelHeight:=Control.FLabel.Height+LabelTopInterval;
  end;

  FCurrWidth:=0;
  if Assigned(Control.DCLEditComponent) then
  if Assigned(Control.DCLEditComponent.Control) then
  begin
    FCurrHeight:=Control.DCLEditComponent.Control.Height;
    FCurrWidth:=Control.DCLEditComponent.Control.Width;
    if FMaxColHeight<FCurrHeight+FLabelHeight then
    begin
      FMaxColHeight:=FCurrHeight+FLabelHeight;
    end;

    if maxWidth<FCurrWidth then
      maxWidth:=FCurrWidth;

    if Control.ContextButtons.Count>0 then
    begin
      cbw:=FLeft+Control.DCLEditComponent.Control.Width+ContextButtonInterval;
      for i:=1 to Control.ContextButtons.Count do
      begin
        cb:=Control.ContextButtons[i-1];
        cb.Button.Top:=FTop+FLabelHeight;
        cb.Button.Left:=cbw;
        if FCurrHeight<100 then
          cb.Button.Height:=FCurrHeight;
        inc(cbw, cb.Button.Width+ContextButtonInterval);
      end;
      Inc(FCurrWidth, cbw);
    end;

    Control.DCLEditComponent.Control.Top:=FTop+FLabelHeight;
    Control.DCLEditComponent.Control.Left:=FLeft;

    Inc(FLeft, maxWidth);
    Inc(FLeft, BeginStepLeft);
  end;
end;

procedure TDCLHorizontalFieldLayoutManger<T>.ProcessBeforeNextControl(CurrentControl: T);
begin
  if FParent.Width<FLeft+FieldsStepLeft+CurrentControl.Width then
  begin
    Inc(FTop, FMaxColHeight+LabelTopInterval);

    FMaxColHeight:=0;
    FLeft:=BeginStepLeft;
  end;
end;

end.

