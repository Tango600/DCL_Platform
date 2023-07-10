unit uDCLData;
{$I DefineType.pas}

interface

uses
  StdCtrls, ComCtrls, Controls, Graphics, ExtCtrls, DB, Buttons, Classes,
  Generics.Collections, SysUtils,
{$IFnDEF FPC}
  Vcl.DBCtrls,
{$ELSE}
  DBCtrls,
{$ENDIF}
  uDCLConst, uDCLTypes;

type
  //TOrientation=(oVertical, oHorizontal);

  TGPT=record
  // EnableSQLTrace,
    DebugMesseges, OneCopy, ExitCnf, UseMessages, UserLogging, UserLoggingHistory, DebugOn,
    DisableFieldsList, HashPass, ShowPicture, DialogsSettings, DisableColors,
    DisableIniPasword, IBAll: Boolean;
    CurrentRunningScrString, CurrentRunningCmdString, Port: Integer;
    DateSeparator, TimeSeparator: Char;
    ServerCodePage, DateFormat, TimeFormat, Viewer, ConnectionString, MainFormCaption,
    NewConnectionString, DBPath, ServerName, NewDBUserName, DBType, GeneratorName: String;
    SQLDialect: Byte;
    NoParamsTable, NoUsersTable, DisableLogOnWithoutUser, MultiRolesMode: Boolean;
    DBUserName, DCLUserName, DCLUserPass, EnterPass, LongRoleName, GetValueSeparator, UpperString,
    UpperStringEnd,
    IniFileName, BaseID, LaunchScrFile, LaunchForm,
    StringTypeChar, ShowRoleField,
    TimeStampFormat, DCLLongUserName, UserID, RoleID,
    DCLRoleName, NewDBPassword, DBPassword, LibPath,
    WordOLEExtension, ExcelOLEExtension: String;
    FormPosInDB: TIniStore;
    OfficeDocumentFormat: TOfficeDocumentFormat;
    OfficeFormat: TOfficeFormat;
    AccessLevel: TUserLevelsType;
  end;

  TVariable=class
    NameSpace, Name: String;
    Value: String;
  End;

  { TDependFind }

  TDependFind=class
    GetResultFields, ReturnFields: TList<String>;
    GetToResultTable: String;
    DependFindMode: Byte;

    constructor Create;
    destructor Destroy; override;
  End;

  TDCLEdit=class
    Control: TWinControl;
    EditType: TFieldBoxType;
    GetResultFields: TDependFind;
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

  TExpr=Record
    Oper1, Oper2, ValResult: Real;
    Sign, Result: String;
  End;

  TSignInfo=Record
    SignPos: Word;
    SignLong:Byte;
  End;

  TDateTimeItem=Record
    Hour, Min, Sec, mSec, Year, Month, Day: Word;
  End;

  TDCLSession=Record
    LoginTime, UserSystemName: String;
  End;

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

  TRollBar=class
    RollBar: TTrackBar;
    Event, Variable, Field: String;
  end;

  TDCLEvent=class
    ScriptName: String;
    EventType: TEventsEnum;
  end;

  TBrushColor=class
    Color: TColor;
    Value, Key: String;
  end;

  TContextList=class
    ContextList: TComboBox;
    SQL, Table, Field, KeyField, DataField, ListField, Variable: String;
    NoData: Boolean;
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
    Multiselect: Boolean;
    constructor Create(aKeyField, aValueField, aKeyEditName, aValueEditName, aKeyModifyField, aValueModifyField,
      aKeyVar, aValueVar, aBatchScript: String; aMultiselect: Boolean);
  end;

  TComboFilterItem=class
    Key, Value:String;
  end;

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

{ TDependFind }

constructor TDependFind.Create;
begin
  GetResultFields:=TList<String>.Create;
  ReturnFields:=TList<String>.Create;
end;

destructor TDependFind.Destroy;
begin
  inherited;
  FreeAndNil(GetResultFields);
  FreeAndNil(ReturnFields);
end;

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
