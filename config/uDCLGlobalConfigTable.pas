unit uDCLGlobalConfigTable;

interface

uses
  Graphics, uDCLConst;

type
  TGPT=record
  // EnableSQLTrace,
    DebugMesseges, ExitCnf, UseMessages,
    DialogsSettings, DisableColors, DisableFieldsList,
    DisableUnload, DisableLoad, EasyIdentMode, DisableIniPasword, IBAll: Boolean;
    OneCopy, Port: Integer;
    MainColor, TablePartColor, GridColor, GridAlternateColor: TColor;
    DateSeparator, TimeSeparator, ThousandSeparator, DecimalSeparator: Char;
    ServerCodePage, DateFormat, TimeFormat, Viewer, MainFormCaption,
    DataBaseName, ScriptDir, DBPath, ServerName, DBType: String;
    SQLDialect: Byte;
    NoParamsTable, NoUsersTable, DisableLogOnWithoutUser, DisableColorScheme: Boolean;
    DBUserName, DCLUserName, DCLUserPass, EnterPass, LongRoleName, GetValueSeparator,
    IniFileName, BaseID,
    StringTypeChar,
    TimeStampFormat, DCLLongUserName, UserID, RoleID,
    DCLRoleName, DBPassword, LibPath,
    WordOLEExtension, ExcelOLEExtension: String;
    OfficeDocumentFormat: TOfficeDocumentFormat;
    OfficeFormat: TOfficeFormat;
    AccessLevel: TUserLevelsType;
    MenuType: TMenuType;
  end;

implementation

end.

