unit uDCLMultiLang;
{$I DefineType.pas}

interface

uses
  SysUtils, Classes, translations, TypInfo,
{$IFDEF FPC}
  LazUTF8,
{$ENDIF}
  uDCLConst;

type
  TStringMessages=(msNone, msClose, msOpen, msEdit, msDelete, msModified, msInputVulues, msInBegin,
    msInEnd, msPrior, msNext, msCancel, msRefresh, msInsert, msPost, msEmptyUserName, msPage, msApplay,
    msConnectDBError, msClearContent, msConnectionStringIncorrect, msNoField, msDeleteRecord,
    msLoad, msClear, msSave, msNotAllow, msOpenForm, msExecuteApps, msText, msAll, msFormated,
    msConfigurationFile, msNotFoundM, msNotFoundF, msTable, msAppRunning, msNot, msNotSupportedS,
    msPaths, msTheProduct, msProducer, msVersion, msStatus, msUser, msRole, msDataBase, msConfiguration,
    msDebugMode, msInformationAbout, msBuildOf, msOS, msLang, msUsers, msDoYouWontTerminate, msClearAllFind,
    msApplication, msDownloadInProgress, msFind, msFindCurrCell, msPrint, msCopy, msCut, msPast, msBookmark,
    msStructure, msGotoBookmark, msOldFormat, msVersionsGap, msOldVersion, msDeleteTempFilter,
    msChangePassord, msOldM, msNewM, msPassword, msConfirm, msHashed, msToHashing, msToAll, msIn,
    msLogonToSystem, msUserName, msNoYes, msDenyMessageDev, msDenyMessageUsr, msAccessLevelsSet, msNotifyActionsSet,
    msCodePage, msLock, msUnLock, msChoose, msEditings, msData, msReset, msSettings, msFields,
    msBookmarks, msHour, msMinute, msSecond, msMSecond, msModeOff, msModeOn, msStringNum, msVisualCommand,
    msConnectionError, msErrorQuery, msBadFindParams, msErrorInExpression, msErrorQueryInExpression,
    msTooMachParams, msBadFieldFormad, msNoDATARegion, msNoTemplatesTable, msTemplateNotFound, msLabelNotFound,
    msTemplFileNotFound, msTableUsersNotFound, msOONotInstalled, msFailOpenDocument, msMSNotInstalled, msWord2000Req,
    msNoOfficeInstalled, msConvertionError, msAppRunError, msFileNotFound, msErrorInRaightExpression, msFieldNotFound,
    msJanuary, msFebruary, msMarch, msApril, msMay, msJune, msJuly, msAugust, msSeptember, msOctober, msNovember,
    msDecember, msMonday, msTuesday, msWednesday, msThursday, msFriday, msSaturday, msSunday, msEditPassword,
    msOldPassword, msNewPassword, msHashPassword, msResetAllFieldsSettings, msResetAllFieldsSettingsQ,
    msResetFieldsSettings, msResetFieldsSettingsQ, msDeleteAllBookmarks, msDeleteAllBookmarksQ, msSaveFieldsSettings,
    msNotAllowOpenForm, msDeleteRecordQ, msNotAllowExecuteApps, msPathsNotSupported, msSaveEditings, msSaveEditingsQ,
    msDoYouWontTerminateApplicationQ, msConfigurationFileNotFound, msClearContentQ, msNotifycation, msForUser,
    msLoading, msTimeToExit, msDSStateSet, msCloseDialogQuery, msNotFilter, msCantOpenForUpdatePackage,
    msPackageSignNotValid, msFildsNotInputValue);


  procedure LoadLangFile(const FileName: String);
  procedure LoadLangRes(const Lang, Path: String);
  function GetDCLMessageString(MessID: TStringMessages): String;
  function GetDCLErrorString(ErrorCode: Integer; const AddText: String=''): String;
  function GetLacalaizedMonthName(MonthNum: Integer): String;

  procedure InitLangEnv;

const
  DefaultLangDir='lang';
  DefaultLanguage='ru';
  StringDelim=#39;

var
  LangName: String;
  StringMessages: Array[TStringMessages] of String;

implementation

function GetDCLMessageStringDefault(MesID: TStringMessages): String;
begin
  If LangName.ToLower=DefaultLanguage then
  Begin
    case MesID of
    msNone:
    Result:='<Нет>';
    msNot:
    Result:='не';
    msIn:
    Result:='В';
    msClose:
    Result:='Закрыть';
    msCloseDialogQuery:
    Result:='Закрыть?';
    msOpen:
    Result:='Открыть';
    msEdit:
    Result:='Изменить';
    msDelete:
    Result:='Удалить';
    msDeleteRecord:
    Result:='Удалить запись';
    msClearContent:
    Result:='Очистить содержимое';
    msModified:
    Result:='Изменено';
    msInputVulues:
    Result:='Ввод значений';
    msInBegin:
    Result:='В начало';
    msInEnd:
    Result:='В конец';
    msPrior:
    Result:='Назад';
    msNext:
    Result:='Вперёд';
    msCancel:
    Result:='Отменить';
    msRefresh:
    Result:='Обновить';
    msInsert:
    Result:='Добавить';
    msPost:
    Result:='Записать';
    msEmptyUserName:
    Result:='Не заполнено имя пользователя.';
    msPage:
    Result:='Страница';
    msConnectDBError:
    Result:='Не удалось подсоединиться к БД.';
    msConnectionStringIncorrect:
    Result:='Строка соединения не корректна.';
    msNoField:
    Result:='Нет поля:';
    msLoad:
    Result:='Загрузить';
    msClear:
    Result:='Очистить';
    msApplay:
    Result:='Принять';
    msSave:
    Result:='Сохранить';
    msNotAllow:
    Result:='Вам не разрешено';
    msOpenForm:
    Result:='открывать эту форму.';
    msExecuteApps:
    Result:='запускать приложения.';
    msText:
    Result:='Текст';
    msAll:
    Result:='все';
    msFormated:
    Result:='Форматированный';
    msConfigurationFile:
    Result:='Файл конфигурации';
    msNotFoundM:
    Result:='не найден';
    msNotFoundF:
    Result:='не найдена';
    msTable:
    Result:='Таблица';
    msAppRunning:
    Result:='Приложение уже запущено (возможно оно свернуто на панели задач).';
    msNotSupportedS:
    Result:='не поддерживаются';
    msPaths:
    Result:='пути';
    msTheProduct:
    Result:='Продукт';
    msProducer:
    Result:='Изготовитель';
    msVersion:
    Result:='Версия';
    msStatus:
    Result:='статус';
    msUser:
    Result:='Пользователь';
    msRole:
    Result:='Роль';
    msDataBase:
    Result:='База данных';
    msConfiguration:
    Result:='Конфигурация';
    msDebugMode:
    Result:='Режим отладки';
    msInformationAbout:
    Result:='Сведения о';
    msBuildOf:
    Result:='сборке';
    msOS:
    Result:='ОС';
    msLang:
    Result:='Язык';
    msUsers:
    Result:='пользователей';
    msDoYouWontTerminate:
    Result:='Хотите завершить';
    msApplication:
    Result:='приложение';
    msDownloadInProgress:
    Result:='Идёт закачка';
    msClearAllFind:
    Result:='Очистить поиск';
    msFind:
    Result:='Поиск';
    msFindCurrCell:
    Result:='Фильтр по текущей ячейки';
    msPrint:
    Result:='Печать';
    msCopy:
    Result:='Копировать';
    msCut:
    Result:='Вырезать';
    msPast:
    Result:='Вставить';
    msBookmark:
    Result:='закладка';
    msBookmarks:
    Result:='закладки';
    msStructure:
    Result:='Структура';
    msGotoBookmark:
    Result:='Перейти к закладке';
    msOldFormat:
    Result:='Старый формат';
    msVersionsGap:
    Result:='Существенная разница в версиях. Всё может не работать.';
    msOldVersion:
    Result:='Старая версия. Некоторые особенности могут не работать.';
    msToAll:
    Result:='Всем';
    msChangePassord:
    Result:='Смена пароля';
    msOldM:
    Result:='Старый';
    msNewM:
    Result:='Новый';
    msPassword:
    Result:='пароль';
    msConfirm:
    Result:='Подтверждение';
    msHashed:
    Result:='Хешированный';
    msToHashing:
    Result:='Хешировать';
    msLogonToSystem:
    Result:='Вход в систему';
    msUserName:
    Result:='Имя пользователя';
    msNoYes:
    Result:='Нет,Да';
    msDenyMessageDev:
    Result:='У Вас нет права разработчика.';
    msDenyMessageUsr:
    Result:='Вам не разрешён вход в систему.';
    msAccessLevelsSet:
    Result:='Не определено,Отключен,Только чтение,Запись,Полные права,Уровень 1,Уровень 2,Уровень 3,Уровень 4,Оператор обновления,Оператор пакетов,Разработчик';
    msNotifyActionsSet:
    Result:='Выполнено,Запуск скрипта,Сообщение,Запуск приложения с ожиданием,Запуск приложения,Выход по времени';
    msCodePage:
    Result:='Кодовая страница';
    msLock:
    Result:='Заблокировать';
    msChoose:
    Result:='Выбрать';
    msEditings:
    Result:='изменения';
    msData:
    Result:='Данные';
    msReset:
    Result:='Сбросить';
    msSettings:
    Result:='Настройки';
    msFields:
    Result:='полей';
    msHour:
    Result:='ч';
    msMinute:
    Result:='м';
    msSecond:
    Result:='сек';
    msMSecond:
    Result:='мсек';
    msModeOff:
    Result:='Выкл';
    msModeOn:
    Result:='Вкл';
    msStringNum:
    Result:='строке №';
    msVisualCommand:
    Result:='Визуальный/Коммандный';
    msConnectionError:
    Result:='Ошибка соединения';
    msErrorQuery:
    Result:='Ошибочный запрос.';
    msBadFindParams:
    Result:='Ошибочный запрос или не верные условия поиска.';
    msErrorInExpression:
    Result:='Ошибка в выражении.';
    msErrorQueryInExpression:
    Result:='Ошибочный запрос в параметре.';
    msTooMachParams:
    Result:='Недостаточно или много параметров в предложении.';
    msBadFieldFormad:
    Result:='Неверный формат полей.';
    msNoDATARegion:
    Result:='Нет области данных "DATA".';
    msNoTemplatesTable:
    Result:='Нет таблицы шаблонов.';
    msTemplateNotFound:
    Result:='Нет такого шаблона - ';
    msLabelNotFound:
    Result:='Такой метки нет.';
    msTemplFileNotFound:
    Result:='Нет файла шаблона.';
    msTableUsersNotFound:
    Result:='Таблица пользователей не найдена.';
    msOONotInstalled:
    Result:='OpenOffice не установлен.';
    msFailOpenDocument:
    Result:='Открыть документ не удалось.';
    msMSNotInstalled:
    Result:='Microsoft Office не установлен.';
    msWord2000Req:
    Result:='Требуется WORD 2000/XP или выше.';
    msNoOfficeInstalled:
    Result:='Никакой офис не установлен.';
    msConvertionError:
    Result:='Ошибка преобразования.';
    msAppRunError:
    Result:='Ошибка запуска.';
    msFileNotFound:
    Result:='Файл не найден.';
    msErrorInRaightExpression:
    Result:='Ошибка в выражении прав доступа.';
    msFieldNotFound:
    Result:='Поле не найдено.';
    msJanuary:
    Result:='Январь';
    msFebruary:
    Result:='Февраль';
    msMarch:
    Result:='Март';
    msApril:
    Result:='Апрель';
    msMay:
    Result:='Май';
    msJune:
    Result:='Июнь';
    msJuly:
    Result:='Июль';
    msAugust:
    Result:='Август';
    msSeptember:
    Result:='Сентябрь';
    msOctober:
    Result:='Октябрь';
    msNovember:
    Result:='Ноябрь';
    msDecember:
    Result:='Декабрь';
    msMonday:
    Result:='Понедельник';
    msTuesday:
    Result:='Вторник';
    msWednesday:
    Result:='Среда';
    msThursday:
    Result:='Четверг';
    msFriday:
    Result:='Пятница';
    msSaturday:
    Result:='Суббота';
    msSunday:
    Result:='Воскресенье';
    msEditPassword:
    Result:='Изменить пароль';
    msOldPassword:
    Result:='Старый пароль';
    msNewPassword:
    Result:='Новый пароль';
    msHashPassword:
    Result:='Хешировать пароль';
    msResetAllFieldsSettings:
    Result:='Сбросить настройки всех полей';
    msResetAllFieldsSettingsQ:
    Result:=GetDCLMessageStringDefault(msResetAllFieldsSettings)+'?';
    msResetFieldsSettings:
    Result:='Сбросить настройки полей';
    msResetFieldsSettingsQ:
    Result:=GetDCLMessageStringDefault(msResetFieldsSettings)+'?';
    msDeleteAllBookmarks:
    Result:='Удалить все закладки';
    msDeleteAllBookmarksQ:
    Result:=GetDCLMessageStringDefault(msDeleteAllBookmarks)+'?';
    msSaveFieldsSettings:
    Result:='Сохранить настройки полей';
    msNotAllowOpenForm:
    Result:='Вам не разрешено открывать формы';
    msDeleteRecordQ:
    Result:=GetDCLMessageStringDefault(msDeleteRecord)+'?';
    msPathsNotSupported:
    Result:='пути не поддерживаются';
    msSaveEditings:
    Result:='Сохранить изменения';
    msSaveEditingsQ:
    Result:=GetDCLMessageStringDefault(msSaveEditings)+'?';
    msDoYouWontTerminateApplicationQ:
    Result:='Завершить приложение?';
    msConfigurationFileNotFound:
    Result:='Файл конфигурации не найден';
    msClearContentQ:
    Result:=GetDCLMessageStringDefault(msClearContent)+'?';
    msNotifycation:
    Result:='Уведомление';
    msForUser:
    Result:='Для пользователя';
    msLoading:
    Result:='Загрузка';
    msTimeToExit:
    Result:='Выход из системы через %d секунд.';
    msDSStateSet:
    Result:='Не активен,Просмотр,Редактирование,Вставка,Установка ключа,Вычисляемые поля,Фильтрация,Новое значение,Старое значение,Текущее значение,Блочное чтение,Внутренне вычисление,Открытие';
    msNotFilter:
    Result:='Исключение';
    msDeleteTempFilter:
    Result:='Убрать врем. фильтр';
    msCantOpenForUpdatePackage:
    Result:='Нельзя загрузить пакет для обновления.';
    msPackageSignNotValid:
    Result:='Подпись пакета не верна.';
    msFildsNotInputValue:
    Result:='Не все обязательные поля заполнены!';
    end;
  End;
end;

function GetDCLMessageString(MessID: TStringMessages): String;
begin
  Result:=StringMessages[MessID];
end;

function GetDCLErrorString(ErrorCode: Integer; const AddText: String=''): String;
Var
  MessageText: String;
Begin
  MessageText:='';
  Case ErrorCode Of
  -2, -3:
  MessageText:=GetDCLMessageString(msConnectionError);
  -1100, -1101, -1119, -1102, -1106, -1107, -1112, -1200, -1201, -1113, -1114, -1115, -1116, -1118:
  MessageText:=GetDCLMessageString(msErrorQuery)+' '+IntToStr(ErrorCode);
  -1111:
  MessageText:=GetDCLMessageString(msBadFindParams)+' '+IntToStr(ErrorCode);
  -1103, -1104, -1105, -1108, -1110, -1117:
  MessageText:=GetDCLMessageString(msErrorInExpression)+' '+IntToStr(ErrorCode);
  -1109:
  MessageText:=GetDCLMessageString(msErrorQueryInExpression)+' '+IntToStr(ErrorCode);
  -4000:
  MessageText:=GetDCLMessageString(msTooMachParams)+' '+IntToStr(ErrorCode);
  -4002:
  MessageText:=GetDCLMessageString(msBadFieldFormad)+' '+IntToStr(ErrorCode);
  -5002:
  MessageText:=GetDCLMessageString(msNoDATARegion)+' '+IntToStr(ErrorCode);
  -5003:
  MessageText:=GetDCLMessageString(msNoTemplatesTable)+' '+IntToStr(ErrorCode);
  -5004:
  MessageText:=GetDCLMessageString(msTemplateNotFound)+' '+IntToStr(ErrorCode);
  -5005:
  MessageText:=GetDCLMessageString(msLabelNotFound)+' '+IntToStr(ErrorCode);
  -5006, -5007:
  MessageText:=GetDCLMessageString(msTemplFileNotFound)+' '+IntToStr(ErrorCode);
  -5008:
  MessageText:=GetDCLMessageString(msTableUsersNotFound)+' '+IntToStr(ErrorCode);
  -6001, -6002: // OOo
  MessageText:=GetDCLMessageString(msOONotInstalled)+' '+IntToStr(ErrorCode);
  -6003:
  MessageText:=GetDCLMessageString(msFailOpenDocument)+' '+IntToStr(ErrorCode);
  -6000, -6010:
  MessageText:=GetDCLMessageString(msMSNotInstalled)+' '+IntToStr(ErrorCode);
  -6011:
  MessageText:=GetDCLMessageString(msWord2000Req)+' '+IntToStr(ErrorCode);
  -6020:
  MessageText:=GetDCLMessageString(msNoOfficeInstalled)+' '+IntToStr(ErrorCode);
  -7000:
  MessageText:=GetDCLMessageString(msConvertionError)+' '+IntToStr(ErrorCode);
  -8000:
  MessageText:=GetDCLMessageString(msAppRunError)+' '+IntToStr(ErrorCode);
  -8001:
  MessageText:=GetDCLMessageString(msFileNotFound)+' '+IntToStr(ErrorCode);
  -9000:
  MessageText:=GetDCLMessageString(msErrorInRaightExpression)+' '+IntToStr(ErrorCode);
  -10000, -10001, -10002:
  MessageText:=GetDCLMessageString(msFieldNotFound)+' '+IntToStr(ErrorCode);
  -11000:
  MessageText:=GetDCLMessageString(msFildsNotInputValue)+' '+IntToStr(ErrorCode);
  End;

  Result:=MessageText+LineEnding+AddText;
End;

procedure LoadLangFile(const FileName: String);
var
  LangResFile: TStringList;
  MessID: TStringMessages;
  S, msID, MessageString: String;
  i, p, k, Delims, StartDelim, EndDelim: Integer;
begin
{$IFNDEF SINGLELANG}
  If FileExists(FileName) then
  Begin
    LangResFile:=TStringList.Create;
    LangResFile.LoadFromFile(FileName, TEncoding.UTF8);

    For i:=1 to LangResFile.Count do
    Begin
      S:=LangResFile[i-1];

      p:=Pos(':=', S);
      If p>0 then
      Begin
        msID:=LowerCase(Trim(Copy(S, 1, p-1)));
        Delims:=-1;
        StartDelim:=-1;
        EndDelim:=-1;
        For k:=p to Length(S) do
        Begin
          If Delims=-1 then
          Begin
            If S[k]=StringDelim then
            Begin
              Inc(Delims);
              StartDelim:=k+1;
            End;
          End
          Else
          begin
            If Delims=0 then
              If S[k]=StringDelim then
              Begin
                Dec(Delims);
                EndDelim:=k-1;
              End;
          end;
        End;

        If (StartDelim<EndDelim) and (StartDelim>0) then
        Begin
          MessageString:=Copy(S, StartDelim, EndDelim-StartDelim+1);

          k:=GetEnumValue(TypeInfo(TStringMessages), msID);

          if k<>-1 then
          Begin
            If MessageString<>'' then
              StringMessages[TStringMessages(k)]:=MessageString
            Else
              StringMessages[TStringMessages(k)]:=GetDCLMessageStringDefault(TStringMessages(k));
          End;
        End;
      End;
    End;

    LangResFile.Free;
  End
  Else
{$ENDIF}
    For MessID in TStringMessages do
    begin
      StringMessages[TStringMessages(MessID)]:=GetDCLMessageStringDefault(TStringMessages(MessID));
    end;
end;

procedure LoadLangRes(const Lang, Path: String);
var
  FileName: String;
begin
  FileName:=IncludeTrailingPathDelimiter(DefaultLangDir)+'DCLTranslate.'+LowerCase(Lang);
  LoadLangFile(Path+FileName);
end;

function GetLacalaizedMonthName(MonthNum: Integer): String;
begin
  If (MonthNum>0) and (MonthNum<13) then
    Result:=GetDCLMessageString(TStringMessages(MonthNum+Ord(msJanuary)-1))
  Else
    Result:='';
end;

function GetSystemLanguage: String;
var
  LanguageID: TLanguageID;
begin
  LanguageID:=GetLanguageID;
  if LanguageID.LanguageCode='' then
    Result:=DefaultLanguage
  else
    Result:=LanguageID.LanguageCode.ToLower;
end;

procedure InitLangEnv;
begin
  LangName:=GetSystemLanguage;
end;

end.
