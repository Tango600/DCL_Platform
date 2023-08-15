unit uDCLMeasurements;
{$I DefineType.pas}

interface

const
  EditWidth=230;
  DateTimeBoxWidth=110;
  DigitEditWidth=80;
  GetValueEditWidth=181;
  GetValueButtonGeom=22;
  FilterWidth=150;
  GrabComponentsWidth=200;
  GroupToolButtonTop=4;
  GroupToolButtonHeight=23;
  GroupButtonPanelHeight=GroupToolButtonHeight+GroupToolButtonTop*2;
  MemoWidth=250;
  MemoHeight=120;
  GraficWidth=166;
  GraficHeight=160;
  GroupHeight=160;
  CheckWidth=20;
  TablePartHeight=250;
  RollHeight=33;
  NavigatorHeight=25;

  MaxAllFieldsHeight=550;
  MaxAllFieldsWidth=900;

  LoginButtonWidth=75;
  LogOnFormControlsLeft=60;

  ContextButtonInterval=5;
  ToolLeftInterval=15;

{$IFDEF FPC}
  CalendarLeft={$IFDEF ZVComponents}25{$ELSE}15{$ENDIF};
  DateBoxAddWidth={$IFDEF ZVComponents}20{$ELSE}30{$ENDIF};
{$ELSE}
  AddHeight=0;
  CalendarLeft=15;
  DateBoxAddWidth=0;
{$ENDIF}
  ToolButtonPanelHeight=29;
  ToolButtonHeight=25;
  ToolBarButtonSpliterWidth=8;
  ToolButtonsFlat=True;

  BeginStepLeft=15;
  BeginStepTop=25;

  ButtonWidth=90;
  ButtonHeight=27;

  LabelTopInterval=4;
  CompenentTopStep=8;
  ButtonsInterval=10;
  FilterLabelTop=7;

  ColumnsLongerThis=1000;
  DefaultColumnSize=350;

  BevelWidth=4;
  ButtonsTop=12;
  ButtonsParagrapDown=11;
  //IncPanelHeight=ButtonHeight+ButtonsParagrapDown;
  ButtonPanelHeight=ButtonsTop+ButtonHeight+ButtonsParagrapDown;
  FullButtonWidth=ButtonWidth+ButtonsInterval;

  ScrollHeight=20;
  LookupTableHeight=145;
  FieldsStepLeft=17;
  FormPanelHeight=28;
  FormPanelButtonHeight=FormPanelHeight-5;
  FormPanelButtonWidth=85;
  PanelButtonTextRight=3;
{$IFDEF UNIX}
  AddSummGridHeight=20;
{$ELSE}
  AddSummGridHeight=0;
{$ENDIF}
  SummGridHeight=27+AddSummGridHeight;
  SumPanelHeight=150;

  DefaultFormHeight=MaxAllFieldsHeight+ToolButtonPanelHeight+ButtonPanelHeight;
  DefaultFormWidth=MaxAllFieldsWidth+10;

  StatusRecords=0;
  StatusDB=1;
  StatusInfo=2;
  StatusCustom=3;

implementation

end.

