unit uDCLField;
{$mode Delphi}

interface

uses
  Classes, SysUtils, StdCtrls, Generics.Collections,
  uDCLData, uDCLTypes, uDCLConst;

type
  { TDCLField }

  TDCLField=class
  public
    FLabel: TDialogLabel;
    CharCase: TEditCharCase;
    FieldName, Caption, Hint, Variable, CheckValue, UnCheckValue,
      FullFieldName, FirstFieldsLine, NotInputValue: String;
    PasswordChar: Char;
    ReadOnly, NoDataField, UseIndex, Enabled, RequireValue: Boolean;
    Width, Height, StepLeft: Integer;
    DataFieldType: TDCLDataFieldKind;
    FieldTypeFormat: TFieldFormat;
    LookupData: TDCLLookup;
    DCLEditComponent: TDCLEdit;
    ContextButtons: TList<TContextFieldButton>;

    constructor Create;
  end;


implementation

{ TDCLField }

constructor TDCLField.Create;
begin
  ContextButtons:=TList<TContextFieldButton>.Create;

  Enabled:=True;
  CheckValue:='1';
  UnCheckValue:='0';
  CharCase:=ecNormal;
  DataFieldType:=dftDefault;
end;

end.

