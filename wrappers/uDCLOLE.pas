unit uDCLOLE;
{$mode Delphi}

interface

uses
  types, Variants, ComObj, ActiveX;

function IsWordInstall: Boolean;
function IsWriterInstall: Boolean;
function IsExcelInstall: Boolean;
function IsOOInstall: Boolean;

implementation

Function IsOLEObjectInstalled(Name: String): Boolean;
Var
  ClassID: TCLSID;
  Rez: HRESULT;
Begin
  Rez:=CLSIDFromProgID(PWideChar(WideString(Name)), ClassID);
  Result:=Rez=S_OK;
End;

function IsWordInstall: Boolean;
begin
  Result:=IsOLEObjectInstalled('Word.Application');
end;

function IsExcelInstall: Boolean;
begin
  Result:=IsOLEObjectInstalled('Excel.Application');
end;

function IsOOInstall: Boolean;
begin
  Result:=IsOLEObjectInstalled('com.sun.star.ServiceManager');
end;

function IsWriterInstall: Boolean;
begin
  Result:=IsOLEObjectInstalled('com.sun.star.ServiceManager');
end;

end.
