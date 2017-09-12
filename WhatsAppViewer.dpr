program WhatsAppViewer;

uses
  System.StartUpCopy,
  FMX.Forms,
  Main in 'Main.pas' {ChatViewer},
  WAV.Chat in 'WAV.Chat.pas',
  WAV.Chat.Painter in 'WAV.Chat.Painter.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TChatViewer, ChatViewer);
  Application.Run;
end.
