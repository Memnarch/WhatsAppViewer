unit WAV.Chat;

interface

uses
  Spring.Collections,
  FMX.Graphics;

type
  TChatElement = class
  private
    FDate: string;
    FTime: string;
    FUser: string;
  public
    property User: string read FUser write FUser;
    property Date: string read FDate write FDate;
    property Time: string read FTime write FTime;
  end;

  TTextChatElement = class(TChatElement)
  private
    FText: string;
  public
    property Text: string read FText write FText;
  end;

  TImageChatElement = class(TChatElement)
  private
    FImage: TBitmap;
  public
    constructor Create;
    destructor Destroy; override;
    property Image: TBitmap read FImage;
  end;

  TWhatsAppChat = class
  private
    FItems: IList<TChatElement>;
    FBaseDirectory: string;
    FUsers: IList<string>;
    procedure ProcessLine(const ALine: string);
    function SplitLine(const ALine: string; out AContent, AUser, ADate, ATime: string): Boolean;
    function TryParseImage(const AContent: string; out AImageFile: string): Boolean;
    procedure CollectUsers;
  public
    constructor Create;
    procedure LoadFromDirectory(const APath: string);
    property Items: IList<TChatElement> read FItems;
    property Users: IList<string> read FUsers;
  end;

implementation

uses
  Types,
  Classes,
  IOUtils,
  SysUtils,
  StrUtils;

{ TImageChatElement }

constructor TImageChatElement.Create;
begin
  inherited;
  FImage := TBitmap.Create();
end;

destructor TImageChatElement.Destroy;
begin
  FImage.Free();
  inherited;
end;

{ TWhatsAppChat }

procedure TWhatsAppChat.CollectUsers;
var
  LUsers: ISet<string>;
  LElement: TChatElement;
begin
  LUsers := TCollections.CreateSet<string>();
  for LElement in FItems do
    LUsers.Add(LElement.User);
  FUsers.AddRange(LUsers);
end;

constructor TWhatsAppChat.Create;
begin
  inherited;
  FItems := TCollections.CreateObjectList<TChatElement>();
  FUsers := TCollections.CreateList<string>();
end;

procedure TWhatsAppChat.LoadFromDirectory(const APath: string);
var
  LFiles: TStringDynArray;
  LChat: TStringList;
  LLine: string;
begin
  FItems.Clear();
  FUsers.Clear();
  FBaseDirectory := APath;
  if TDirectory.Exists(APath) then
  begin
    LFiles := TDirectory.GetFiles(APath, 'WhatsApp Chat*.txt');
    if Length(LFiles) > 0 then
    begin
      LChat := TStringList.Create();
      try
        LChat.LoadFromFile(LFiles[0], TEncoding.UTF8);
        for LLine in LChat do
          ProcessLine(LLine);
        CollectUsers();
      finally
        LChat.Free();
      end;
    end;
  end;
end;

procedure TWhatsAppChat.ProcessLine(const ALine: string);
var
  LContent, LUser, LDate, LTime, LImage: string;
  LElement: TChatElement;
  LText: TTextChatElement;
begin
  if SplitLine(ALine, LContent, LUser, LDate, LTime) then
  begin
    if TryParseImage(LContent, LImage) then
    begin
      LElement := TImageChatElement.Create();
      TImageChatElement(LElement).Image.LoadFromFile(LImage);
    end
    else
    begin
      LElement := TTextChatElement.Create();
      TTextChatElement(LElement).Text := LContent;
    end;
    LElement.Date := LDate;
    LElement.Time := LTime;
    LElement.User := LUser;
    FItems.Add(LElement);
  end
  else
  begin
    LElement := FItems.Last;
    if LElement is TTextChatElement then
    begin
      LText := TTextChatElement(LElement);
      LText.Text := LText.Text + Trim(ALine);
    end
    else
    begin
      LText := TTextChatElement.Create();
      LText.User := LElement.User;
      LText.Date := LElement.Date;
      LText.Time := LElement.Time;
      LText.Text := Trim(ALine);
      FItems.Add(LText);
    end;
  end;
end;

function TWhatsAppChat.SplitLine(const ALine: string; out AContent, AUser,
  ADate, ATime: string): Boolean;
var
  LDateSeperator, LTimeSeperator, LUserSeperator: Integer;
begin
  LDateSeperator := Pos(',', ALine);
  LTimeSeperator := Pos('-', ALine);
  LUserSeperator := PosEx(':', ALine, LTimeSeperator);
  Result := (LDateSeperator > 0) and (LTimeSeperator > 0) and (LUserSeperator > 0);
  AContent := Trim(Copy(ALine, LUserSeperator + 1, Length(ALine)));
  AUser := Trim(Copy(ALine, LTimeSeperator + 1, LUserSeperator - LTimeSeperator - 1));
  ATime := Trim(Copy(ALine, LDateSeperator + 1, LTimeSeperator - LDateSeperator - 1));
  ADate := Trim(Copy(ALine, 1, LDateSeperator - 1));
end;

function TWhatsAppChat.TryParseImage(const AContent: string;
  out AImageFile: string): Boolean;
const
  CImageOpen = 'IMG-';
  CSubMessageOpen = '(';
var
  LSubPos: Integer;
  LImage: string;
begin
  Result := False;
  if StartsStr(CImageOpen, AContent) then
  begin
    LSubPos := Pos(CSubMessageOpen, AContent);
    if LSubPos > 1 then
    begin
      LImage := Trim(Copy(AContent, 1, LSubPos - 1));
      LImage := TPath.Combine(FBaseDirectory, LImage);
      if TFile.Exists(LImage) and MatchText(ExtractFileExt(LImage), ['.jpg', '.jpeg']) then
      begin
        AImageFile := LImage;
        Exit(True);
      end;
    end;
  end;
end;

end.
