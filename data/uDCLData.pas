unit uDCLData;
{$mode Delphi}

interface

uses
  DB, uDCLConst;

type
  { TReturnValueParams }

  TReturnValueParams=class
  public
    Mode: TChooseMode;
    KeyField, ValueField, KeyEditName, ValueEditName, KeyModifyField, ValueModifyField,
      KeyVar, ValueVar, InitScript, BatchScript, FinishScript: String;
    Multiselect: Boolean;
    constructor Create(aMode: TChooseMode; aKeyField, aValueField, aKeyEditName, aValueEditName, aKeyModifyField, aValueModifyField,
      aKeyVar, aValueVar, aBatchScript: String; aMultiselect: Boolean);
  end;

  TGridFieldSetting=class
    FieldName: String;
    Index, Width: Integer;
  end;

var
  TDataGrid: set of TGridStyle;
  TDataFields: set of TGridStyle;
  TBlobFields: set of TFieldType;
  TIntegerTypedFields: set of TFieldType;
  TStringTypedFields: set of TFieldType;
  TFloatTypedFields: set of TFieldType;
  TDateTimeTypedFields: set of TFieldType;

implementation

{ TReturnValueParams }

constructor TReturnValueParams.Create(aMode: TChooseMode; aKeyField, aValueField, aKeyEditName,
  aValueEditName, aKeyModifyField, aValueModifyField, aKeyVar, aValueVar,
  aBatchScript: String; aMultiselect: Boolean);
begin
  Mode:=aMode;
  KeyField:=aKeyField;
  ValueField:=aValueField;
  KeyEditName:=aKeyEditName;
  ValueEditName:=aValueEditName;
  KeyModifyField:=aKeyModifyField;
  ValueModifyField:=aValueModifyField;
  KeyVar:=aKeyVar;
  ValueVar:=aValueVar;
  BatchScript:=aBatchScript;
  Multiselect:=aMultiselect;
end;

Initialization

  TDataGrid:=[gsGrid];
  TDataFields:=[gsFields, gsFieldsHorizontal];

  TBlobFields:=[ftBytes, ftVarBytes, ftBlob, ftGraphic, ftMemo, ftFmtMemo, ftTypedBinary, ftWideMemo];
  TStringTypedFields:=[ftUnknown, ftString, ftFixedChar, ftWideString, ftVariant, ftGuid, ftFixedWideChar, ftWideMemo];
  TIntegerTypedFields:=[ftSmallint, ftInteger, ftWord, ftBoolean, ftAutoInc, ftLargeint, ftBytes, ftVarBytes];
  TFloatTypedFields:=[ftBCD, ftFloat, ftCurrency];
  TDateTimeTypedFields:=[ftDate, ftTime, ftDateTime, ftTimeStamp];
end.
