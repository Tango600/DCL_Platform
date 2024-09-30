unit uDBControlsTypes;
{$mode Delphi}

interface

uses
  DBGrids, DBExtCtrls, DBCtrls,
  cMyFilterCombo;

type
  TDCLDBGrid=TDBGrid;
  TDBDate=TDBDateEdit;
  TNavButtons=TDBNavButton;
  TNavButtonsSet=TDBNavButtonSet;
  TDCLDBLookupCombo=TDBMyLookupCombo;
  //TDCLDBLookupCombo=TDBLookupComboBox;

const
  NavigatorEditButtons=[nbEdit, nbDelete, nbInsert, nbPost, nbCancel];
  NavigatorNavigateButtons=[nbFirst, nbLast, nbRefresh];

implementation

end.

