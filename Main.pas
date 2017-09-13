unit Main;

interface

uses
  Spring.Collections, WAV.Chat, WAV.Chat.Painter, System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects, FMX.Layouts,
  FMX.TreeView, FMX.ListBox;

type
  TChatViewer = class(TForm)
    ChatView: TPaintBox;
    ChatScroll: TScrollBar;
    ResizeTimer: TTimer;
    tvNavigator: TTreeView;
    Panel1: TPanel;
    cbUsers: TComboBox;
    lbChatWith: TLabel;
    Rectangle1: TRectangle;
    StyleBook1: TStyleBook;
    Shadow: TRectangle;
    procedure ChatViewPaint(Sender: TObject; ACanvas: TCanvas);
    procedure ChatScrollChange(Sender: TObject);
    procedure ChatViewResized(Sender: TObject);
    procedure ChatViewMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; var Handled: Boolean);
    procedure ResizeTimerTimer(Sender: TObject);
    procedure tvNavigatorClick(Sender: TObject);
    procedure cbUsersChange(Sender: TObject);
  private
    { Private declarations }
    FChat: TWhatsAppChat;
    FPainter: IList<TElementPainter>;
    FMainUserColor: TAlphaColor;
    FOthersColor: TAlphaColor;
    FDateColor: TAlphaColor;
    procedure BuildPainter;
    procedure UpdatePainter;
    procedure BuildTree;
    procedure SetMainUser(const AUser: string);
    function FindElementPosition(AElement: TChatElement): Single;
  public
    constructor Create(AOwner: TComponent); override;
    { Public declarations }
    destructor Destroy; override;
  end;

var
  ChatViewer: TChatViewer;

implementation

uses
  StrUtils;

{$R *.fmx}

const
  CVertSpace = 10;

procedure TChatViewer.BuildPainter;
var
  LElement: TChatElement;
  LPainter: TElementPainter;
  LLastDate: string;
begin
  LLastDate := '';
  for LElement in FChat.Items do
  begin
    LPainter := nil;
    if LLastDate <> LElement.Date then
    begin
      LLastDate := LElement.Date;
      LPainter := TDateElementPainter.Create();
      LPainter.Element := LElement;
      LPainter.Align := eaCenter;
      LPainter.ShowTime := False;
      LPainter.Background := FDateColor;
      FPainter.Add(LPainter);
      LPainter := nil;
    end;
    if LElement is TTextChatElement then
      LPainter := TTextElementPainter.Create()
    else if LElement is TImageChatElement then
      LPainter := TImageElementPainter.Create();
    LPainter.Element := LElement;
    FPainter.Add(LPainter);
  end;
end;

procedure TChatViewer.BuildTree;
var
  LDay, LLastDay, LMonth, LLastMonth, LYear, LLastYear: string;
  LSplitted: TStringDynArray;
  LElement: TChatElement;
  LDayItem, LMonthItem, LYearItem: TTreeViewItem;
begin
  tvNavigator.Clear();
  LDay := '';
  LMonth := '';
  LYear := '';
  LLastDay := '';
  LLastMonth := '';
  LLastYear := '';
  LDayItem := nil;
  LMonthItem := nil;
  LYearItem := nil;
  for LElement in FChat.Items do
  begin
    LSplitted := SplitString(LElement.Date, ' ');
    LDay := LSplitted[0];
    LMonth := LSplitted[1];
    LYear := LSplitted[2];
    if LYear <> LLastYear then
    begin
      LLastYear := LYear;
      LLastMonth := '';
      LYearItem := TTreeViewItem.Create(tvNavigator);
      LYearItem.Text := LYear;
      LYearItem.TagObject := LElement;
      tvNavigator.AddObject(LYearItem);
    end;

    if LMonth <> LLastMonth then
    begin
      LLastMonth := LMonth;
      LLastDay := '';
      LMonthItem := TTreeViewItem.Create(tvNavigator);
      LMonthItem.Text := LMonth;
      LMonthItem.TagObject := LElement;
      LYearItem.AddObject(LMonthItem);
    end;

    if LDay <> LLastDay then
    begin
      LLastDay := LDay;
      LDayItem := TTreeViewItem.Create(tvNavigator);
      LDayItem.Text := LDay;
      LDayItem.TagObject := LElement;
      LMonthItem.AddObject(LDayItem);
    end;
  end;
end;

procedure TChatViewer.cbUsersChange(Sender: TObject);
begin
  if cbUsers.ItemIndex > -1 then
    SetMainUser(cbUsers.Items[cbUsers.ItemIndex]);
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
  FMainUserColor := $FFe2ffc7;
  FOthersColor := TAlphaColorRec.White;
  FDateColor := $FFd4eaf5;
  BuildPainter();
  BuildTree();
  cbUsers.Items.AddStrings(FChat.Users.ToArray);
  cbUsers.ItemIndex := 0;
  ChatView.Canvas.Fill.Color := TAlphaColorRec.Black;
end;

destructor TChatViewer.Destroy;
begin
  FChat.Free();
  inherited;
end;

function TChatViewer.FindElementPosition(AElement: TChatElement): Single;
var
  LPainter: TElementPainter;
begin
  Result := 0;
  for LPainter in FPainter do
  begin
    if LPainter.Element = AElement then
      Exit;
    Result := Result + LPainter.Height + CVertSpace;
  end;
end;

procedure TChatViewer.ResizeTimerTimer(Sender: TObject);
begin
  ResizeTimer.Enabled := False;
  UpdatePainter();
  Invalidate();
end;

procedure TChatViewer.SetMainUser(const AUser: string);
var
  LPainter: TElementPainter;
  LOtherUser, LUsers: string;
begin
  for LPainter in FPainter do
  begin
    if (not (LPainter is TDateElementPainter)) then
      if (LPainter.Element.User = AUser) then
      begin
        LPainter.Align := eaRight;
        LPainter.Background := FMainUserColor;
      end
      else
      begin
        LPainter.Align := eaLeft;
        LPainter.Background := FOthersColor;
      end;
  end;
  UpdatePainter();
  LUsers := '';
  for LOtherUser in FChat.Users do
    if LOtherUser <> AUser then
    begin
      if LUsers <> '' then
        LUsers := ', ';
      LUsers := LUsers + LOtherUser;
    end;
  lbChatWith.Text := 'Chatting with: ' + LUsers;
  Invalidate;
end;

procedure TChatViewer.tvNavigatorClick(Sender: TObject);
begin
  if Assigned(tvNavigator.Selected) then
  begin
    ChatScroll.Value := FindElementPosition(tvNavigator.Selected.TagObject as TChatElement);
  end;
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
