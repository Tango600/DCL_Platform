unit uDCLBaseOfficeReport;
{$mode Delphi}

interface

uses
  Classes, SysUtils, LazFileUtils,
  uDCLConst, uDCLDBConnector, uDCLValuesParser;

type

  { TDCLBaseOfficeReport }

  TDCLBaseOfficeReport=class(TComponent)
  protected
    FDCLConnector: TDCLDBConnector;
    FValuseParser: TDCLValuseParser;
    FExtSQL: String;
    FErrorCode: Integer;
    OfficeDocumentFormat: TOfficeDocumentFormat;

    function GetTemplateFile(const Template, FileName, Ext: String): String;
  public
    constructor Create(DCLConnector: TDCLDBConnector; ValuseParser: TDCLValuseParser; SQL: String); overload;
  end;

implementation

uses
  uDCLDataStorage, uSystemUtils, uDCLMessages, uDCLGlobalVariables;

{ TDCLBaseOfficeReport }

function TDCLBaseOfficeReport.GetTemplateFile(const Template, FileName, Ext: String): String;
var
  BinStor: TDCLDataStorage;
  TempFile, Templ: String;
begin
  BinStor:=TDCLDataStorage.Create(FDCLConnector);
  FErrorCode:=0;
  Templ:=Template;
  FValuseParser.TranslateVals(Templ, nil, False);

  If Templ<>'' Then
  begin
    If BinStor.IsDataExist(Templ, ftByName) then
    begin
      If FileName<>'' Then
      begin
        If FilenameIsAbsolute(FileName) Then
          TempFile:=ChangeFileExt(FileName, '.'+Ext)
        Else
          TempFile:=IncludeTrailingPathDelimiter(GPT.AppConfigDir)+ChangeFileExt(FileName, '.'+Ext);
      end
      Else
        TempFile:=IncludeTrailingPathDelimiter(GPT.AppConfigDir)+GetTempFileName(Ext);

      BinStor.GetData(Templ, ftByName).SaveToFile(TempFile);
    end
    Else
    begin
      ShowErrorMessage( - 5004, Templ);
      FErrorCode:=4;
      TempFile:='';
    end;
  end;
  Result:=TempFile;
end;

constructor TDCLBaseOfficeReport.Create(DCLConnector: TDCLDBConnector;
  ValuseParser: TDCLValuseParser; SQL: String);
begin
  FExtSQL:=SQL;
  FDCLConnector:=DCLConnector;
  FValuseParser:=ValuseParser;
end;

end.

