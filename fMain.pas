unit fMain;
{$I DefineType.pas}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls,
  uDCLConst, uDCLData;

type

  { TMainForm }

  TMainForm = class(TForm)
    StatusBar1: TStatusBar;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

implementation

{$R *.lfm}

{ TMainForm }

procedure TMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin

end;

function FindCommandStrParam(Str: String): String;
var
  i: Byte;
begin
  For i:=1 to ParamCount do
  begin
    if Pos(LowerCase(Str), LowerCase(ParamStr(i)))<>0 then
    begin
      Result:=Copy(ParamStr(i), Length(Str)+1, Length(ParamStr(i)));
      break;
    end;
  end;
end;

function FindMDI: Boolean;
begin
  Result:=FindCommandStrParam('MDI=')='1';
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  MDI: Boolean;
  S: String;
  T: TextFile;
begin
  Caption:='DCL Run v.'+Version;

  MDI:=False;
  if FileExists('interface.ini') then
  begin
    AssignFile(T, 'interface.ini');
    ReSet(T);
    While not EOF(T) do
    begin
      ReadLn(T, S);
      if Pos('mdi', LowerCase(S))<>0 then
        MDI:=True;
    end;
    CloseFile(T);
  end;

  if MDI or FindMDI then
    FormStyle:=fsMDIForm;
end;

end.

