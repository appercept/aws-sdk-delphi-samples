program Poller;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  AWS.SQS,
  System.SysUtils;

var
  QueueURL: string;
  QueuePoller: ISQSQueuePoller;

const
  LOG_DATE_FORMAT = 'yyyymmdd''T''hhnnss';

procedure Log(const AMessage: string);
begin
  Writeln(Format('[%s] %s', [FormatDateTime(LOG_DATE_FORMAT, Now), AMessage]));
end;

begin
  try
    QueueURL := ParamStr(1);
    if QueueURL.IsEmpty then
    begin
      Writeln('Please specify Queue URL as argument.');
      Exit;
    end;

    QueuePoller := TSQSQueuePoller.Create(QueueURL);

    QueuePoller.OnBeforeRequest := procedure(const APoller: ISQSQueuePoller;
                                             const AStats: TSQSQueuePollerStatistics)
      begin
        if AStats.RequestCount = 0 then
          Log(Format('Polling started at %s', [FormatDateTime('c', AStats.PollingStartedAt)]))
        else
          Log(Format('Polling iteration %d', [AStats.RequestCount]));
        Log(Format('Messages received to date %d', [AStats.ReceivedMessageCount]));
      end;

    // Uncomment the following line to enable receiving in batches.
    // QueuePoller.MaxNumberOfMessages := 3;

    QueuePoller.Poll(
      procedure(const AMessages: TSQSMessages)
      var
        LMessage: ISQSMessage;
      begin
        for LMessage in AMessages do
          Log(Format('Received message: %s', [LMessage.Body]));
      end
    );
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
