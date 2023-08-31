unit uSheetOfficeReportSelector;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils,
  uDCLConst, uOfficeReportBaseSelector;

type

  { TSheetOfficeReportSelector }

  TSheetOfficeReportSelector=class(TOfficeReportBaseSelector)
  protected
    procedure SetOfficeType; override;
  public
    procedure Run; override;
  end;

implementation

uses
  uDCLData, uDCLOfficeSheetReport, uDCLOfficeUtils, uDCLGlobalVariables;

{ TSheetOfficeReportSelector }

procedure TSheetOfficeReportSelector.SetOfficeType;
begin
  FOfficeFormat:=GetPossibleOffice(dtSheet, ConvertOfficeType(FOfficeTypeStr), GPT.OfficeFormat);
end;

procedure TSheetOfficeReportSelector.Run;
var
  Report: TDCLOfficeSheetReport;
begin
  Report:=TDCLOfficeSheetReport.Create(FDCLConnector, FValuseParser, FExtSQL);

  Case FOfficeFormat of
  ofOO:
  Report.Calc(FLine, FSave, FClose);
  ofMSO:
  Report.Excel(FLine, FSave, FClose);
  //ofNone: ShowErrorMessage( - 6200, '');
  end;
end;

end.

