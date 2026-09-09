unit fMessageForm;
{$mode Delphi}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ActnList;

type

  { TMessageForm }

  TMessageForm = class(TForm)
    aEsc: TAction;
    ActionList1: TActionList;
    GroupBox1: TGroupBox;
    MessageMemo: TMemo;
    procedure aEscExecute(Sender: TObject);
  private

  public
    constructor Create(UserName, Message: String); overload;
  end;

implementation

{$R *.lfm}

{ TMessageForm }

procedure TMessageForm.aEscExecute(Sender: TObject);
begin
  Close;
end;

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

