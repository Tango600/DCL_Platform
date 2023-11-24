unit uDCLTypes;
{$I DefineType.pas}

interface

Uses
  Controls, ExtCtrls, StdCtrls, ComCtrls, Buttons, cMeDateEdit,
  Forms;

type
  TDialogButton=TBitBtn;
  TDCLDialogButton=TBitBtn;
  TDCLFilterPanel=TScrollBox;
  TDialogPanel=TScrollBox;
  TDCLButtonPanel=TScrollBox;
  TToolBarPanel=TToolBar;
  TDialogLabel=TLabel;

  TDialogSpeedButton=TSpeedButton;
  TFormPanelButton=TSpeedButton;

  TDateTimePicker={$IFDEF ZVComponents}TZVDateTimePicker{$ELSE}TMyDateEdit{$ENDIF};

implementation


end.
