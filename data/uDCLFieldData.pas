unit uDCLFieldData;
{$mode Delphi}

interface

uses
  StdCtrls,
  uDCLData, uDCLConst;

type
  { TDCLFieldData }

  TDCLFieldData=class
  public
    CharCase: TEditCharCase;
    FieldName, Caption, Hint, Variable, Value, CheckValue, UnCheckValue, SQL,
      FullFieldName, FirstFieldsLine, NotInputValue, ComponentName: String;
    PasswordChar: Char;
    Width, Height, MaxLength: Integer;
    ReadOnly, NoDataField, UseIndex, Enabled, RequireValue: Boolean;
    FieldTypeFormat: TFieldFormat;
    DataFieldType: TDCLDataFieldKind;

    constructor Create;
  end;

implementation

{ TDCLFieldData }

constructor TDCLFieldData.Create;
begin
  Enabled:=True;
  CheckValue:='1';
  UnCheckValue:='0';
  DataFieldType:=dftDefault;
  CharCase:=ecNormal;
end;

end.

