unit uDCLDataStorage;
{$mode Delphi}

interface

uses
  Classes, SysUtils, DB,
  uDCLConst, uDCLTypes, uDCLDBConnector, uDCLData, uDCLMD5, uDCLDBStructure,
  uLZW;

type

  { TDCLDataStorage }

  TDCLDataStorage=class(TComponent)
  private
    FErrorCode: Byte;
    FIsCompressed: Boolean;
    FDBConnector: TDCLDBConnector;
    DCLQuery: TDCLDialogQuery;
    FTableName, FKeyField, FNameField, FDataField: String;
  public
    constructor Create(DBConnector: TDCLDBConnector); overload;

    function GetData(DataName: String; FindType: TFindType): TMemoryStream;
    procedure SetData(DataName: String; FindType: TFindType; Stream: TStream;
      Compress: Boolean);

    procedure ClearData(DataName: String; FindType: TFindType);
    procedure DeleteData(DataName: String; FindType: TFindType);

    function IsDataExist(DataName: String; FindType: TFindType): Boolean;

    procedure CompressData(DataName: String; FindType: TFindType);
    procedure DeCompressData(DataName: String; FindType: TFindType);

    function MD5(DataName: String; FindType: TFindType): String;

    procedure StoreFromFile(FileName, DataName: String; FindType: TFindType;
      Compress: Boolean);
    procedure SaveToFile(FileName, DataName: String; FindType: TFindType);

    property IsCompressed: Boolean read FIsCompressed;
  end;

implementation

uses
  uDCLGlobalVariables;

{ TDCLDataStorage }

constructor TDCLDataStorage.Create(DBConnector: TDCLDBConnector);
begin
  FDBConnector:=DBConnector;
  FErrorCode:=0;

  DCLQuery:=TDCLDialogQuery.Create(Self);
  DBConnector.SetConnector(DCLQuery);

  FTableName:=BinStorageTable;
  FKeyField:=BinDataId;
  FNameField:=BinStorageNameField;
  FDataField:=BinDataField;
end;

function TDCLDataStorage.GetData(DataName: String; FindType: TFindType): TMemoryStream;
var
  BS, MS: TStream;
  Marker: Cardinal;
begin
  FErrorCode:=0;
  DCLQuery.Close;
  Result:=TMemoryStream.Create;
  Case FindType of
  ftByName: begin
    DCLQuery.SQL.Text:='select '+FDataField+' from '+FTableName+' where lower('+FNameField+')='+
      'lower(:DataName)';
    DCLQuery.ParamByName('DataName').AsString:=DataName;
  end;
  ftByIndex: begin
    DCLQuery.SQL.Text:='select '+FDataField+' from '+FTableName+' where '+FKeyField+'=:DataName';
    DCLQuery.ParamByName('DataName').AsString:=DataName;
  end;
  ftSQL:
  DCLQuery.SQL.Text:=DataName;
  end;
  try
    DCLQuery.Open;
    DCLQuery.Last;
    DCLQuery.First;
  Except
    FErrorCode:=3;
    Exit;
  end;
  If Not DCLQuery.IsEmpty Then
  begin
    try
      MS:=TMemoryStream.Create;
      Result:=TMemoryStream.Create;
      TBlobField(DCLQuery.Fields[0]).SaveToStream(MS);
      If MS.Size>0 Then
      begin
        Marker:=0;
        MS.Position:=0;
        MS.Read(Marker, PAGSignatureSize);

        FIsCompressed:=False;
        If Marker=PAGSignature Then // "PAG" Signature
        begin
          // Compressed/
          FIsCompressed:=True;
          BS:=TMemoryStream.Create;
          BS.Position:=0;
          DecompressProc(MS, BS);
          BS.Position:=0;
          MS.Position:=0;
          MS.CopyFrom(BS, BS.Size);
          FreeAndNil(BS);
        end;

        MS.Position:=0;
        Result.CopyFrom(MS, MS.Size);
      end;
    Except
      //
    end;
  end;
  DCLQuery.Close;
end;

procedure TDCLDataStorage.SetData(DataName: String; FindType: TFindType;
  Stream: TStream; Compress: Boolean);
var
  BS: TStream;
  Signature: Cardinal;
begin
  If Stream.Size>0 Then
  begin
    FIsCompressed:=Compress;
    If Compress Then
    begin
      BS:=TMemoryStream.Create;
      Signature:=PAGSignature;
      BS.Write(Signature, PAGSignatureSize);
      Stream.Position:=0;
      CompressProc(Stream, BS);
      BS.Position:=0;
      Stream.Position:=0;
      Stream.CopyFrom(BS, BS.Size);
      FreeAndNil(BS);
    end;

    if IsDataExist(DataName, FindType) then
    begin
      Case FindType of
      ftByName: begin
        DCLQuery.SQL.Text:='update '+FTableName+' set '+FDataField+' = :DATADD '+
          'where lower('+FNameField+') = lower(:DataName)';
        DCLQuery.ParamByName('DataName').AsString:=DataName;
      end;
      ftByIndex: begin
        DCLQuery.SQL.Text:='update '+FTableName+' set '+FDataField+' = :DATADD '+
          'where '+FKeyField+' = :DataName';
        DCLQuery.ParamByName('DataName').AsString:=DataName;
      end;
      ftSQL:
      begin
        DCLQuery.SQL.Text:=DataName;
      end;
      end;
    end
    else
    begin
      Case FindType of
      ftByName: begin
        DCLQuery.SQL.Text:='insert into '+FTableName+'('+FNameField+', '+FDataField+') values(:DataName, :DATADD)';
        DCLQuery.ParamByName('DataName').AsString:=DataName;
      end;
      ftByIndex: begin
        DCLQuery.SQL.Text:='insert into '+FTableName+'('+FKeyField+', '+FDataField+') values(:DataName, :DATADD)';
        DCLQuery.ParamByName('DataName').AsString:=DataName;
      end;
      ftSQL:
      begin
        DCLQuery.SQL.Text:=DataName;
      end;
      end;
    end;

    Stream.Position:=0;
    DCLQuery.ParamByName('DATADD').LoadFromStream(Stream, ftBlob);
    try
      DCLQuery.ExecSQL;
    Except
      FErrorCode:=3;
      Exit;
    end;
  end;
end;

procedure TDCLDataStorage.ClearData(DataName: String; FindType: TFindType);
begin
  Case FindType of
  ftByName: begin
    DCLQuery.SQL.Text:='update '+FTableName+' set '+FDataField+'=null where '+
      'lower('+FNameField+')=lower(:DataName)';
    DCLQuery.ParamByName('DataName').AsString:=DataName;
  end;
  ftByIndex: begin
    DCLQuery.SQL.Text:='update '+FTableName+' set '+FDataField+'=null where '+
      FKeyField+'=:DataName';
    DCLQuery.ParamByName('DataName').AsString:=DataName;
  end;
  ftSQL:
  DCLQuery.SQL.Text:=DataName;
  end;
  try
    DCLQuery.ExecSQL;
  Except
    Exit;
  end;
end;

procedure TDCLDataStorage.DeleteData(DataName: String; FindType: TFindType);
begin
  Case FindType of
  ftByName: begin
    DCLQuery.SQL.Text:='delete from '+FTableName+
      ' where lower('+FNameField+')=lower(:DataName)';
    DCLQuery.ParamByName('DataName').AsString:=DataName;
  end;
  ftByIndex: begin
    DCLQuery.SQL.Text:='delete from '+FTableName+
      ' where '+FKeyField+'=:DataName';
    DCLQuery.ParamByName('DataName').AsString:=DataName;
  end;
  ftSQL:
  DCLQuery.SQL.Text:=DataName;
  end;
  try
    DCLQuery.ExecSQL;
  Except
    FErrorCode:=3;
  end;
end;

function TDCLDataStorage.IsDataExist(DataName: String; FindType: TFindType
  ): Boolean;
begin
  Result:=False;
  Case FindType of
  ftByName: begin
    DCLQuery.SQL.Text:='select '+FDataField+' from '+FTableName+
      ' where lower('+FNameField+')=lower(:DataName)';
    DCLQuery.ParamByName('DataName').AsString:=DataName;
  end;
  ftByIndex: begin
    DCLQuery.SQL.Text:='select '+FDataField+' from '+FTableName+
      ' where '+FKeyField+'=:DataName';
    DCLQuery.ParamByName('DataName').AsString:=DataName;
  end;
  ftSQL:
  DCLQuery.SQL.Text:=DataName;
  end;
  try
    DCLQuery.Open;
  Except
    FErrorCode:=3;
    Exit;
  end;
  Result:=Not DCLQuery.IsEmpty;
  DCLQuery.Close;
end;

procedure TDCLDataStorage.CompressData(DataName: String; FindType: TFindType);
var
  MS: TMemoryStream;
begin
  MS:=GetData(DataName, FindType);
  MS.Position:=0;
  SetData(DataName, FindType, MS, True);
  MS.Free;
end;

procedure TDCLDataStorage.DeCompressData(DataName: String; FindType: TFindType);
var
  MS: TMemoryStream;
begin
  MS:=GetData(DataName, FindType);
  SetData(DataName, FindType, MS, False);
  MS.Free;
end;

function TDCLDataStorage.MD5(DataName: String; FindType: TFindType): String;
var
  MS: TMemoryStream;
begin
  MS:=GetData(DataName, FindType);
  Result:=MD5Stream(MS);
end;

procedure TDCLDataStorage.StoreFromFile(FileName, DataName: String;
  FindType: TFindType; Compress: Boolean);
var
  MS: TMemoryStream;
begin
  If FileExists(FileName) Then
  begin
    MS:=TMemoryStream.Create;
    MS.LoadFromFile(FileName);
    SetData(DataName, FindType, MS, Compress);
    MS.Free;
  end;
end;

procedure TDCLDataStorage.SaveToFile(FileName, DataName: String;
  FindType: TFindType);
begin
  GetData(DataName, FindType).SaveToFile(FileName);
end;

end.

