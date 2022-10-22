unit Form.Secret;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Edit,
  FMX.Controls.Presentation, FMX.StdCtrls,
  AWS.SecretsManager;

type
  TSecretForm = class(TForm)
    LblDetails: TLabel;
    LblEncryptionKey: TLabel;
    EditEncryptionKey: TEdit;
    LblSecretName: TLabel;
    EditSecretName: TEdit;
    LblSecretARN: TLabel;
    EditSecretARN: TEdit;
    LblSecretDescription: TLabel;
    EditSecretDescription: TEdit;
    LblSecretValue: TLabel;
    EditSecretValue: TEdit;
    BtnRetriveSecretValue: TSpeedButton;
    procedure FormShow(Sender: TObject);
    procedure BtnRetriveSecretValueClick(Sender: TObject);
  private
    FClient: ISecretsManagerClient;
    FCurrentRegion: string;
    FSecretId: string;
    property Client: ISecretsManagerClient read FClient;
    function GetCurrentRegion: string;
    procedure SetCurrentRegion(const ACurrentRegion: string);
    function GetSecretId: string;
    procedure SetSecretId(const ASecretId: string);
    procedure LoadSecret;
  public
    property CurrentRegion: string read GetCurrentRegion write SetCurrentRegion;
    property SecretId: string read GetSecretId write SetSecretId;
  end;

var
  SecretForm: TSecretForm;

implementation

{$R *.fmx}

{ TSecretForm }

procedure TSecretForm.BtnRetriveSecretValueClick(Sender: TObject);
var
  LResponse: ISecretsManagerGetSecretValueResponse;
begin
  LResponse := Client.GetSecretValue(SecretId);
  if LResponse.IsSuccessful then
    EditSecretValue.Text := LResponse.SecretString;
end;

procedure TSecretForm.FormShow(Sender: TObject);
begin
  LoadSecret;
end;

function TSecretForm.GetCurrentRegion: string;
begin
  Result := FCurrentRegion;
end;

function TSecretForm.GetSecretId: string;
begin
  Result := FSecretId;
end;

procedure TSecretForm.LoadSecret;
var
  LResponse: ISecretsManagerDescribeSecretResponse;
begin
  LResponse := Client.DescribeSecret(SecretId);
  if LResponse.IsSuccessful then
  begin
    EditEncryptionKey.Text := LResponse.KmsKeyId;
    EditSecretName.Text := LResponse.Name;
    EditSecretARN.Text := LResponse.ARN;
    EditSecretDescription.Text := LResponse.Description;
  end;
end;

procedure TSecretForm.SetCurrentRegion(const ACurrentRegion: string);
var
  LOptions: ISecretsManagerOptions;
begin
  FCurrentRegion := ACurrentRegion;
  if not CurrentRegion.IsEmpty then
  begin
    LOptions := TSecretsManagerOptions.Create;
    LOptions.Region := CurrentRegion;
    FClient := TSecretsManagerClient.Create(LOptions);
  end;
end;

procedure TSecretForm.SetSecretId(const ASecretId: string);
begin
  FSecretId := ASecretId;
  Caption := Format('Secret: %s', [SecretId]);
end;

end.
