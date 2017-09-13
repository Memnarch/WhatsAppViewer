unit WAV.Chat.Painter;

interface

uses
  WAV.Chat,
  Types,
  UITypes,
  FMX.Graphics;

type
  TElementAlign = (eaLeft, eaRight, eaCenter);

  TElementPainter = class
  private
    FElement: TChatElement;
    FBackground: TAlphaColor;
    FBoundaries: TRectF;
    FContentRect: TRectF;
    FTimeRect: TRectF;
    FAlign: TElementAlign;
    FShowTime: Boolean;
    function GetHeight: Single;
  protected
    procedure MeasureContent(const ACanvas: TCanvas; var AWidth, AHeight: Single); virtual;
    procedure PaintContent(const ACanvas: TCanvas; const ATarget: TRectF); virtual;
  public
    constructor Create;
    procedure PaintTo(const ACanvas: TCanvas; ATop: Single); virtual;
    procedure UpdateSize(const ACanvas: TCanvas; AWidth: Single); virtual;
    property Height: Single read GetHeight;
    property Element: TChatElement read FElement write FElement;
    property Background: TAlphaColor read FBackground write FBackground;
    property Align: TElementAlign read FAlign write FAlign;
    property ShowTime: Boolean read FShowTime write FShowTime;
  end;

  TTextElementPainter = class(TElementPainter)
  protected
    function GetText: string; virtual;
    procedure MeasureContent(const ACanvas: TCanvas; var AWidth: Single; var AHeight: Single); override;
    procedure PaintContent(const ACanvas: TCanvas; const ATarget: TRectF); override;
  end;

  TDateElementPainter = class(TTextElementPainter)
  protected
    function GetText: string; override;
  end;

  TImageElementPainter = class(TElementPainter)
  protected
    function GetBitmap: TBitmap;
    procedure MeasureContent(const ACanvas: TCanvas; var AWidth: Single; var AHeight: Single); override;
    procedure PaintContent(const ACanvas: TCanvas; const ATarget: TRectF); override;
  public
    procedure UpdateSize(const ACanvas: TCanvas; AWidth: Single); override;
  end;

implementation

uses
  FMX.Types,
  Math;

const
  CBubblePadding = 50;
  CInnerPadding = 5;
  CCornerRadius = 5;
  CImagePreviewSize = 200;
  CMainTextOpacity = 1;
  CSecondaryTextOpacity = 0.5;
  CTimeFontFactor = 0.8;

{ TElementPainter }

constructor TElementPainter.Create;
begin
  inherited;
  FShowTime := True;
end;

function TElementPainter.GetHeight: Single;
begin
  Result := FBoundaries.Height;
end;

procedure TElementPainter.MeasureContent(const ACanvas: TCanvas; var AWidth, AHeight: Single);
begin

end;

procedure TElementPainter.PaintContent(const ACanvas: TCanvas;
  const ATarget: TRectF);
begin

end;

procedure TElementPainter.PaintTo(const ACanvas: TCanvas; ATop: Single);
var
  LBubble, LTarget: TRectF;
  LOldFont: Single;
begin
  inherited;
  LBubble := FBoundaries;
  LBubble.Offset(0, ATop);
  ACanvas.Fill.Color := FBackground;
  ACanvas.Stroke.Color := TAlphaColorRec.Grey;
  ACanvas.Stroke.Kind := TBrushKind.Solid;
  ACanvas.FillRect(LBubble, CCornerRadius, CCornerRadius, AllCorners, 1);
  LBubble.Inflate(-1, -1);
  ACanvas.DrawRect(LBubble, CCornerRadius, CCornerRadius, AllCorners, 1);

  LTarget := FContentRect;
  LTarget.Offset(0, ATop);
  PaintContent(ACanvas, LTarget);

  if FShowTime then
  begin
    LTarget := FTimeRect;
    LTarget.Offset(0, ATop);
    LOldFont := ACanvas.Font.Size;
    ACanvas.Font.Size := LOldFont * CTimeFontFactor;
    ACanvas.Fill.Color := TAlphaColorRec.Grey;
    ACanvas.FillText(LTarget, FElement.Time, False, 1, [], TTextAlign.Trailing);
    ACanvas.Font.Size := LOldFont;
  end;
end;

procedure TElementPainter.UpdateSize(const ACanvas: TCanvas; AWidth: Single);
var
  LWidth, LHeight, LOldFontSize: Single;
const
  CMaxHeight = 9999;
begin
  if FShowTime then
  begin
    FTimeRect := TRectF.Create(0, 0, AWidth, CMaxHeight);
    LOldFontSize := ACanvas.Font.Size;
    ACanvas.Font.Size := ACanvas.Font.Size * CTimeFontFactor;
    ACanvas.MeasureText(FTimeRect, FElement.Time, False, [], TTextALign.Leading);
    FTimeRect.Offset(0, -FTimeRect.Top);
    ACanvas.Font.Size := LOldFontSize;
  end;
  LWidth := AWidth - CBubblePadding - CInnerPadding * 2;
  if FShowTime then
    LWidth := LWidth - FTimeRect.Width - CInnerPadding;
  LHeight := CMaxHeight;
  MeasureContent(ACanvas, LWidth, LHeight);
  if LHeight = CMaxHeight then
    LHeight := 0;
  FBoundaries := TRectF.Create(0, 0, LWidth + CInnerPadding*2, LHeight + CInnerPadding * 2);
  if FShowTime then
    FBoundaries.Width := FBoundaries.Width + FTimeRect.Width + CInnerPadding;
  if Align = eaRight then
    FBoundaries.Offset(AWidth - FBoundaries.Width, 0)
  else if Align = eaCenter then
    FBoundaries.Offset((AWidth - FBoundaries.Width) / 2, 0);
  FContentRect := TRectF.Create(FBoundaries.Left + CInnerPadding, CInnerPadding, 0, 0);
  FContentRect.Width := LWidth;
  FContentRect.Height := LHeight;
  if FShowTime then
    FTimeRect.Offset(FBoundaries.Left + FBoundaries.Width - FTimeRect.Width - CInnerPadding, FBoundaries.Height - FTimeRect.Height - CInnerPadding);
end;

{ TImageElementPainter }

function TImageElementPainter.GetBitmap: TBitmap;
begin
  Result := TImageChatElement(FElement).Image;
end;

procedure TImageElementPainter.MeasureContent(const ACanvas: TCanvas;
  var AWidth, AHeight: Single);
begin
  inherited;
  AWidth := Min(Min(GetBitmap.Width, CImagePreviewSize), AWidth);
  AHeight := Min(Min(GetBitmap.Height, CImagePreviewSize), AHeight);
end;

procedure TImageElementPainter.PaintContent(const ACanvas: TCanvas;
  const ATarget: TRectF);
begin
  inherited;
  ACanvas.DrawBitmap(GetBitmap, GetBitmap.BoundsF, ATarget, 1);
end;

procedure TImageElementPainter.UpdateSize(const ACanvas: TCanvas;
  AWidth: Single);
begin
  inherited;
  if FShowTime then
  begin
    //resize and move Time below Image instead of right
    FTimeRect.Offset(-(FTimeRect.Width + CInnerPadding), FTimeRect.Height + CInnerPadding);
    FBoundaries.Width := FBoundaries.Width - FTimeRect.Width - CInnerPadding;
    FBoundaries.Height := FBoundaries.Height + FTimeRect.Height + CInnerPadding;
    if Align = eaRight then
    begin
      FBoundaries.Offset(FTimeRect.Width + CInnerPadding, 0);
      FContentRect.Offset(FTimeRect.Width + CInnerPadding, 0);
      FTimeRect.Offset(FTimeRect.Width + CInnerPadding, 0);
    end;
  end;
end;

{ TTextElementPainter }

function TTextElementPainter.GetText: string;
begin
  Result := (FElement as TTextChatElement).Text;
end;

procedure TTextElementPainter.MeasureContent(const ACanvas: TCanvas; var AWidth,
  AHeight: Single);
var
  LRect: TRectF;
begin
  inherited;
  LRect := TRectF.Create(0, 0, AWidth, AHeight);
  ACanvas.MeasureText(LRect, GetText, True, [], TTextAlign.Leading, TTextAlign.Leading);
  AWidth := LRect.Width;
  AHeight := LRect.Height;
end;

procedure TTextElementPainter.PaintContent(const ACanvas: TCanvas;
  const ATarget: TRectF);
begin
  inherited;
  ACanvas.Fill.Color := TAlphaColorRec.Black;
  ACanvas.FillText(ATarget, GetText, True, 1, [], TTextAlign.Leading);
end;

{ TDateElementPainter }

function TDateElementPainter.GetText: string;
begin
  Result := FElement.Date;
end;

end.
