unit uPrintBase;
{$mode Delphi}

interface

uses
  Classes, SysUtils, DB, LazUTF8,
  uDCLDBAwareTypes;

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

const
  PixelPerChar=7;

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
  SeparatorLength, k, i: Integer;
  Separator, S, S1, S2: String;
  F: TField;
begin
  PrintBox:=TStringList.Create;
  PrintBox.Append(Caption);
  PrintBox.Append('');
  S:='|';
  If Not Assigned(Grid) Then
  begin
    For F in FQuery.Fields do
    begin
      S1:='';
      S2:=TrimRight(F.FieldName);
      If UTF8Length(S2)>F.DataSize Then
        SetLength(S2, F.DataSize+1);
      S:=S+S2;
      For k:=UTF8Length(TrimRight(F.FieldName)) to F.DataSize do
        S1:=S1+' ';
      S:=S+S1+'|';
    end;
    PrintBox.Append(S);
    SeparatorLength:=UTF8Length(S)-1;
    Separator:='';
    For k:=0 to SeparatorLength do
      Separator:=Separator+'-';
    PrintBox.Append(Separator);

    FQuery.First;
    While Not FQuery.Eof do
    begin
      S:='|';
      For F in FQuery.Fields do
      begin
        S1:='';
        S2:=TrimRight(F.AsString);
        If UTF8Length(S2)>F.DataSize Then
          SetLength(S2, F.DataSize+1);
        S:=S+S2;
        For k:=UTF8Length(TrimRight(F.AsString)) to F.DataSize do
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
    For i:=0 to Grid.Columns.Count-1 do
    begin
      S1:='';
      S2:=TrimRight(Grid.Columns[i].Title.Caption);
      If UTF8Length(S2)>(Grid.Columns[i].Width div PixelPerChar) Then
        S:=S+UTF8Copy(S2, 1, (Grid.Columns[i].Width div PixelPerChar)+1)
      else
        S:=S+S2;
      For k:=UTF8Length(TrimRight(Grid.Columns[i].Title.Caption))
        to (Grid.Columns[i].Width div PixelPerChar) do
        S1:=S1+' ';
      S:=S+S1+'|';
    end;
    PrintBox.Append(S);
    SeparatorLength:=UTF8Length(S)-1;
    Separator:='';
    For i:=0 to SeparatorLength do
      Separator:=Separator+'-';
    PrintBox.Append(Separator);

    FQuery.DisableControls;

    FQuery.First;
    While Not FQuery.Eof do
    begin
      S:='|';
      For i:=0 to Grid.Columns.Count-1 do
      begin
        S1:='';
        try
          S2:=Grid.Columns[i].Field.AsString;
        Except
          S2:='[no field]';
        end;
        If UTF8Length(S2)>(Grid.Columns[i].Width div PixelPerChar) Then
          S:=S+UTF8Copy(S2, 1, (Grid.Columns[i].Width div PixelPerChar)+1)
        else
          S:=S+S2;
        For k:=UTF8Length(TrimRight(Grid.Columns[i].Field.AsString))
          to (Grid.Columns[i].Width div PixelPerChar) do
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
  For i:=Length(Separator) to SeparatorLength-1 do
    Separator:=Separator+' ';
  Separator:=Separator+'|';
  PrintBox.Append(Separator);
end;

procedure TPrintBase.Save(FileName: String);
begin
  if Assigned(PrintBox) then
  begin
    PrintBox.SaveToFile(FileName, TEncoding.UTF8);
  end;
end;

end.

