unit uDCLQueryUtils;
{$mode delphi}

interface

uses
  uDCLDBStructure;

function GetRolesQueryText(const Where, UserID: String): String;

implementation

function GetOutRolesQueryText(const Where: String): String;
begin
  Result:='select s.'+IdField+', s.'+IdentifyField+', s.'+ParentField+', s.'+DCLNameField+', s.'+CommandField+
    ', s.'+ScriptField+' from '+
    DCLTable+' s where '+Where+' order by s.'+IdentifyField+', s.'+ParentField;
end;

function GetRolesQueryText(const Where, UserID: String): String;
begin
  If UserID='' Then
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
    Result:=Result+' and u.'+UserIDField+'='+UserID;
    if Length(Where)>3 then
      Result:=Result+' and '+Where;
    Result:=Result+' order by s.'+IdentifyField+', s.'+ParentField;
  end;
end;

end.
