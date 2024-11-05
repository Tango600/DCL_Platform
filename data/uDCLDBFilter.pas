unit uDCLDBFilter;
{$mode Delphi}

interface

uses
  Classes, uDCLConst;

type
  TDCLDBFilter=class
    Width, WaitForKey, MaxLength: Integer;
    Contains, Between, NotLike, CaseC, NotFilter: Boolean;
    FilterName, Field, KeyField, ListField: String;
    FilterType: TFilterType;
    FilterKey, VarName, Caption, SQL, KeyValue: String;
  end;

implementation

end.

