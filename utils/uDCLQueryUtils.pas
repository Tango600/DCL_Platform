unit uDCLQueryUtils;
{$mode delphi}

interface

uses
  uDCLDBStructure, uDCLGlobalVariables;

function GetRolesQueryText(Where, UserID: String): String;
function GetOutRolesQueryText(Where: String): String;

implementation

function GetRolesQueryText(Where, UserID: String): String;
begin
  If GPT.DCLUserName='' Then
  begin
    Result:=GetOutRolesQueryText(Where);
  end
  else
  begin
    Result:='select distinct s.'+IdField+', s.'+IdentifyField+', s.'+ParentField+', s.'+DCLNameField+', s.'+CommandField+
      ', s.'+ScriptField+' from '+
      DCLTable+' s, '+RolesMenuTable+' rm, '+RolesTable+' r, '+UsersTable+' u, '+
      RolesToUsersTable+' ru '+' where r.'+RolesIDFiled+'=rm.'+RolesMenuIDFiled+' and rm.'+RoleMenuItemIDField+'=s.'+
      IdentifyField+' and ru.'+RolesToUsersRoleIDField+'=r.'+RolesIDFiled+' and u.'+UserIDField+
      '=ru.'+RolesToUsersUserIDField;
    if UserID<>'' then
      Result:=Result+' and u.'+UserIDField+'='+UserID;
    if Length(Where)>3 then
      Result:=Result+' and '+Where;
    Result:=Result+' order by s.'+IdentifyField+', s.'+ParentField;
  end;
end;

function GetOutRolesQueryText(Where: String): String;
begin
  Result:='select s.'+IdField+', s.'+IdentifyField+', s.'+ParentField+', s.'+DCLNameField+', s.'+CommandField+
    ', s.'+ScriptField+' from '+
    DCLTable+' s where '+Where+' order by s.'+IdentifyField+', s.'+ParentField;
end;

end.
