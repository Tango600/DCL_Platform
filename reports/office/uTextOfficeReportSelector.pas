unit uTextOfficeReportSelector;
{$mode Delphi}

interface

uses
  Classes, SysUtils,
  uDCLConst, uOfficeReportBaseSelector;

type

  { TTextOfficeReportSelector }

  TTextOfficeReportSelector=class(TOfficeReportBaseSelector)
  protected
    procedure SetOfficeType; override;
  public
    procedure Run; override;
  end;

implementation

uses
  uDCLData, uDCLOfficeUtils, uDCLOfficeTextReport, uDCLGlobalVariables;

{ TTextOfficeReportSelector }

procedure TTextOfficeReportSelector.SetOfficeType;
begin
  FOfficeFormat:=GetPossibleOffice(dtText, ConvertOfficeType(FOfficeTypeStr), GPT.OfficeFormat);
end;

procedure TTextOfficeReportSelector.Run;
var
  Report: TDCLOfficeTextReport;
begin
  Report:=TDCLOfficeTextReport.Create(FDCLConnector, FValuseParser, FExtSQL);

  Case FOfficeFormat of
  ofOO:
  Report.Writer(FLine, FSave, FClose);
  ofMSO:
  Report.Word(FLine, FSave, FClose);
  //ofNone: ShowErrorMessage( - 6200, '');
  end;
end;

end.

