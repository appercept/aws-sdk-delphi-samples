program Sender;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  AWS.SQS,
  System.SysUtils;

var
  SQS: TSQSClient;
  SenderName: string;
  QueueURL: string;
  MessageCount: Integer;

begin
  try
    SenderName := ParamStr(1);
    QueueURL := ParamStr(2);

    if SenderName.IsEmpty or QueueURL.IsEmpty then
    begin
      Writeln('Please specify sender name and Queue URL as arguments.');
      Exit;
    end;

    SQS := TSQSClient.Create;
    try
      MessageCount := 0;
      while True do
      begin
        Inc(MessageCount);
        SQS.SendMessage(
          QueueURL,
          Format('Message %d from %s', [MessageCount, SenderName])
        );
        Sleep(1000);
      end;
    finally
      SQS.Free;
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
