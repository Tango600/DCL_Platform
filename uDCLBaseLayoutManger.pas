unit uDCLBaseLayoutManger;
{$mode Delphi}

interface

uses
  Classes, SysUtils, Controls, Generics.Collections;

type

  { TDCLBaseLayoutManger }

  TDCLBaseLayoutManger<T>=class
  protected
    FControls: TList<T>;
    FParent: TWinControl;
    FParentResizeEvent: TNotifyEvent;
    FTop, FLeft, FStepTop: Integer;
    FLeftDirect: Integer;
    FTopDirect: Integer;

    procedure OnResize(Sender: TObject);

    procedure ProcessControls;
    procedure ProcessControlFromList(Control: T); virtual; abstract;
    procedure ProcessBeforeNextControl; virtual;
    procedure ProcessPostNextControl; virtual;
  public
    constructor Create(Parent: TWinControl; Controls: TList<T>);

    procedure InitMeasurements; virtual; abstract;
  end;


implementation

{ TDCLBaseLayoutManger }

procedure TDCLBaseLayoutManger<T>.OnResize(Sender: TObject);
begin
  if Assigned(FParentResizeEvent) then
  begin
    FParentResizeEvent(FParent);
  end;
  ProcessControls;
end;

procedure TDCLBaseLayoutManger<T>.ProcessControls;
var
  C: T;
begin
  InitMeasurements;
  if Assigned(FControls) then
  begin
    for C in FControls do
    begin
      ProcessBeforeNextControl;
      ProcessControlFromList(C);
      ProcessPostNextControl;
    end;
  end;
end;

procedure TDCLBaseLayoutManger<T>.ProcessBeforeNextControl;
begin
end;

procedure TDCLBaseLayoutManger<T>.ProcessPostNextControl;
begin
end;

constructor TDCLBaseLayoutManger<T>.Create(Parent: TWinControl; Controls: TList<T>);
begin
  FControls:=Controls;
  FParent:=Parent;
  FParentResizeEvent:=FParent.OnResize;
  FParent.OnResize:=OnResize;
end;

end.

