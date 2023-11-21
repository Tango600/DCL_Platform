unit cMeDateEdit;
{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, EditBtn;

type

  { TMyDateEdit }

  TMyDateEdit=class(TDateEdit)
  private
    FFreeDateFormat: String;

  published
    constructor Create(AOwner: TComponent); override;
    procedure EditClick; override;

    procedure SetFreeDateFormat(AValue: String);

    procedure SetDateOrderInstDateFormat(Value: String);

  published
    property DateFormat: String read FFreeDateFormat write SetFreeDateFormat;
  end;

implementation

{ TMyDateEdit }

constructor TMyDateEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

procedure TMyDateEdit.EditClick;
var
  p: Integer;
begin
  inherited EditClick;

  p:=BaseEditor.SelStart;
  case DateOrder of
  doDMY, doMDY: begin
    if (p>=0) and (p<=3) then
    begin
      BaseEditor.SelStart:=0;
      BaseEditor.SelLength:=2;
    end;
    if (p>3) and (p<=6) then
    begin
      BaseEditor.SelStart:=3;
      BaseEditor.SelLength:=2;
    end;
    if (p>6) and (p<=10) then
    begin
      BaseEditor.SelStart:=6;
      BaseEditor.SelLength:=4;
    end;
  end;
  doYMd: begin
    if (p>=0) and (p<=5) then
    begin
      BaseEditor.SelStart:=0;
      BaseEditor.SelLength:=4;
    end;
    if (p>5) and (p<=8) then
    begin
      BaseEditor.SelStart:=5;
      BaseEditor.SelLength:=2;
    end;
    if (p>8) and (p<=10) then
    begin
      BaseEditor.SelStart:=8;
      BaseEditor.SelLength:=2;
    end;
  end;
  end;
end;

procedure TMyDateEdit.SetFreeDateFormat(AValue: String);
begin
  SetDateOrderInstDateFormat(AValue);
end;

procedure TMyDateEdit.SetDateOrderInstDateFormat(Value: String);
var
  dp, mp, yp: Integer;
begin
  if Value<>'' then
  begin
    dp:=Pos('dd', Value.ToLower);
    if dp<>0 then
    begin
      mp:=Pos('mm', Value.ToLower);
      if mp<>0 then
      begin
        yp:=Pos('yyyy', Value.ToLower);
        if yp<>0 then
        begin
          if (dp<mp) and (mp<yp) then
          begin
            DateOrder:=doDMY;
            DateFormat:='';
          end
          else
          if (mp<dp) and (dp<yp) then
          begin
            DateOrder:=doMDY;
            DateFormat:='';
          end
          else
          if (yp<mp) and (mp<dp) then
          begin
            DateOrder:=doYMd;
            DateFormat:='';
          end;
        end;
      end;
    end;
  end;
end;

end.

