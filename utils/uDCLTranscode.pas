unit uDCLTranscode;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils;

type
  TTranscodeDataType=(tdtTranslit);

 procedure LoadTranscodeRes(const Lang, Path: String);
 Function GetFileNameToTranslite(Const FullFileName: String): String;

implementation

uses
  uDetectDataType, uStringParams, uDCLConst;

type
  TTranscodeType=(ttDirect, ttSub, ttAdd, ttVarLen);

  TTranscodeData=Record
    CodeFrom1, CodeFrom2, TargetGap: Integer;
    SourceLiteral, TagertCode: String;
    TranscodeType: TTranscodeType;
  end;

const
  DefaultLangDir='lang';
  TransliteSimbolsCount=68;
  RusTab: Array [0..TransliteSimbolsCount-1] Of String=('а', 'б', 'в', 'г', 'д', 'е', 'ё', 'ж', 'з', 'и', 'й',
    'к', 'л', 'м', 'н', 'о', 'п', 'р', 'с', 'т', 'у', 'ф', 'х', 'ц', 'ч', 'ш', 'щ', 'ы', 'ъ', 'ь',
    'э', 'ю', 'я', 'А', 'Б', 'В', 'Г', 'Д', 'Е', 'Ё', 'Ж', 'З', 'И', 'Й', 'К', 'Л', 'М', 'Н', 'О',
    'П', 'Р', 'С', 'Т', 'У', 'Ф', 'Х', 'Ц', 'Ч', 'Ш', 'Щ', 'Ы', 'Ъ', 'Ь', 'Э', 'Ю', 'Я', ' ', '№');
  LatTab: Array [0..TransliteSimbolsCount-1] Of String=('a', 'b', 'v', 'g', 'd', 'je', 'jo', 'zh', 'z', 'i',
    'j', 'k', 'l', 'm', 'n', 'o', 'p', 'r', 's', 't', 'u', 'f', 'h', 'ce', 'ch', 'sh', 'sch', 'y',
    '''', '', 'e', 'ju', 'ja', 'A', 'B', 'V', 'G', 'D', 'JE', 'JO', 'ZH', 'Z', 'I', 'J', 'K', 'L',
    'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'F', 'H', 'CE', 'CH', 'SH', 'SCH', 'Y', '''', '', 'E',
    'JU', 'JA', '_', '#');

var
  TranscodeData: Array[TTranscodeDataType] of Array of TTranscodeData;

procedure ClearTranscodeData(var Data: TTranscodeData);
begin
  Data.CodeFrom1:=0;
  Data.CodeFrom2:=0;
  Data.TargetGap:=0;
  Data.SourceLiteral:='';
  Data.TagertCode:='';
  Data.TranscodeType:=ttDirect;
end;

function LoadTranscodeFile(DataType: TTranscodeDataType; const FileName: String): Boolean;
var
  LangResFile: TStringList;
  S, c, vs1, tmp1: String;
  ii, p, k, d, v1, l: Integer;
  simbcodeflg: Boolean;
begin
  Result:=False;
{$IFNDEF SINGLELANG}
  If FileExists(FileName) then
  Begin
    LangResFile:=TStringList.Create;
    LangResFile.LoadFromFile(FileName, TEncoding.UTF8);

    For ii:=1 to LangResFile.Count do
    Begin
      S:=LangResFile[ii-1];
      If Pos(';', S)<>1 then
      Begin
        p:=Pos(':', S);
        If p<>0 then
        Begin
          l:=Length(TranscodeData[DataType]);
          SetLength(TranscodeData[DataType], l+1);
          ClearTranscodeData(TranscodeData[DataType][l]);
          vs1:=GetClearParam(Copy(S, 1, p-1), #39);
          If (Pos('-', vs1)=0) then
          Begin
            tmp1:=GetClearParam(Copy(S, 1, p-1), #39);
            if IsDigit(tmp1) or IsHex(tmp1) then
            begin
              k:=StrToInt(tmp1);
              TranscodeData[DataType][l].CodeFrom1:=k;
              TranscodeData[DataType][l].CodeFrom2:=k;
            end
            else
            begin
              TranscodeData[DataType][l].SourceLiteral:=tmp1;
            End;
          End
          Else
          Begin
            tmp1:=GetClearParam(Copy(S, 1, Pos('-', vs1)-1), #39);
            if IsDigit(tmp1) or IsHex(tmp1) then
            Begin
              k:=StrToInt(tmp1);
              TranscodeData[DataType][l].CodeFrom1:=k;
            end;

            tmp1:=Copy(S, Pos('-', vs1)+1, p-1-Pos('-', vs1));
            if IsDigit(tmp1) or IsHex(tmp1) then
            Begin
              k:=StrToInt(tmp1);
              TranscodeData[DataType][l].CodeFrom2:=k;
            End;
          End;

          d:=Pos(';', S);
          If d=0 then
            d:=Length(S);
          c:=Copy(S, p+1, d-p-1);
          simbcodeflg:=False;
          If Length(c)>0 then
          Begin
            vs1:='';
            If (c[1]=#39) and (Length(c)>1) and (c[Length(c)]=#39) then
            Begin
              vs1:=GetClearParam(c, #39);
              TranscodeData[DataType][l].TranscodeType:=ttVarLen;
              simbcodeflg:=False;
            End
            Else
            Begin
              TranscodeData[DataType][l].TranscodeType:=ttDirect;

              For v1:=1 to Length(c) do
              Begin
                If simbcodeflg and (c[v1] in ['0'..'9']) then
                  vs1:=vs1+c[v1];

                If c[v1]='#' then
                Begin
                  simbcodeflg:=True;
                  If vs1<>'' then
                    TranscodeData[DataType][l].TagertCode:=TranscodeData[DataType][l].TagertCode+Chr(StrToInt(vs1));
                  vs1:='';
                End;
                If c[v1]='-' then
                Begin
                  TranscodeData[DataType][l].TranscodeType:=ttSub;
                  simbcodeflg:=True;
                  If vs1<>'' then
                    TranscodeData[DataType][l].TargetGap:=StrToInt(vs1);
                End;
                If c[v1]='+' then
                Begin
                  TranscodeData[DataType][l].TranscodeType:=ttAdd;
                  simbcodeflg:=True;
                  If vs1<>'' then
                    TranscodeData[DataType][l].TargetGap:=StrToInt(vs1);
                End;
              End;
            End;

            if simbcodeflg then
            Begin
              If vs1<>'' then
                TranscodeData[DataType][l].TagertCode:=TranscodeData[DataType][l].TagertCode+Chr(StrToInt(vs1));
            End
            Else
              If vs1<>'' then
                TranscodeData[DataType][l].TagertCode:=TranscodeData[DataType][l].TagertCode+vs1;
            vs1:='';
          End;
        End;
      End;
    End;

    Result:=True;
  End;
{$ENDIF}
end;

Function Transcode(DataType: TTranscodeDataType; const Buf: String): String;
Var
  i, j, k: LongInt;
  Match: Boolean;
  ts: String;
begin
  Result:='';
  i:=1;
  while i<=Length(Buf) Do
  Begin
    Match:=False;
    For j:=1 to Length(TranscodeData[DataType]) do
    Begin
      If (TranscodeData[DataType][j-1].SourceLiteral<>'') then
      Begin
        If TranscodeData[DataType][j-1].SourceLiteral[1]=Buf[i] then
        Begin
          If Length(TranscodeData[DataType][j-1].SourceLiteral)>1 then
          Begin
            k:=1;
            while (TranscodeData[DataType][j-1].SourceLiteral[k]=Buf[i+k]) and (k<=Length(TranscodeData[DataType][j-1].SourceLiteral)) do
            Begin
              Inc(k);
            End;
            If k=Length(TranscodeData[DataType][j-1].SourceLiteral) then
            begin
              Match:=True;
              break;
            end;
          End
          Else
          Begin
            Match:=True;
            break;
          End;
        End;
      End
      Else
        If TranscodeData[DataType][j-1].CodeFrom1=TranscodeData[DataType][j-1].CodeFrom2 then
        Begin
          If Ord(Buf[i])=TranscodeData[DataType][j-1].CodeFrom1 then
          Begin
            Match:=True;
            break;
          End;
        End
        Else
          If TranscodeData[DataType][j-1].CodeFrom1<TranscodeData[DataType][j-1].CodeFrom2 then
          Begin
            If Ord(Buf[i])>=TranscodeData[DataType][j-1].CodeFrom1 then
              If Ord(Buf[i])<=TranscodeData[DataType][j-1].CodeFrom2 then
              Begin
                Match:=True;
                break;
              End;
          End;
    End;

    If Match then
    Begin
      Case TranscodeData[DataType][j-1].TranscodeType of
      ttDirect:
        ts:=TranscodeData[DataType][j-1].TagertCode;
      ttAdd:
        ts:=Chr(Ord(Buf[i])+Ord(TranscodeData[DataType][j-1].TagertCode[1]));
      ttSub:
        ts:=Chr(Ord(Buf[i])-Ord(TranscodeData[DataType][j-1].TagertCode[1]));
      ttVarLen:
        ts:=TranscodeData[DataType][j-1].TagertCode;
      end;
    End
    Else
      ts:=Buf[i];

    Result:=Result+ts;
    Inc(i);
  End;
end;

procedure SetDefaultTranslite;
var
  i:Integer;
begin
  SetLength(TranscodeData[tdtTranslit], TransliteSimbolsCount);
  For i:=1 to TransliteSimbolsCount do
  Begin
    TranscodeData[tdtTranslit][i-1].SourceLiteral:=RusTab[i-1];
    TranscodeData[tdtTranslit][i-1].TagertCode:=LatTab[i-1];
  End;
end;

Function GetFileNameToTranslite(const FullFileName: String): String;
Var
  FileName, NewFileName, FilePath: String;
Begin
  FileName:=ExtractFileName(FullFileName);
  FilePath:=ExtractFilePath(FullFileName);

  NewFileName:=Transcode(tdtTranslit, FileName);

  Result:=FilePath+NewFileName;
End;

procedure LoadTranscodeRes(const Lang, Path: String);
Var
  FileName: String;
begin
  FileName:=IncludeTrailingPathDelimiter(DefaultLangDir)+'DCLTranslite.'+LowerCase(Lang);
  If not LoadTranscodeFile(tdtTranslit, Path+FileName) then
    SetDefaultTranslite;
end;

end.
