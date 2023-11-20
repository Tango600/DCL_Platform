// copyright 2021-2021 crazzzypeter
// license GNU 3.0

unit MathParser;
{$MODE DELPHI}
{$SCOPEDENUMS ON}

interface

uses
  Classes, SysUtils, Generics.Collections;

type
  EParserError = class(Exception)
  private
    FPosition: Integer;
  public
    constructor Create(const Position: Integer; const Message: string);
    property Position: Integer read FPosition;
  end;

  // Plus := '+'
  // Minus := '-'
  // Multiply := '*'
  // Divide := '/'

  // <Number> := <'0'..'9'>[.]<'0'..'9'>[e<['0'..'9']>] ...
  // <Primitive> := <'('><AddAndSub><')'> | <Number>
  // <MulAndDiv> := <Primitive> [<Multiply> | <Divide>] <Primitive> ...
  // <AddAndSub> := <MulAndDiv> [<Plus> | <Minus>] <MulAndDiv> ...

  TLogEvent = procedure (sender: TObject; str: string) of object;

  TTokenType = (ttNumber, ttPlus, ttMinus, ttMultiply, ttDivide, ttPower, ttLeftBracket, ttRightBracket, ttFunction, ttVariable,
    ttEqual, ttNotEqual, ttGrate, ttLess, ttDiv, ttMod, ttTerminal);

  TMathCall = function(): Double of object;

  TNullValue=class
    isNull: Boolean;
  end;

  { TNullDoubleValue }

  TNullDoubleValue=class(TNullValue)
    Value: Double;
    procedure SetValue(Value: Double);
  end;

  { TNullBoolValue }

  TNullBoolValue=class(TNullValue)
    Value: Boolean;
    procedure SetValue(Value: Boolean);
  end;

  { TResultValue }

  TResultValue=class
  private
    B: TNullBoolValue;
    D: TNullDoubleValue;

    function IsLogical: Boolean;
  public
    function GetValue: Double;
    function GetLogicalValue: Boolean;

    procedure SetValue(Value: Double);
    procedure SetLogical(Value: Boolean);
  end;

  { TMathParser }

  TMathParser = class sealed
  private
    FExpression: string;
    FOnLog: TLogEvent;
    procedure SetExpression(const Value: string);
  private
    FContants: TDictionary<string, Double>;
    Data: PChar;
    Position: Integer;
    PrevPosition: Integer;
    Token: TTokenType;
    Value: Double;
    Identifier: string;
    StackLevel: Integer;
    procedure NextToken;
    procedure SkipSpaces;
    function Primitive: Double;
    function AddAndSub: Double;
    function MulAndDiv: Double;
    function ExecuteFunction(const X: Double; FunctionName: string; const FunctionPosition: Integer): Double;
    procedure Log(str: string);
    function Pow: Double;
    function RecursiveCall(const Func: TMathCall): Double;
    function GetConstant(const Name: string): Double;
    procedure SetConstant(const Name: string; const Value: Double);
  public
    constructor Create;
    destructor Destroy; override;
    function Calculate: Double;
    property Expression: string read FExpression write SetExpression;
    property OnLog: TLogEvent read FOnLog write FOnLog;
    property Constants[const Name: string]: Double read GetConstant write SetConstant;
  end;

implementation

uses
  Math;

const
  MaxStackLevel = 64;

  sClosingParenthesisExpected = 'Closing parenthesis expected';
  sPrimitiveExpected = 'Primitive expected';
  sMissingOperator = 'Missing operator';
  sUnmatchedRightParenthesis = 'Unmatched right parenthesis';
  sUnexpectedSymbol = 'Unexpected symbol';
  sBadNumber = 'Bad number';
  sDivisionByZero = 'Division by zero';
  sBadFunctionArgument = 'Bad function argument';
  sBadFunction = 'Bad function';
  sOverflow = 'Overflow';
  sInternalError = 'Internal error!';
  sStackOverflow = 'Stack overflow';
  sContantNotFound = 'Constant not found';

{ TNullDoubleValue }

procedure TNullDoubleValue.SetValue(Value: Double);
begin
  Self.isNull:=False;
  Self.Value:=Value;
end;

{ TNullBoolValue }

procedure TNullBoolValue.SetValue(Value: Boolean);
begin
  Self.isNull:=False;
  Self.Value:=Value;
end;

{ TResultValue }

function TResultValue.IsLogical: Boolean;
begin
  Result:=not B.isNull;
end;

function TResultValue.GetValue: Double;
begin

end;

function TResultValue.GetLogicalValue: Boolean;
begin

end;

procedure TResultValue.SetValue(Value: Double);
begin

end;

procedure TResultValue.SetLogical(Value: Boolean);
begin

end;

{ TMathParser }

procedure TMathParser.NextToken;
var
  TokenString: string;
begin
  SkipSpaces;
  TokenString:='';
  PrevPosition := Position;

  case Data[Position] of
    '0'..'9':
    begin
      // for ex: 12.34e+56
      // 12
      Token := TTokenType.ttNumber;
      while CharInSet(Data[Position], ['0'..'9']) do
      begin
        TokenString := TokenString + Data[Position];
        Position := Position + 1;
      end;
      // .
      if Data[Position] = '.' then
      begin
        TokenString := TokenString + Data[Position];
        Position := Position + 1;
      end;
      // 34
      while CharInSet(Data[Position], ['0'..'9']) do
      begin
        TokenString := TokenString + Data[Position];
        Position := Position + 1;
      end;
      // e
      if CharInSet(Data[Position], ['e', 'E']) then
      begin
        TokenString := TokenString + Data[Position];
        Position := Position + 1;
        // +/-
        if CharInSet(Data[Position], ['-', '+']) then
        begin
          TokenString := TokenString + Data[Position];
          Position := Position + 1;
        end;
        // 56
        if not CharInSet(Data[Position], ['0'..'9']) then
          raise Exception.Create(sBadNumber);// error
        while CharInSet(Data[Position], ['0'..'9']) do
        begin
          TokenString := TokenString + Data[Position];
          Position := Position + 1;
        end;
      end;

      if not TryStrToFloat(TokenString, Value,
        {$IFNDEF FPC}TFormatSettings.Invariant{$ELSE}DefaultFormatSettings{$ENDIF}) then
        raise EParserError.Create(PrevPosition, sBadNumber);// error

      Log('NextToken: TokenType = Number, Value = ' +
        FloatToStr(Value, {$IFNDEF FPC}TFormatSettings.Invariant{$ELSE}DefaultFormatSettings{$ENDIF}));
    end;
    '+':
    begin
      Log('NextToken: TokenType = Plus');
      Token := TTokenType.ttPlus;
      Position := Position + 1;
    end;
    '-':
    begin
      Log('NextToken: TokenType = Minus');
      Token := TTokenType.ttMinus;
      Position := Position + 1;
    end;
    '*':
    begin
      Log('NextToken: TokenType = Multiply');
      Token := TTokenType.ttMultiply;
      Position := Position + 1;
    end;
    '/':
    begin
      Log('NextToken: TokenType = Divide');
      Token := TTokenType.ttDivide;
      Position := Position + 1;
    end;
    '^':
    begin
      Log('NextToken: TokenType = Power');
      Token := TTokenType.ttPower;
      Position := Position + 1;
    end;
    '=':
    begin
      Log('NextToken: TokenType = Equal');
      Token := TTokenType.ttEqual;
      Inc(Position);
    end;
    '(':
    begin
      Log('NextToken: TokenType = LeftBracket');
      Token := TTokenType.ttLeftBracket;
      Position := Position + 1;
    end;
    ')':
    begin
      Log('NextToken: TokenType = RightBracket');
      Token := TTokenType.ttRightBracket;
      Position := Position + 1;
    end;
    'a'..'z', 'A'..'Z':
    begin
      Identifier := '';
      // abc
      while CharInSet(Data[Position], ['a'..'z', 'A'..'Z', '0'..'9']) do
      begin
        Identifier := Identifier + Data[Position];
        Position := Position + 1;

        if Identifier='div' then
        begin
          Log('NextToken: TokenType = div');
          if not CharInSet(Data[Position+1], ['a'..'z', 'A'..'Z']) then
          begin
            if CharInSet(Data[Position], ['0'..'9']) or (Pos(Data[Position], '-+/^( )*')<>0) then
              Token := TTokenType.ttDiv;
          end;
          SkipSpaces;
          Exit;
        end;

        if Identifier='mod' then
        begin
          Log('NextToken: TokenType = mod');
          if CharInSet(Data[Position], ['0'..'9']) or (Pos(Data[Position], '-+/^( )*')<>0) then
          begin
            Token := TTokenType.ttMod;
          end;
          SkipSpaces;
          Exit;
        end;
      end;
      // SkipSpaces;
      // (
      if Data[Position] = '(' then
      begin
        Token := TTokenType.ttFunction;
        Position := Position + 1;
      end else
        Token := TTokenType.ttVariable;

      //raise EParserError.Create(PrevPosition, sBadFunction);  // error

      Log('NextToken: TokenType = Function, Value = ' + Identifier);
    end;
    #0, ';':
    begin
      Log('NextToken: TokenType = Terminal');
      Token := TTokenType.ttTerminal;
    end;
    else
      raise EParserError.Create(Position, sUnexpectedSymbol);// error
  end;
end;

function TMathParser.Primitive: Double;
var
  FunctionName: string;
  FunctionPos: Integer;
begin
  //NextToken;
  case Token of
    // unary operators +/-
    TTokenType.ttPlus:
    begin
      NextToken;
      Result := RecursiveCall(Primitive);
    end;
    TTokenType.ttMinus:
    begin
      NextToken;
      Result := -RecursiveCall(Primitive);
    end;
    // primitives
    TTokenType.ttNumber:
    begin
      NextToken;
      Result := Value;
    end;
    TTokenType.ttLeftBracket:
    begin
      NextToken;
      Result := RecursiveCall(AddAndSub);
      if Token <> TTokenType.ttRightBracket then
        raise EParserError.Create(PrevPosition, sClosingParenthesisExpected);// error
      NextToken;
    end;
    TTokenType.ttFunction:
    begin
      FunctionName := UpperCase(Identifier);// hmmm...
      FunctionPos := PrevPosition;
      NextToken;
      Result := RecursiveCall(AddAndSub);
      if Token <> TTokenType.ttRightBracket then
        raise EParserError.Create(Position, sClosingParenthesisExpected);// error
      Result := ExecuteFunction(Result, FunctionName, FunctionPos);
      NextToken;
    end;
    TTokenType.ttVariable:
    begin
      if FContants.ContainsKey(UpperCase(Identifier)) then
        Result := FContants[UpperCase(Identifier)]
      else
        raise EParserError.Create(PrevPosition, sContantNotFound);// error
      NextToken;
    end
    else
      raise EParserError.Create(PrevPosition, sPrimitiveExpected);// error
  end;

  //if Token in [TTokenType.Number, TTokenType.LeftBracket, TTokenType.&Function] then
  //  raise EParserError.Create(PrevPosition, sMissingOperator);// error
end;

function TMathParser.Pow: Double;
begin
  Result := Primitive;

  while True do
  begin
    case Token of
      // ^
      TTokenType.ttPower:
      begin
        NextToken;
        Result := Power(Result, RecursiveCall(Pow));
      end;
      else
        break;
    end;
  end;
end;

function TMathParser.MulAndDiv: Double;
var
  RightValue: Double;
  DividerPos: Integer;
begin
  Result := Pow;

  while True do
  begin
    case Token of
      // *
      TTokenType.ttMultiply:
      begin
        NextToken;
        Result := Result * Pow;
      end;
      // /
      TTokenType.ttDivide:
      begin
        NextToken;
        DividerPos := PrevPosition;
        RightValue := Pow;
        if RightValue = 0.0 then
          raise EParserError.Create(DividerPos, sDivisionByZero);
        Result := Result / RightValue;
      end;
      TTokenType.ttDiv:
      begin
        NextToken;
        DividerPos := PrevPosition;
        RightValue := Pow;
        if RightValue = 0.0 then
          raise EParserError.Create(DividerPos, sDivisionByZero);
        Result := Trunc(Result) div Trunc(RightValue);
      end;
      TTokenType.ttMod:
      begin
        NextToken;
        DividerPos := PrevPosition;
        RightValue := Pow;
        if RightValue = 0.0 then
          raise EParserError.Create(DividerPos, sDivisionByZero);
        Result := Result mod RightValue;
      end;
      else
        break;
    end;
  end;
end;

function TMathParser.AddAndSub: Double;
begin
  Result := MulAndDiv;

  while True do
  begin
    case Token of
      // +
      TTokenType.ttPlus:
      begin
        NextToken;
        Result := Result + MulAndDiv;
      end;
      // -
      TTokenType.ttMinus:
      begin
        NextToken;
        Result := Result - MulAndDiv;
      end;
      else
        break;
    end;
  end;
end;

function TMathParser.Calculate: Double;
var
  Mask: {$IFNDEF FPC}TArithmeticExceptionMask{$ELSE}TFPUExceptionMask{$ENDIF};
begin
  Position := 0;
  StackLevel := 0;

  Mask := SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
  try
    NextToken;
    Result := AddAndSub;

    if Token = TTokenType.ttRightBracket then
      raise EParserError.Create(PrevPosition, sUnmatchedRightParenthesis);  // error

    if Token <> TTokenType.ttTerminal then
      raise EParserError.Create(PrevPosition, sMissingOperator);  // error

    if IsInfinite(Result) then
      raise EParserError.Create(0, sOverflow);  // error
  finally
    SetExceptionMask(Mask);
  end;
end;

function TMathParser.RecursiveCall(const Func: TMathCall): Double;
begin
  StackLevel := StackLevel + 1;
  if StackLevel > MaxStackLevel then
    raise EParserError.Create(PrevPosition, sStackOverflow);
  Result := Func();
  StackLevel := StackLevel - 1;
end;

constructor TMathParser.Create;
begin
  FContants := TDictionary<string, Double>.Create;
  FContants.Add('PI', System.Pi);
  Data := PChar(FExpression);
end;

destructor TMathParser.Destroy;
begin
  FContants.Free;
  inherited;
end;

function TMathParser.ExecuteFunction(const X: Double; FunctionName: string; const FunctionPosition: Integer): Double;
begin
  if IsNan(X) then
    Exit(NaN);

  if FunctionName = 'SQRT' then
  begin
    if X < 0 then
      raise EParserError.Create(FunctionPosition, sBadFunctionArgument);
    Result := Sqrt(X);
  end
  else if FunctionName = 'ABS' then
    Result := Abs(X)
  else if FunctionName = 'TRUNC' then
    Result := Trunc(X)
  else if FunctionName = 'ROUND' then
    Result := Round(X)
  else if FunctionName = 'SIN' then
    Result := Sin(X)
  else if FunctionName = 'COS' then
    Result := Cos(X)
  else if FunctionName = 'TAN' then
    Result := Tan(X)
  else if FunctionName = 'ARCSIN' then
  begin
    if (X < -1) or (X > 1) then
      raise EParserError.Create(FunctionPosition, sBadFunctionArgument);
    Result := ArcSin(X);
  end
  else if FunctionName = 'ARCCOS' then
  begin
    if (X < -1) or (X > 1) then
      raise EParserError.Create(FunctionPosition, sBadFunctionArgument);
    Result := ArcCos(X);
  end
  else if FunctionName = 'ARCTAN' then
  begin
    Result := ArcTan(X);
  end
  else if FunctionName = 'LOG' then
  begin
    if (X <= 0) then
      raise EParserError.Create(FunctionPosition, sBadFunctionArgument);
    Result := Log10(X);
  end
  else if FunctionName = 'EXP' then
  begin
    Result := Exp(X);
  end else
    raise EParserError.Create(FunctionPosition, sBadFunction);
end;

function TMathParser.GetConstant(const Name: string): Double;
begin
  Result := FContants[UpperCase(Name)];
end;

procedure TMathParser.Log(str: string);
begin
  if Assigned(FOnLog) then
    FOnLog(self, str);
end;

procedure TMathParser.SetConstant(const Name: string; const Value: Double);
begin
  FContants.AddOrSetValue(UpperCase(Name), Value);
end;

procedure TMathParser.SetExpression(const Value: string);
begin
  FExpression := Value;
  Data := PChar(FExpression);
end;

procedure TMathParser.SkipSpaces;
begin
  while CharInSet(Data[Position], [#9, ' ']) do
  begin
    Position := Position + 1;
  end;
end;

{ EPerserError }

constructor EParserError.Create(const Position: Integer; const Message: string);
begin
  inherited Create('Error: ' + Message + ' at ' + IntToStr(Position));
  FPosition := Position;
end;

end.
