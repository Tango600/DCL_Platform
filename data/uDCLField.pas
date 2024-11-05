unit uDCLField;
{$mode Delphi}

interface

uses
  Classes, SysUtils, StdCtrls, Generics.Collections,
  uDCLFieldData, uDCLData, uDCLTypes, uDCLConst;

type
  { TDCLField }

  TDCLField=class(TDCLFieldData)
  public
    FLabel: TDialogLabel;
    StepLeft: Integer;
    LookupData: TDCLLookup;
    DCLEditComponent: TDCLEdit;
    ContextButtons: TList<TContextFieldButton>;

    constructor Create;
  end;


implementation

{ TDCLField }

constructor TDCLField.Create;
begin
  inherited Create;
  ContextButtons:=TList<TContextFieldButton>.Create;
end;

end.

