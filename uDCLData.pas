unit uDCLData;
{$I DefineType.pas}

interface

uses
  StdCtrls, ComCtrls, Controls, Graphics, ExtCtrls, DB, Buttons, Classes,
  Generics.Collections, SysUtils, Forms,
{$IFnDEF FPC}
  Vcl.DBCtrls,
{$ELSE}
  DBCtrls,
{$ENDIF}
  uDCLConst, uDCLTypes;

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
    Control: DateTimePicker;
    Caption, Field, Variable: String;
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
    LookupQuery:TDCLDialogQuery;
    LookupToVar:String;
    LookupData:TDataSource;
    NoDataField:Boolean;
    ModifyEdit:String;
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
    Value, Key: String;
  end;

  TKeyBookMark=class
    KeyField, KeyValue, Title: String;
  End;

  { TKeyBookmarks }

  TKeyBookmarks=class
    KeyField, TitleField: String;
    KeyBookMarks: TList<TKeyBookMark>;

    constructor Create;
  end;

  TFontStyleRec=Record
    Italic, Bold, Undeline, StrikeThrough: Byte;
    Center:Boolean;
  End;

  TGetValueItem=class
    Key, Value: String;
  end;

  { TReturnFormValue }

  TReturnFormValue=class
    KeyModifyField, ValueModifyField, KeyVar, ValueVar, KeyEditName, ValueEditName, BatchScript: String;
    Multiselect: Boolean;
    Values: TList<TGetValueItem>;
    DestinationForm: TForm;

    constructor Create;
  end;

  TVirtualScript=Record
    ScriptName, ScrCommand, ScrText:string;
  End;

  { TReturnValueParams }

  TReturnValueParams=class
  public
    KeyField, ValueField, KeyEditName, ValueEditName, KeyModifyField, ValueModifyField,
      KeyVar, ValueVar, BatchScript: String;
    Multiselect, Modal: Boolean;
    constructor Create(aKeyField, aValueField, aKeyEditName, aValueEditName, aKeyModifyField, aValueModifyField,
      aKeyVar, aValueVar, aBatchScript: String; aMultiselect: Boolean);
  end;

  TComboFilterItem=class
    Key, Value:String;
  end;

  TGetValueProc=procedure(Value: TReturnFormValue) of Object;

var
  TDataGrid: set of TGridStyle;
  TDataFields: set of TGridStyle;
  //DefaultOrientation: TOrientation;
  TBlobFields: set of TFieldType;
  TIntegerTypedFields: set of TFieldType;
  TStringTypedFields: set of TFieldType;
  TFloatTypedFields: set of TFieldType;
  TDateTimeTypedFields: set of TFieldType;

implementation

{ TKeyBookmarks }

constructor TKeyBookmarks.Create;
begin
  KeyBookMarks:=TList<TKeyBookMark>.Create;
end;

{ TReturnFormValue }

constructor TReturnFormValue.Create;
begin
  Values:=TList<TGetValueItem>.Create;
end;

{ TReturnValueParams }

constructor TReturnValueParams.Create(aKeyField, aValueField, aKeyEditName, aValueEditName, aKeyModifyField, aValueModifyField,
    aKeyVar, aValueVar, aBatchScript: String; aMultiselect: Boolean);
begin
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
  TIntegerTypedFields:=[ftSmallint, ftInteger, ftWord, ftBoolean, ftAutoInc, ftLargeint, ftBytes, ftVarBytes{$IFNDEF FPC}, ftOraInterval{$ENDIF}];
  TFloatTypedFields:=[ftBCD, ftFloat, ftCurrency];
  TDateTimeTypedFields:=[ftDate, ftTime, ftDateTime, ftTimeStamp {$IFNDEF FPC}, ftOraTimeStamp{$ENDIF}];

end.
