unit uReturnFormValue;
{$mode Delphi}

interface

uses
  Classes, SysUtils, Generics.Collections;

type
  TGetValueItem=class
    Key, Value: String;
  end;

  { TReturnFormValue }

  TReturnFormValue=class
    KeyModifyField, ValueModifyField, KeyVar, ValueVar, KeyEditName, ValueEditName,
      InitScript, BatchScript, FinishScript: String;
    Multiselect: Boolean;
    Values: TList<TGetValueItem>;

    constructor Create;
  end;

implementation

{ TReturnFormValue }

constructor TReturnFormValue.Create;
begin
  Values:=TList<TGetValueItem>.Create;
end;

end.

