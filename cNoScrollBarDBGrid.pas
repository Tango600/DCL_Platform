unit cNoScrollBarDBGrid;
{$mode Delphi}

interface

uses
  Classes, SysUtils, DBGrids;

type
  TNoScrollBarDBGrid=class(TDBGrid)
  {$IFNDEF FPC}
    private
      FScrollBars: TScrollStyle;
      procedure SetScrollBars(Value: TScrollStyle);
    published
      property ScrollBars: TScrollStyle read FScrollBars write SetScrollBars default ssBoth;
  {$ENDIF}
  end;

implementation

{$IFNDEF FPC}
procedure TNoScrollBarDBGrid.SetScrollBars(Value: TScrollStyle);
begin
  inherited;
end;
{$ENDIF}

end.

