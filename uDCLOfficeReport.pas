unit uDCLOfficeReport;
{$mode Delphi}

interface

uses
  Classes, SysUtils,
  uDCLTypes, uDCLDBConnector;

type

  { TDCLOfficeReport }

  TDCLOfficeReport=class


  public
    constructor Create(DCLConnector: TDCLDBConnector; SQL: String);


  end;

implementation

{ TDCLOfficeReport }

constructor TDCLOfficeReport.Create(DCLConnector: TDCLDBConnector; SQL: String);
begin

end;

end.

