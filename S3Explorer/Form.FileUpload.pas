unit Form.FileUpload;

interface

uses
  AWS.S3,
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs, FMX.StdCtrls, FMX.Controls.Presentation, FMX.Memo.Types,
  FMX.ScrollBox, FMX.Memo, FMX.Layouts,
  Frame.PartProgress;

type
  TFileUploadForm = class(TForm)
    OverallProgressBar: TProgressBar;
    Label1: TLabel;
    Label2: TLabel;
    LblSource: TLabel;
    LblDestination: TLabel;
    Label3: TLabel;
    LblStartedAt: TLabel;
    Label4: TLabel;
    LblFinishedAt: TLabel;
    Label5: TLabel;
    LblTransferred: TLabel;
    PartsProgressContainer: TVertScrollBox;
    AbortButton: TButton;
    procedure AbortButtonClick(Sender: TObject);
  private
    { Private declarations }
    FObject: IS3Object;
    FAborting: Boolean;
    function FindPartProgress(const APartNumber: Integer): TPartProgressFrame;
    procedure UpdatePartProgress(const APartNumber: Integer; APartLength, APartWriteCount: Int64);
  public
    { Public declarations }
    procedure UploadFile(const AFilePath, ABucket, AKey: string; AClient: IS3Client);
  end;

var
  FileUploadForm: TFileUploadForm;

implementation

{$R *.fmx}

uses
  System.DateUtils,
  System.Threading;

{ TFileUploadForm }

procedure TFileUploadForm.AbortButtonClick(Sender: TObject);
begin
  AbortButton.Enabled := False;
  AbortButton.Text := 'Aborting...';
  FAborting := True;
end;

function TFileUploadForm.FindPartProgress(
  const APartNumber: Integer): TPartProgressFrame;
var
  I: Integer;
  LPartProgressFrame: TPartProgressFrame;
begin
  Result := nil;
  for I := 0 to PartsProgressContainer.Content.ChildrenCount - 1 do
  begin
    if not (PartsProgressContainer.Content.Children[I] is TPartProgressFrame) then
      Continue;

    LPartProgressFrame := PartsProgressContainer.Content.Children[I] as TPartProgressFrame;
    if LPartProgressFrame.PartNumber = APartNumber then
      Exit(LPartProgressFrame);
  end;
end;

procedure TFileUploadForm.UpdatePartProgress(const APartNumber: Integer;
  APartLength, APartWriteCount: Int64);
var
  LPartProgressFrame: TPartProgressFrame;
begin
  PartsProgressContainer.BeginUpdate;
  LPartProgressFrame := FindPartProgress(APartNumber);
  if not Assigned(LPartProgressFrame) then
  begin
    LPartProgressFrame := TPartProgressFrame.Create(PartsProgressContainer.Content);
    LPartProgressFrame.Parent := PartsProgressContainer.Content;
    LPartProgressFrame.Position.Y := -1;
    LPartProgressFrame.PartNumber := APartNumber;
  end;

  LPartProgressFrame.PartSize := APartLength;
  LPartProgressFrame.Progress := APartWriteCount;
  PartsProgressContainer.EndUpdate;
end;

procedure TFileUploadForm.UploadFile(const AFilePath, ABucket, AKey: string;
  AClient: IS3Client);
begin
  Caption := Format('Uploading file: %s', [AFilePath]);
  LblSource.Text := AFilePath;
  LblDestination.Text := Format('s3://%s/%s', [ABucket, AKey]);
  Show;
  // TS3Object is a convenience model exposing object-level functions of S3.
  FObject := TS3Object.Create(ABucket, AKey, AClient);
  LblStartedAt.Text := DateToISO8601(Now);
  // This might be a long-running task, so we use TTask to run it in another
  // thread.
  TTask.Run(
    procedure
    begin
      // The `TS3Object.UploadFile` procedure encapsulates a call to
      // `TS3FileUploader` which can be used directly. The `TS3FileUploader`
      // will make a decision on the best way to upload a file. If it is small
      // (less than 100 MiB) then it will upload the file in a single part.
      // Files greater than 100MiB will be split and uploaded in parts. The
      // parts themselves are uploaded asynchronously which is why we may
      // receive status callbacks for different parts overlapping each other.
      FObject.UploadFile(
        AFilePath,
        True,
        procedure(const AUploadId: string; APartNumber: Integer; APartLength, APartWriteCount, AOverallLength, AOverallWriteCount: Int64; var AAbort: Boolean)
        begin
          // We are in another thread here, so we need to queue (or synchronize)
          // these UI updates to the main (UI) thread.
          TThread.Queue(nil,
            procedure
            begin
              LblTransferred.Text := Format('%d of %d', [AOverallWriteCount, AOverallLength]);
              OverallProgressBar.Max := AOverallLength;
              OverallProgressBar.Value := AOverallWriteCount;
              UpdatePartProgress(APartNumber, APartLength, APartWriteCount);
            end
          );
          // If someone has clicked abort, we can abort the upload here.
          AAbort := FAborting;
        end
      );
      LblFinishedAt.Text := DateToISO8601(Now);
    end
  );
end;

end.
