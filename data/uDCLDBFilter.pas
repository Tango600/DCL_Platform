unit uDCLDBFilter;
{$mode Delphi}{$H+}

interface

uses
  Classes, uDCLConst;

type
  TDCLDBFilter=class
    FilterNum: Integer;
    FilterString: String;
    Width, WaitForKey, MaxLength: Integer;
    Contains, Between, NotLike, CaseC, NotFilter: Boolean;
    FilterName, Field, KeyField, ListField: String;
    FilterType: TFilterType;
    FilterKey, VarName, Caption, SQL, KeyValue: String;
  end;

implementation

end.

