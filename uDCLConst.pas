unit uDCLConst;
{$I DefineType.pas}

interface

uses
{$IFnDEF FPC}
  Vcl.DBCtrls
{$ELSE}
  DBCtrls, DBGrids
{$ENDIF};

const
{$IFDEF MSWINDOWS}
  DefaultLibraryLocation='gds32.dll';
{$ENDIF}
{$IFDEF UNIX}
  DefaultLibraryLocation='libfbclient.so';
{$ENDIF}
{$IFDEF ADO}
  DBEngineType='ADODB (Universal)';
{$ENDIF}
{$IFDEF IBX}
  DBEngineType='IBX';
{$ENDIF}
{$IFDEF ZEOS}
  DBEngineType='ZEOS (Universal)';
  DefaultIBPort=3050;
  DefaultDBType='firebird-3.0';
  DefaultDBTInterBaseType='interbase-6';
{$ENDIF}
{$IFDEF SQLdbIB}
  DBEngineType='SQLdb IB';
{$ENDIF}
{$IFDEF SQLdb}
  DBEngineType='SQLdb (Universal)';
{$ENDIF}
  Version='12.0.0.0';

  JPEGCompressionQuality=85;

  ShowFormPanel=True;
  CloseButton=True;

  TextScriptFileExt='.dst';
  SignedScriptExt='.dcs';
  SignMethodVer='1.2';

  DBTypeFirebird='firebird';
  DBTypeInterbase='interbase';

  ScriptControlLanguage='VBScript';

  UserLevelsSet='ulDeny,ulReadOnly,ulWrite,ulExecute,ulLevel,ulDeveloper';

  SW_SHOWNORMAL=1;

{$IFDEF FPC}
  InternalAppNameSuffix='FPC';
  IndicatorWidth=DEFINDICATORCOLWIDTH;

  AppBuildDate={$I %DATE%};
  fpcVersion={$I %FPCVERSION%};
  TargetCPU={$I %FPCTARGETCPU%};
  TargetOS={$I %FPCTARGETOS%};
{$ENDIF}
{$IFDEF DELPHI}
  InternalAppNameSuffix='Delphi';
{$IFDEF MSWINDOWS}
  LineEnding=#13#10;
{$ENDIF}
{$IFDEF WIN32}
  TargetCPU='i386';
{$ENDIF}
{$IFDEF WIN64}
  TargetCPU='x86-64';
{$ENDIF}
{$ENDIF}
  CR=LineEnding;
{$IFDEF UNIX}
  CrossDelim='\';
  PathDelim='/';
  ConfigDir='/.config/';
  OSType='posix';
{$ENDIF}
{$IFNDEF FPC}
{$IFDEF WIN32}
  TargetOS='Windows x32';
{$ENDIF}
{$IFDEF WIN64}
  TargetOS='Windows x64';
{$ENDIF}
{$ENDIF}
{$IFDEF MSWINDOWS}
  CrossDelim='/';
  PathDelim='\';
  ConfigDir='\';
  OSType='windows';
{$ENDIF}
{$IFDEF FPC}
  GridAlternateColor=$E0DDDD;
  VK_SHIFT=16;
  VK_CONTROL=17;

  SW_SHOWNOACTIVATE=4;
  SW_NORMAL=1;
  SW_RESTORE=9;
  SW_SHOW=5;
{$ENDIF}
  MemFileName='DCL_Run_Unit_'+DBEngineType;

  EncodingUTF8='utf8';
{$IFDEF DELPHI}
  UTF8BOM=#$EF#$BB#$BF;
  UTF16LEBOM=#$FF#$FE;
  DefaultInterfaceEncoding='utf8';
{$ENDIF}
  AppTitle='DCL Platform';
  InternalAppName='DCLPlatform_'+InternalAppNameSuffix;

  ParamPrefix=':';
  FieldObjectPrefix='$';
  VariablePrefix='&';
  ParamsSepareteSimb=';';
  // DefaultValuesSeparator=',';
  // DefaultParamDelim='"';
  ProcPrefix='!!';
  MaskPassChar='#';
  ParamDelim='"';
  TabSize=2;

  PAGSignatureSize=3;
  PAGSignature=$474150;

  FloatDelimiterFrom=',';
  FloatDelimiterTo='.';
  Quote=#39;

  StopSimbols=';( )[],=\/+-^<>.%:;&$#@*'#39#10#13;

  KillerTimerInterval=400;
  IntervalTimeToInitScripts=700;
  IntervalTimeNotify=61007;
  TimeToTerminate=5000;
  ExitTime=30;
  AutoResfreshInterval=90*1000;

  MainFormName='MainForm';

  NavigatorEditButtons=[nbEdit, nbDelete, nbInsert, nbPost, nbCancel];
  NavigatorNavigateButtons=[nbFirst, nbLast, nbRefresh];

  DefaultNavigButtonsSet='First,Last,Edit,Delete,Insert,Post,Cancel,Refresh';

  DCLDir='DCL5'+PathDelim;
  FormConfigDir='Dialogs'+PathDelim;
  DefaultTimeSeparator=':';
  DefaultDateSeparator='.';
  DefaultDateFormat='dd'+DefaultDateSeparator+'mm'+DefaultDateSeparator+'yyyy';
  DefaultTimeFormat='hh'+DefaultTimeSeparator+'mm'+DefaultTimeSeparator+'ss';
  DefaultTimeStampFormat=DefaultDateFormat+' '+DefaultTimeFormat;

  StopFilterFlg=-1;

  ToolCommandsCount=3;
  ToolButtonsCmd: Array [1..ToolCommandsCount] Of String=('structure', 'print', 'find');

  KeyMarksItems=3;
  TransParams=True;

  ScrDataBlockWidth=80;

Type
  TEventsEnum=(evtScroll, evtBeforeScroll, evtDelete, evtAfterOpen, evtAfterPost, evtCancel,
    evtInsert, evtLineDblClick, evtBeforePost, evtScrollPart, evtPostPart, evtClose);
  TReliseStatus=(rsAlpha, rsBetta, rsPreRelase, rsUnstable, rsStable);
  TUserLevelsType=(ulUndefined, ulDeny, ulReadOnly, ulWrite, ulExecute, ulLevel1, ulLevel2, ulLevel3, ulLevel4,
    ulDeveloper);
  TGridStyle=(gsFields, gsFieldsHorizontal, gsGrid);
  TDataControlType=(dctMainGrid, dctSideGrid, dctTablePart, dctLookupGrid);

  TNotAllowedOperation=(dsoNone, dsoDelete, dsoInsert, dsoEdit);

  TLogOnStatus=(lsUnInitaliced, lsLogonOK, lsRejected, lsNotNeed);
  TPassStatus=(psNone, psConfirmed, psCanceled);
  TFormsNotifyAction=(fnaRefresh, fnaClose, fnaMinimize, fnaMaximaze, fnaSetMDI, fnaResetMDI,
    fnaHide, fnaShow, fnaStopAutoRefresh, fnaStartAutoRefresh, fnaPauseAutoRefresh,
    fnaResumeAutoRefresh);
  TIsDigitType=(idString, idDigit, idFloatDigit, idHex, idColor, idDateTime, idUserLevel);
  TDataStatus=(dssChanged, dssSaved);
  TNotifyActionsType=(naDone, naScriptRun, naMessage, naExecAndWait, naExec, naExitToTime);
  TQueryType=(qtMain, qtFind, qtDefault);
  TFilterType=(ftNone, ftDBFilter, ftContextFilter, ftComboFilter);
  TOfficeFormat=(ofNone, ofMSO, ofOO, ofPossible);
  TOfficeDocumentFormat=(odfNone, odfMSO97, odfMSO2007, odfOO, odfPossible);
  TDocumentType=(dtNone, dtSheet, dtText);
  TSign=(isND, isEq, isGt, isLe, isGtEq, isLeEq, isNotEq);
  TReportViewMode=(rvmOneRecord, rvmAllDS, rvmGrid, rvmMultitRecordReport, rvmBookmarcks);
  TFieldBoxType=(fbtDBField, fbtDBCheck, fbtOutBox, fbtInputBox, fbtEditBox, fbtSimplyCombo, fbtDBLookup, fbtDBCombo, fbtGrid);
  TGraficFileType=(gftNone, gftBMP, gftJPEG, gftPNG, gftIcon, gftGIF, gftTIFF, gftOther);
  TDataFieldTypeType=(dftDefault, dftMemo, dftGrafic, dftRichText, dftLogic, dftFloat);
  TSpoolType=(stNone, stSpool, stText);
  TGroupType=(gtGrafic, gtMemo, gtRichText);
  TReportType=(rtWord, rtFast);
  TFindType=(ftByIndex, ftByName, ftSQL);
  TNewQueryMode=(nqmNew, nqmFromGrid);
  TMessageType=(mbtError=0, mbtWarning=1, mbtInformation=9, mbtConfirmation=10);
  TSimplyFieldType=(sftNotDefine, sftString, sftDigit, sftFloat, sftDateTime, fstBlobMemo);
  TDCLFormCloseAction=(fcaNone, fcaClose);
  TFieldFormat=(fftNone, fftDigit, fftDate, fftTime, fftDateTime, fftTrim, fftFloat);
  TSheetFillStrategy=(sfsInsert, sfsReplace);
  TFieldParsingMode=(fpmNone, fpmCaption, fpmField);

  TTransactionType=(trtWrite, trtRead);

const
  ReleaseStatus=rsAlpha;
  ReliseStatues:Array[TReliseStatus] of String=('Alpha', 'Betta', 'Pre relase', 'Unstable', 'Stable');

implementation


end.
