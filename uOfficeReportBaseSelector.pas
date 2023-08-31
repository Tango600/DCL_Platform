unit uOfficeReportBaseSelector;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils,
  uDCLConst, uDCLDBConnector, uDCLValuesParser;

type

  { TOfficeReportBaseSelector }

  TOfficeReportBaseSelector=class
  protected
    FDCLConnector: TDCLDBConnector;
    FValuseParser: TDCLValuseParser;
    FLine, FExtSQL, FOfficeTypeStr: String;
    FSave, FClose: Boolean;
    FOfficeFormat: TOfficeFormat;

    procedure SetOfficeType; virtual; abstract;
    procedure Run; virtual; abstract;
  public
    constructor Create(ScrLine: String; DCLConnector: TDCLDBConnector; ValuseParser: TDCLValuseParser); overload;

    procedure SetSQL(SQL: String);
  end;

implementation

uses
  uDCLOfficeUtils, uStringParams;

{ TOfficeReportBaseSelector }

procedure TOfficeReportBaseSelector.SetSQL(SQL: String);
begin
  FExtSQL:=SQL;
end;

constructor TOfficeReportBaseSelector.Create(ScrLine: String;
  DCLConnector: TDCLDBConnector; ValuseParser: TDCLValuseParser);
begin
  FDCLConnector:=DCLConnector;
  FValuseParser:=ValuseParser;
  FLine:=ScrLine;

  FSave:=FindParam('Save=', ScrLine)='1';
  FClose:=FindParam('Close=', ScrLine)='1';

  FOfficeTypeStr:=LowerCase(FindParam('OfficeType=', ScrLine));
  SetOfficeType;
end;

end.

