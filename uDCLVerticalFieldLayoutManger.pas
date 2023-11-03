unit uDCLVerticalFieldLayoutManger;
{$mode Delphi}

interface

uses
  Classes, SysUtils, Controls, Generics.Collections,
  uDCLBaseLayoutManger, uDCLMeasurements, uDCLConst, uDCLField, uDCLData;

type

  { TDCLVerticalFieldLayoutManger }

  TDCLVerticalFieldLayoutManger<T: TDCLField>=class(TDCLBaseLayoutManger<T>)
  private
    FMaxColWidth, FMaxLabelWidth, FCurrWidth, FCurrHeight, FLabelHeight: Integer;
  protected
    procedure ProcessControlFromList(Control: T); override;
    procedure ProcessBeforeNextControl(CurrentControl: T); override;
  public
    procedure InitMeasurements; override;
  end;

implementation

procedure TDCLVerticalFieldLayoutManger<T>.InitMeasurements;
begin
  FLeftDirect:=1;
  FTopDirect:=1;

  FTop:=ButtonsTop;
  FLeft:=BeginStepLeft;
end;

procedure TDCLVerticalFieldLayoutManger<T>.ProcessControlFromList(Control: T);
var
  cbw, i, lbw: Integer;
  cb: TContextFieldButton;
begin
  FLabelHeight:=18;
  if Assigned(Control.FLabel) then
  begin
    Control.FLabel.Top:=FTop;
    Control.FLabel.Left:=FLeft;
    lbw:=Control.FLabel.Width;
    if FMaxLabelWidth<lbw then
      FMaxLabelWidth:=lbw;

    FLabelHeight:=Control.FLabel.Height+LabelTopInterval;
    Inc(FTop, FLabelHeight);
  end;

  if Assigned(Control.DCLEditComponent) then
  if Assigned(Control.DCLEditComponent.Control) then
  begin
    FCurrHeight:=Control.DCLEditComponent.Control.Height;
    FCurrWidth:=Control.DCLEditComponent.Control.Width;
    if FMaxColWidth<FCurrWidth then
    begin
      FMaxColWidth:=FCurrWidth;
    end;

    if Control.ContextButtons.Count>0 then
    begin
      cbw:=FLeft+Control.DCLEditComponent.Control.Width+ContextButtonInterval;
      for i:=1 to Control.ContextButtons.Count do
      begin
        cb:=Control.ContextButtons[i-1];
        cb.Button.Top:=FTop;
        cb.Button.Left:=cbw;
        if FCurrHeight<100 then
          cb.Button.Height:=FCurrHeight;
        inc(cbw, cb.Button.Width+ContextButtonInterval);
      end;
    end;

    Control.DCLEditComponent.Control.Top:=FTop;
    Control.DCLEditComponent.Control.Left:=FLeft;

    Inc(FTop, FCurrHeight+LabelTopInterval);
  end;
end;

procedure TDCLVerticalFieldLayoutManger<T>.ProcessBeforeNextControl(CurrentControl: T);
begin
  FCurrHeight:=0;
  if Assigned(CurrentControl.DCLEditComponent) and Assigned(CurrentControl.DCLEditComponent.Control) then
  begin
    FCurrHeight:=CurrentControl.DCLEditComponent.Control.Height;
  end;

  if FParent.Height<FTop+ButtonsTop+FLabelHeight+FCurrHeight+LabelTopInterval then
  begin
    if FMaxColWidth>FMaxLabelWidth then
      Inc(FLeft, FMaxColWidth+FieldsStepLeft)
    else
      Inc(FLeft, FMaxLabelWidth+FieldsStepLeft);

    FMaxColWidth:=0;
    FMaxLabelWidth:=0;
    FTop:=ButtonsTop;
  end;
end;

end.

