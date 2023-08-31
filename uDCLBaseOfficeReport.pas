unit uDCLBaseOfficeReport;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils,
  uDCLData, uDCLConst, uDCLDBConnector, uDCLValuesParser;

type

  { TDCLBaseOfficeReport }

  TDCLBaseOfficeReport=class(TComponent)
  protected
    FDCLConnector: TDCLDBConnector;
    FValuseParser: TDCLValuseParser;
    FExtSQL: String;
    FErrorCode: Integer;
    OfficeDocumentFormat: TOfficeDocumentFormat;

    function GetTemplateFile(Template, FileName, Ext: String): String;
  public
    constructor Create(DCLConnector: TDCLDBConnector; ValuseParser: TDCLValuseParser; SQL: String); overload;
  end;

implementation

uses
  uDCLDataStorage, uSystemUtils, uDCLUtils, uDCLMessages, uDCLGlobalVariables;

{ TDCLBaseOfficeReport }

function TDCLBaseOfficeReport.GetTemplateFile(Template, FileName, Ext: String
  ): String;
var
  BinStor: TDCLDataStorage;
  TempFile: String;
begin
  BinStor:=TDCLDataStorage.Create(FDCLConnector);
  FErrorCode:=0;
  FValuseParser.TranslateVals(Template, nil, False);

  If Template<>'' Then
  begin
    If BinStor.IsDataExist(Template, ftByName) then
    begin
      If FileName<>'' Then
      begin
        If IsFullPAth(FileName) Then
          TempFile:=FakeFileExt(FileName, Ext)
        Else
          TempFile:=IncludeTrailingPathDelimiter(AppConfigDir)+FakeFileExt(FileName, Ext);
      end
      Else
        TempFile:=IncludeTrailingPathDelimiter(AppConfigDir)+GetTempFileName(Ext);

      BinStor.GetData(Template, ftByName).SaveToFile(TempFile);
    end
    Else
    begin
      ShowErrorMessage( - 5004, Template);
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

