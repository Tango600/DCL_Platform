unit uDCLGlobalConfigTable;
{$I DefineType.pas}

interface

uses
  uDCLConst;

type
  TGPT=record
  // EnableSQLTrace,
    DebugMesseges, OneCopy, ExitCnf, UseMessages, UserLogging, UserLoggingHistory, DebugOn,
    DisableFieldsList, HashPass, ShowPicture, DialogsSettings, DisableColors,
    DisableIniPasword, IBAll: Boolean;
    CurrentRunningScrString, CurrentRunningCmdString, Port: Integer;
    DateSeparator, TimeSeparator: Char;
    ServerCodePage, DateFormat, TimeFormat, Viewer, ConnectionString, MainFormCaption,
    NewConnectionString, DBPath, ServerName, NewDBUserName, DBType, GeneratorName: String;
    SQLDialect: Byte;
    NoParamsTable, NoUsersTable, DisableLogOnWithoutUser, MultiRolesMode: Boolean;
    DBUserName, DCLUserName, DCLUserPass, EnterPass, LongRoleName, GetValueSeparator,
    IniFileName, BaseID,
    StringTypeChar, ShowRoleField,
    TimeStampFormat, DCLLongUserName, UserID, RoleID,
    DCLRoleName, NewDBPassword, DBPassword, LibPath,
    WordOLEExtension, ExcelOLEExtension: String;
    OfficeDocumentFormat: TOfficeDocumentFormat;
    OfficeFormat: TOfficeFormat;
    AccessLevel: TUserLevelsType;
  end;

implementation

end.

