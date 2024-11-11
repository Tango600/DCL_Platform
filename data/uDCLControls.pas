unit uDCLControls;
{$mode Delphi}

interface

uses
  Classes, StdCtrls, ComCtrls, Controls, DB,
  uDCLConst, uDCLTypes, uDCLDBFilter, uDCLDBAwareTypes;

type
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

  TDBFilter=class(TDCLDBFilter)
    FilterNum: Integer;
    FilterString: String;
    FilterLabel, NotCheckLabel: TDialogLabel;
    Control: TWinControl;
    FilterQuery: TDCLDialogQuery;
    FilterData: TDataSource;
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

  TComboFilterItem=class
    Key, Value:String;
  end;


implementation

end.

