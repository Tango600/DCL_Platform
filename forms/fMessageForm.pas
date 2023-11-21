unit fMessageForm;
{$mode Delphi}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TMessageForm }

  TMessageForm = class(TForm)
    GroupBox1: TGroupBox;
    MessageMemo: TMemo;
  private

  public
    constructor Create(UserName, Message: String); overload;
  end;

implementation

{$R *.lfm}

{ TMessageForm }

constructor TMessageForm.Create(UserName, Message: String);
var
  NowTimeStr: String;
begin
  inherited Create(Application);
  MessageMemo.Clear;
  MessageMemo.Text:=Message;

  NowTimeStr:=DateToStr(Date)+' '+TimeToStr(SysUtils.Time);
  Self.Caption:=UserName+' : '+NowTimeStr;
end;

end.

