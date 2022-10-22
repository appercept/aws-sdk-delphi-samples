unit Form.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Generics.Collections, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.Edit, FMX.ComboEdit, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView,
  AWS.SecretsManager, FMX.Layouts, FMX.ListBox, FMX.StdCtrls, System.Actions,
  FMX.ActnList;

type
  TMainForm = class(TForm)
    SelectRegion: TComboEdit;
    SecretsListBox: TListBox;
    ToolBar1: TToolBar;
    SpeedButton1: TSpeedButton;
    ActionList1: TActionList;
    ActStoreNewSecret: TAction;
    ActReloadSecrets: TAction;
    SpeedButton2: TSpeedButton;
    procedure SelectRegionChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ActStoreNewSecretExecute(Sender: TObject);
    procedure ActReloadSecretsExecute(Sender: TObject);
    procedure SecretsListBoxDblClick(Sender: TObject);
  private
    { Private declarations }
    FClient: ISecretsManagerClient;
    FCurrentRegion: string;
    FSecrets: TList<ISecretsManagerSecretListEntry>;
    procedure SetCurrentRegion(const ARegion: string);
    procedure ReloadSecrets;
    procedure RefreshSecretsUI;
    property Client: ISecretsManagerClient read FClient;
    property CurrentRegion: string read FCurrentRegion write SetCurrentRegion;
    property Secrets: TList<ISecretsManagerSecretListEntry> read FSecrets;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses Form.NewSecret, Form.Secret;

procedure TMainForm.ActReloadSecretsExecute(Sender: TObject);
begin
  ReloadSecrets;
end;

procedure TMainForm.ActStoreNewSecretExecute(Sender: TObject);
var
  LNewSecretForm: TNewSecretForm;
  LResponse: ISecretsManagerCreateSecretResponse;
begin
  LNewSecretForm := TNewSecretForm.Create(Self);
  try
    LNewSecretForm.CurrentRegion := CurrentRegion;
    if LNewSecretForm.ShowModal = mrOk then
    begin
      LResponse := Client.CreateSecret(LNewSecretForm.CreateSecretRequest);
      if LResponse.IsSuccessful then
        SecretsListBox.Items.Add(LResponse.Name);
    end;
  finally
    LNewSecretForm.Free;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FSecrets := TList<ISecretsManagerSecretListEntry>.Create;
end;

procedure TMainForm.RefreshSecretsUI;
var
  LSecret: ISecretsManagerSecretListEntry;
begin
  SecretsListBox.Items.Clear;
  for LSecret in Secrets do
    SecretsListBox.Items.Add(LSecret.Name);
end;

procedure TMainForm.ReloadSecrets;
var
  LRequest: ISecretsManagerListSecretsRequest;
  LResponse: ISecretsManagerListSecretsResponse;
begin
  if not Assigned(FClient) then
  begin
    var LOptions := TSecretsManagerOptions.Create as ISecretsManagerOptions;
    LOptions.Region := CurrentRegion;
    FClient := TSecretsManagerClient.Create(LOptions);
  end;

  Secrets.Clear;
  LRequest := TSecretsManagerListSecretsRequest.Create;
  LResponse := Client.ListSecrets(LRequest);
  if LResponse.IsSuccessful then
    Secrets.AddRange(LResponse.SecretList);
  RefreshSecretsUI;
end;

procedure TMainForm.SecretsListBoxDblClick(Sender: TObject);
var
  LSecretForm: TSecretForm;
begin
  if Assigned(SecretsListBox.Selected) then
  begin
    LSecretForm := TSecretForm.Create(Self);
    try
      LSecretForm.CurrentRegion := CurrentRegion;
      LSecretForm.SecretId := SecretsListBox.Selected.Text;
      LSecretForm.ShowModal;
    finally
      LSecretForm.Free;
    end;
  end;
end;

procedure TMainForm.SelectRegionChange(Sender: TObject);
begin
  FClient := nil;
  CurrentRegion := SelectRegion.Text;
end;

procedure TMainForm.SetCurrentRegion(const ARegion: string);
begin
  FCurrentRegion := ARegion;
  if not CurrentRegion.IsEmpty then
  begin
    ActReloadSecrets.Enabled := True;
    ActStoreNewSecret.Enabled := True;
    ReloadSecrets;
  end;
end;

end.
