unit Main;

interface

uses
  Spring.Collections, WAV.Chat, WAV.Chat.Painter, System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects;

type
  TChatViewer = class(TForm)
    ChatView: TPaintBox;
    ChatScroll: TScrollBar;
    ResizeTimer: TTimer;
    procedure ChatViewPaint(Sender: TObject; ACanvas: TCanvas);
    procedure ChatScrollChange(Sender: TObject);
    procedure ChatViewResized(Sender: TObject);
    procedure ChatViewMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; var Handled: Boolean);
    procedure ResizeTimerTimer(Sender: TObject);
  private
    { Private declarations }
    FChat: TWhatsAppChat;
    FPainter: IList<TElementPainter>;
    FMainUser: string;
    FMainUserColor: TAlphaColor;
    FOthersColor: TAlphaColor;
    procedure BuildPainter;
    procedure UpdatePainter;
  public
    constructor Create(AOwner: TComponent); override;
    { Public declarations }
    destructor Destroy; override;
  end;

var
  ChatViewer: TChatViewer;

implementation

{$R *.fmx}

const
  CVertSpace = 10;

procedure TChatViewer.BuildPainter;
var
  LElement: TChatElement;
  LPainter: TElementPainter;
begin
  for LElement in FChat.Items do
  begin
    LPainter := nil;
    if LElement is TTextChatElement then
      LPainter := TTextElementPainter.Create()
    else if LElement is TImageChatElement then
      LPainter := TImageElementPainter.Create();
    LPainter.Element := LElement;
    if LElement.User = FMainUser then
    begin
      LPainter.Align := eaRight;
      LPainter.Background := FMainUserColor;
    end
    else
    begin
      LPainter.Background := FOthersColor;
    end;
    FPainter.Add(LPainter);
  end;
  UpdatePainter();
end;

procedure TChatViewer.ChatScrollChange(Sender: TObject);
begin
  ChatView.Repaint();
end;

procedure TChatViewer.ChatViewMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; var Handled: Boolean);
begin
  ChatScroll.Value := ChatScroll.Value - WheelDelta;
  Handled := True;
end;

procedure TChatViewer.ChatViewPaint(Sender: TObject; ACanvas: TCanvas);
var
  LTop: Single;
  LPainter: TElementPainter;
begin
  LTop := CVertSpace;
  for LPainter in FPainter do
  begin
    if (LPainter.Height > 0)
      and not (((LTop + LPainter.Height) < ChatScroll.Value)
        or ((LTop - ChatScroll.Value) > ChatView.Height)) then
    begin
      LPainter.PaintTo(ACanvas, LTop - ChatScroll.Value);
    end;
    LTop := LTop + LPainter.Height + CVertSpace;
  end;
end;

procedure TChatViewer.ChatViewResized(Sender: TObject);
begin
  if Assigned(FPainter) then
    ResizeTimer.Enabled := True;
end;

constructor TChatViewer.Create(AOwner: TComponent);
begin
  inherited;
  FPainter := TCollections.CreateObjectList<TElementPainter>();
  FChat := TWhatsAppChat.Create();
  FChat.LoadFromDirectory('.\Chat');
  FMainUser := FChat.Users.First;
  FMainUserColor := $FFe2ffc7;
  FOthersColor := TAlphaColorRec.White;
  BuildPainter();
  ChatView.Canvas.Fill.Color := TAlphaColorRec.Black;
end;

destructor TChatViewer.Destroy;
begin
  FChat.Free();
  inherited;
end;

procedure TChatViewer.ResizeTimerTimer(Sender: TObject);
begin
  ResizeTimer.Enabled := False;
  UpdatePainter();
  ChatView.Repaint();
end;

procedure TChatViewer.UpdatePainter;
var
  LPainter: TElementPainter;
  LHeight: Single;
begin
  LHeight := 0;
  for LPainter in FPainter do
  begin
    LPainter.UpdateSize(ChatView.Canvas, ChatView.Width);
    LHeight := LHeight + LPainter.Height;
  end;
  ChatScroll.Max := LHeight + CVertSpace * FPainter.Count - ChatView.Height;
end;

end.
