unit WAV.Chat.Painter;

interface

uses
  WAV.Chat,
  Types,
  UITypes,
  FMX.Graphics;

type
  TElementAlign = (eaLeft, eaRight);

  TElementPainter = class
  private
    FElement: TChatElement;
    FBackground: TAlphaColor;
    FBoundaries: TRectF;
    FContentRect: TRectF;
    FAlign: TElementAlign;
    function GetHeight: Single;
  public
    procedure PaintTo(const ACanvas: TCanvas; ATop: Single); virtual;
    procedure UpdateSize(const ACanvas: TCanvas; AWidth: Single); virtual;
    property Height: Single read GetHeight;
    property Element: TChatElement read FElement write FElement;
    property Background: TAlphaColor read FBackground write FBackground;
    property Align: TElementAlign read FAlign write FAlign;
  end;

  TTextElementPainter = class(TElementPainter)
  protected
    function GetText: string;
  public
    procedure PaintTo(const ACanvas: TCanvas; ATop: Single); override;
    procedure UpdateSize(const ACanvas: TCanvas; AWidth: Single); override;
  end;

  TImageElementPainter = class(TElementPainter)
  protected
    function GetBitmap: TBitmap;
  public
    procedure PaintTo(const ACanvas: TCanvas; ATop: Single); override;
    procedure UpdateSize(const ACanvas: TCanvas; AWidth: Single); override;
  end;

implementation

uses
  FMX.Types;

const
  CBubblePadding = 50;
  CInnerPadding = 5;
  CCornerRadius = 10;
  CImagePreviewSize = 200;
  CMainTextOpacity = 1;
  CSecondaryTextOpacity = 0.5;

{ TElementPainter }

function TElementPainter.GetHeight: Single;
begin
  Result := FBoundaries.Height;
end;

procedure TElementPainter.PaintTo(const ACanvas: TCanvas; ATop: Single);
begin

end;

procedure TElementPainter.UpdateSize(const ACanvas: TCanvas; AWidth: Single);
begin

end;

{ TImageElementPainter }

function TImageElementPainter.GetBitmap: TBitmap;
begin
  Result := TImageChatElement(FElement).Image;
end;

procedure TImageElementPainter.PaintTo(const ACanvas: TCanvas; ATop: Single);
var
  LBubble, LImageRect: TRectF;
begin
  inherited;
  LBubble.Top := ATop;
  LBubble.Left := 0;
  LImageRect.Left := 0;
  if Align = eaRight then
  begin
    LBubble.Left := (FBoundaries.Width - CImagePreviewSize - CInnerPadding * 2);
    LImageRect.Left := LBubble.Left;
  end;
  LImageRect.Left := LImageRect.Left + CInnerPadding;
  LImageRect.Top := ATop + CInnerPadding;
  LImageRect.Width := CImagePreviewSize;
  LImageRect.Height := CImagePreviewSize;
  LBubble.Height := CImagePreviewSize + CInnerPadding * 2;
  LBubble.Width := CImagePreviewSize + CInnerPadding * 2;
  ACanvas.Fill.Color := FBackground;
  ACanvas.Stroke.Color := TAlphaColorRec.Gray;
  ACanvas.Stroke.Kind := TBrushKind.Solid;
  ACanvas.FillRect(LBubble, CCornerRadius, CCornerRadius, AllCorners, 1);
  ACanvas.DrawRect(LBubble, CCornerRadius, CCornerRadius, AllCorners, 1);
  ACanvas.DrawBitmap(GetBitmap, GetBitmap.BoundsF, LImageRect, 1);
end;

procedure TImageElementPainter.UpdateSize(const ACanvas: TCanvas;
  AWidth: Single);
begin
  inherited;
  FBoundaries.Width := AWidth;
  FBoundaries.Height := CImagePreviewSize + CInnerPadding * 2;
end;

{ TTextElementPainter }

function TTextElementPainter.GetText: string;
begin
  Result := (FElement as TTextChatElement).Text;
end;

procedure TTextElementPainter.PaintTo(const ACanvas: TCanvas; ATop: Single);
var
  LBubble, LTextRect: TRectF;
begin
  inherited;
  LBubble.Top := ATop;
  LBubble.Left := 0;
  LTextRect.Left := 0;
  if Align = eaRight then
  begin
    LBubble.Left := CBubblePadding;
    LTextRect.Left := CBubblePadding;
  end;
  LTextRect.Left := LTextRect.Left + CInnerPadding;
  LTextRect.Top := ATop + CInnerPadding;
  LTextRect.Width := FContentRect.Width;
  LTextRect.Height := FContentRect.Height;
  LBubble.Height := FBoundaries.Height;
  LBubble.Width := FBoundaries.Width;
  ACanvas.Fill.Color := FBackground;
  ACanvas.Stroke.Color := TAlphaColorRec.Grey;
  ACanvas.Stroke.Kind := TBrushKind.Solid;
  ACanvas.FillRect(LBubble, CCornerRadius, CCornerRadius, AllCorners, 1);
  LBubble.Inflate(-1, -1);
  ACanvas.DrawRect(LBubble, CCornerRadius, CCornerRadius, AllCorners, 1);
  ACanvas.Fill.Color := TAlphaColorRec.Black;
  ACanvas.FillText(LTextRect, GetText, True, CMainTextOpacity, [], TTextAlign.Leading);
end;

procedure TTextElementPainter.UpdateSize(const ACanvas: TCanvas;
  AWidth: Single);
var
  LAlign: TTextAlign;
begin
  inherited;
  FContentRect.Left := 0;
  FContentRect.Top := 0;
  FContentRect.Width := AWidth - CBubblePadding - CInnerPadding * 2;
  FContentRect.Height := 99999;
  if Align = eaLeft then
    LAlign := TTextAlign.Leading
  else
    LAlign := TTextAlign.Trailing;
  ACanvas.MeasureText(FContentRect, GetText, True, [], LAlign, TTextAlign.Leading);
  FBoundaries.Width := AWidth - CBubblePadding;
  FBoundaries.Height := FContentRect.Height + CInnerPadding * 2;
end;

end.
