unit uDCLGlobalConfigTable;

interface

uses
  uDCLConst;

type
  TGPT=record
  // EnableSQLTrace,
    DebugMesseges, ExitCnf, UseMessages,
    DialogsSettings, DisableColors, DisableFieldsList,
    DisableIniPasword, IBAll: Boolean;
    OneCopy, CurrentRunningScrString, CurrentRunningCmdString, Port: Integer;
    DateSeparator, TimeSeparator, ThousandSeparator, DecimalSeparator: Char;
    ServerCodePage, DateFormat, TimeFormat, Viewer, ConnectionString, MainFormCaption,
    NewConnectionString, DBPath, ServerName, DBType: String;
    SQLDialect: Byte;
    NoParamsTable, NoUsersTable, DisableLogOnWithoutUser: Boolean;
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

