unit Form.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.ComboEdit, FMX.ScrollBox, FMX.Memo, FMX.Edit, FMX.StdCtrls,
  FMX.Controls.Presentation, AWS.SESV2, System.Actions, FMX.ActnList;

type
  TMainForm = class(TForm)
    ToLabel: TLabel;
    EditTo: TEdit;
    SubjectLabel: TLabel;
    EditSubject: TEdit;
    EditMessage: TMemo;
    EditFrom: TComboEdit;
    FromIdentityLabel: TLabel;
    ActionList1: TActionList;
    ActSendEmail: TAction;
    SpeedButton1: TSpeedButton;
    Panel1: TPanel;
    RegionLabel: TLabel;
    SelectRegion: TComboEdit;
    procedure FormShow(Sender: TObject);
    procedure ActSendEmailExecute(Sender: TObject);
    procedure SelectRegionChange(Sender: TObject);
    procedure ActSendEmailUpdate(Sender: TObject);
  private
    FOptions: ISESV2Options;
    FClient: ISESV2Client;
    procedure ChangeRegion(const ARegionCode: string);
    function CreateClient(const ARegionCode: string): ISESV2Client;
    procedure LoadEmailIdentities;
    property Client: ISESV2Client read FClient;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses
  FMX.DialogService;

{$R *.fmx}

procedure TMainForm.ActSendEmailExecute(Sender: TObject);
var
  LDestination: ISESV2Destination;
  LMessage: ISESV2Message;
  LRequest: ISESV2SendEmailRequest;
  LResponse: ISESV2SendEmailResponse;
begin
  LDestination := TSESV2Destination.Create;
  LDestination.AddToAddress(EditTo.Text);

  LMessage := TSESV2Message.Create(EditSubject.Text);
  LMessage.Body.Text := TSESV2Content.Create(EditMessage.Text);

  LRequest := TSESV2SendEmailRequest.Create;
  LRequest.Destination := LDestination;
  LRequest.FromEmailAddress := EditFrom.Text;
  LRequest.Content.Simple := LMessage;
  try
    LResponse := Client.SendEmail(LRequest);
    if LResponse.IsSuccessful then
      TDialogService.ShowMessage('Email sent.');
  except
    on E: ESESV2Exception do
    begin
      var LErrorMessage := E.Message;
      if LErrorMessage.IsEmpty then
        LErrorMessage := 'There was an error sending email.';
      TDialogService.MessageDialog(LErrorMessage, TMsgDlgType.mtError, [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0, nil);
    end;
  end;
end;

procedure TMainForm.ActSendEmailUpdate(Sender: TObject);
begin
  ActSendEmail.Enabled := not EditFrom.Text.IsEmpty and not EditTo.Text.IsEmpty;
end;

procedure TMainForm.ChangeRegion(const ARegionCode: string);
begin
  FClient := CreateClient(ARegionCode);
  LoadEmailIdentities;
end;

function TMainForm.CreateClient(const ARegionCode: string): ISESV2Client;
begin
  FOptions := TSESV2Options.Create;
  FOptions.Region := ARegionCode;
  Result := TSESV2Client.Create(FOptions);
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  ChangeRegion(SelectRegion.Text);
end;

procedure TMainForm.LoadEmailIdentities;
var
  LResponse: ISESV2ListEmailIdentitiesResponse;
begin
  LResponse := Client.ListEmailIdentities;
  if LResponse.IsSuccessful then
  begin
    EditFrom.BeginUpdate;
    try
      EditFrom.Items.Clear;
      for var LIdentity in LResponse.EmailIdentities do
      begin
        if LIdentity.IdentityType.Equals('EMAIL_ADDRESS') then
          EditFrom.Items.Add(LIdentity.IdentityName);
      end;
    finally
      EditFrom.EndUpdate;
    end;
  end;
end;

procedure TMainForm.SelectRegionChange(Sender: TObject);
begin
  ChangeRegion(SelectRegion.Text);
end;

end.
