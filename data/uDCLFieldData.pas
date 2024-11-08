unit uDCLFieldData;
{$mode Delphi}

interface

uses
  StdCtrls,
  uDCLConst;

type
  { TDCLFieldData }

  TDCLFieldData=class
  public
    CharCase: TEditCharCase;
    FieldName, Caption, Hint, Variable, Value, CheckValue, UnCheckValue, SQL,
      FullFieldName, FirstFieldsLine, NotInputValue, ComponentName,
      KeyField, ListField: String;
    PasswordChar: Char;
    Width, Height, MaxLength, CheckState: Integer;
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

