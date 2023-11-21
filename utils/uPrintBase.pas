unit uPrintBase;
{$mode Delphi}

interface

uses
  Classes, SysUtils,
  uDCLTypes;

type

  { TPrintBase }

  TPrintBase=class
  private
    FQuery: TDCLDialogQuery;
    PrintBox: TStringList;

  public
    constructor Create(Query: TDCLDialogQuery);
    destructor Destroy; override;

    procedure Print(Grid: TDCLDBGrid; Caption: String);
    procedure Save(FileName: String);
  end;

implementation

{ TPrintBase }

constructor TPrintBase.Create(Query: TDCLDialogQuery);
begin
  FQuery:=Query;
end;

destructor TPrintBase.Destroy;
begin
  inherited Destroy;
  FreeAndNil(PrintBox);
end;

procedure TPrintBase.Print(Grid: TDCLDBGrid; Caption: String);
var
  SeparatorLength, k, FieldsCounter: Word;
  Separator, S, S1, S2: String;
begin
  PrintBox:=TStringList.Create;
  PrintBox.Append(Caption);
  PrintBox.Append('');
  S:='|';
  If Not Assigned(Grid) Then
  begin
    For FieldsCounter:=0 to FQuery.FieldCount-1 do
    begin
      S1:='';
      S2:=TrimRight(FQuery.Fields[FieldsCounter].FieldName);
      If Length(S2)>FQuery.Fields[FieldsCounter].DataSize Then
        SetLength(S2, FQuery.Fields[FieldsCounter].DataSize+1);
      S:=S+S2;
      For k:=Length(TrimRight(FQuery.Fields[FieldsCounter].FieldName)) to FQuery.Fields
        [FieldsCounter].DataSize do
        S1:=S1+' ';
      S:=S+S1+'|';
    end;
    PrintBox.Append(S);
    SeparatorLength:=Length(S)-1;
    Separator:='';
    For FieldsCounter:=0 to SeparatorLength do
      Separator:=Separator+'-';
    PrintBox.Append(Separator);

    FQuery.First;
    While Not FQuery.Eof do
    begin
      S:='|';
      For FieldsCounter:=0 to FQuery.FieldCount-1 do
      begin
        S1:='';
        S2:=TrimRight(FQuery.Fields[FieldsCounter].AsString);
        If Length(S2)>FQuery.Fields[FieldsCounter].DataSize Then
          SetLength(S2, FQuery.Fields[FieldsCounter].DataSize+1);
        S:=S+S2;
        For k:=Length(TrimRight(FQuery.Fields[FieldsCounter].AsString)) to FQuery.Fields
          [FieldsCounter].DataSize do
          S1:=S1+' ';
        S:=S+S1+'|';
      end;
      PrintBox.Append(S);
      FQuery.Next;
    end;
    PrintBox.Append(Separator);
    Separator:='|'+IntToStr(FQuery.RecordCount);
  end
  Else
  begin
    For FieldsCounter:=0 to Grid.Columns.Count-1 do
    begin
      S1:='';
      S2:=TrimRight(Grid.Columns[FieldsCounter].Title.Caption);
      If Length(S2)>(Grid.Columns[FieldsCounter].Width div 7) Then
        SetLength(S2, (Grid.Columns[FieldsCounter].Width div 7)+1);
      S:=S+S2;
      For k:=Length(TrimRight(Grid.Columns[FieldsCounter].Title.Caption))
        to (Grid.Columns[FieldsCounter].Width div 7) do
        S1:=S1+' ';
      S:=S+S1+'|';
    end;
    PrintBox.Append(S);
    SeparatorLength:=Length(S)-1;
    Separator:='';
    For FieldsCounter:=0 to SeparatorLength do
      Separator:=Separator+'-';
    PrintBox.Append(Separator);

    FQuery.DisableControls;

    FQuery.First;
    While Not FQuery.Eof do
    begin
      S:='|';
      For FieldsCounter:=0 to Grid.Columns.Count-1 do
      begin
        S1:='';
        try
          S2:=Grid.Columns[FieldsCounter].Field.AsString;
        Except
          S2:='[no field]';
        end;
        If Length(S2)>(Grid.Columns[FieldsCounter].Width div 7) Then
          SetLength(S2, (Grid.Columns[FieldsCounter].Width div 7)+1);
        S:=S+S2;
        For k:=Length(TrimRight(Grid.Columns[FieldsCounter].Field.AsString))
          to (Grid.Columns[FieldsCounter].Width div 7) do
          S1:=S1+' ';
        S:=S+S1+'|';
      end;
      PrintBox.Append(TrimRight(S));
      FQuery.Next;
    end;
    FQuery.EnableControls;
    PrintBox.Append(Separator);
    Separator:='|'+IntToStr(FQuery.RecordCount);
  end;
  For FieldsCounter:=Length(Separator) to SeparatorLength-1 do
    Separator:=Separator+' ';
  Separator:=Separator+'|';
  PrintBox.Append(Separator);

  //ExecApp('"'+GPT.Viewer+'" "'+IncludeTrailingPathDelimiter(AppConfigDir)+'table.tmp"', '');
end;

procedure TPrintBase.Save(FileName: String);
begin
  if Assigned(PrintBox) then
  begin
    PrintBox.SaveToFile(FileName{$IFDEF FPC}, TEncoding.UTF8{$ENDIF});
  end;
end;

end.

