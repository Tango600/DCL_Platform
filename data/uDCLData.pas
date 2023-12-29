unit uDCLData;
{$mode Delphi}

interface

uses
  StdCtrls, ComCtrls, Controls, Graphics, ExtCtrls, DB, Buttons, Classes,
  Generics.Collections, SysUtils, Forms, DBCtrls,
  uDCLConst, uDCLTypes, uDCLDBAwareTypes;

type
  TVariable=class
    NameSpace, Name: String;
    Value: String;
  End;

  TDCLEdit=class
    Control: TWinControl;
    EditType: TFieldBoxType;
    Variable: String;
  end;

  TDCLCalendar=class
    LabelField: TDialogLabel;
    Control: TDateTimePicker;
    Caption, Field, Variable, ParamName: String;
    Value: TDate;
    Num: Integer;
    ReOpen: Boolean;
  end;

  TStructureModify=class
    ColumnsListCaption, FieldsListCaption: String;
    ColumnsListField, FieldsListField: String;
  End;

  TDCLQueryStore=class
    QueryStr: String;
    QueryRaights: TUserLevelsType;
    QueryType: TQueryType;
  end;

  TDBFilter=class
    Width, FilterNum, WaitForKey, FilterChengFlag,
      MaxLength: Integer;
    Partial, Between, NotLike, CaseC, NotFilter: Boolean;
    FilterName, FilterString, Field, KeyField, ListField: String;
    FilterLabel: TDialogLabel;
    Control: TWinControl;
    FilterType: TFilterType;
    FilterQuery: TDCLDialogQuery;
    FilterData: TDataSource;
    FilterKey, VarName, Caption, SQL, KeyValue: String;
    NotCheck: TCheckBox;
  end;

  TDCLLookup=class
    LookupQuery: TDCLDialogQuery;
    LookupDS: TDataSource;
    NoDataField: Boolean;
    ModifyEdit: String;
  end;

  TContextFieldButton=class
    Button: TDialogSpeedButton;
    Command: String;
  End;

  TDCLEvent=class
    ScriptName: String;
    EventType: TEventsEnum;
  end;

  TBrushColor=class
    Color: TColor;
    ConditionValue: String;
  end;

  TFontStyleRec=Record
    Italic, Bold, Undeline, StrikeThrough: Byte;
    Center:Boolean;
  End;

  TVirtualScript=Record
    ScriptName, ScrCommand, ScrText:string;
  End;

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

  TComboFilterItem=class
    Key, Value:String;
  end;

  { TCondition }

  TCondition=class
    FieldNameLeft: String;
    ConditionType: TConditionTypes;
    Values: TList<String>;
    ItemCondition: TPairCondition;

    constructor Create;
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

{ TCondition }

constructor TCondition.Create;
begin
  Values:=TList<String>.Create;
end;

Initialization

  TDataGrid:=[gsGrid];
  TDataFields:=[gsFields, gsFieldsHorizontal];

  TBlobFields:=[ftBytes, ftVarBytes, ftBlob, ftGraphic, ftMemo, ftFmtMemo, ftTypedBinary, ftWideMemo];
  TStringTypedFields:=[ftUnknown, ftString, ftFixedChar, ftWideString, ftVariant, ftGuid, ftFixedWideChar, ftWideMemo];
  TIntegerTypedFields:=[ftSmallint, ftInteger, ftWord, ftBoolean, ftAutoInc, ftLargeint, ftBytes, ftVarBytes, ftOraInterval];
  TFloatTypedFields:=[ftBCD, ftFloat, ftCurrency];
  TDateTimeTypedFields:=[ftDate, ftTime, ftDateTime, ftTimeStamp, ftOraTimeStamp];
end.
