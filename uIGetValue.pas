unit uIGetValue;
{$I DefineType.pas}

interface

uses
  uDCLData;

type
  IGetValue=interface
    procedure GetValueProc(Value: TReturnFormValue);
  end;

implementation

end.