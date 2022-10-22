unit Form.NewSecret;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.Edit, FMX.StdCtrls, FMX.ListBox, FMX.ScrollBox, FMX.Memo,
  FMX.Controls.Presentation, System.Generics.Collections,
  AWS.KMS, System.Actions, FMX.ActnList,
  AWS.SecretsManager;

type
  TNewSecretForm = class(TForm)
    LblPlaintext: TLabel;
    MemoPlaintext: TMemo;
    LblEncryptionKey: TLabel;
    EditEncryptionKey: TComboBox;
    BtnReloadEncryptionKeys: TButton;
    BtnStore: TButton;
    LblName: TLabel;
    EditName: TEdit;
    LblDescription: TLabel;
    MemoDescription: TMemo;
    ActionList1: TActionList;
    ActReloadEncryptionKeys: TAction;
    procedure ActReloadEncryptionKeysExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure EditNameChange(Sender: TObject);
    procedure MemoPlaintextChange(Sender: TObject);
    procedure EditEncryptionKeyChange(Sender: TObject);
  private
    FCurrentRegion: string;
    FKMSClient: IKMSClient;
    FKeyAliases: TList<IKMSAliasListEntry>;
    FEncryptionKeys: TList<IKMSKeyMetadata>;
    FKeyMap: TDictionary<string, IKMSKeyMetadata>;
    function GetCurrentRegion: string;
    procedure SetCurrentRegion(const ACurrentRegion: string);
    function GetKMSClient: IKMSClient;
    procedure SetKMSClient(const AKMSClient: IKMSClient);
    function GetCreateSecretRequest: ISecretsManagerCreateSecretRequest;
    property KMSClient: IKMSClient read GetKMSClient write SetKMSClient;
    property KeyAliases: TList<IKMSAliasListEntry> read FKeyAliases;
    property EncryptionKeys: TList<IKMSKeyMetadata> read FEncryptionKeys;
    property KeyMap: TDictionary<string, IKMSKeyMetadata> read FKeyMap;
    procedure LoadEncryptionKeys;
    procedure LoadKeyAliases;
    procedure BuildKeyMap;
    procedure ValidateInputs;
  public
    property CurrentRegion: string read GetCurrentRegion write SetCurrentRegion;
    property CreateSecretRequest: ISecretsManagerCreateSecretRequest read GetCreateSecretRequest;
  end;

var
  NewSecretForm: TNewSecretForm;

implementation

{$R *.fmx}

{ TNewSecretForm }

procedure TNewSecretForm.ActReloadEncryptionKeysExecute(Sender: TObject);
begin
  LoadEncryptionKeys;
  LoadKeyAliases;
  BuildKeyMap;
  EditEncryptionKey.Items.Clear;
  for var LAliasKeyEntry in KeyMap do
    EditEncryptionKey.Items.Add(LAliasKeyEntry.Key);
end;

procedure TNewSecretForm.BuildKeyMap;

  function FindKeyForAlias(const AAlias: IKMSAliasListEntry): IKMSKeyMetadata;
  var
    I: Integer;
    LKey: IKMSKeyMetadata;
  begin
    Result := nil;
    for I := 0 to EncryptionKeys.Count - 1 do
    begin
      LKey := EncryptionKeys[I];
      if LKey.KeyId = AAlias.TargetKeyId then
        Exit(LKey);
    end;
  end;

var
  LAlias: IKMSAliasListEntry;
  LKey: IKMSKeyMetadata;
begin
  KeyMap.Clear;
  for LAlias in KeyAliases do
  begin
    LKey := FindKeyForAlias(LAlias);
    if Assigned(LKey) then
      KeyMap.Add(LAlias.AliasName, LKey);
  end;
end;

procedure TNewSecretForm.EditEncryptionKeyChange(Sender: TObject);
begin
  ValidateInputs;
end;

procedure TNewSecretForm.EditNameChange(Sender: TObject);
begin
  ValidateInputs;
end;

procedure TNewSecretForm.FormCreate(Sender: TObject);
begin
  FKeyAliases := TList<IKMSAliasListEntry>.Create;
  FEncryptionKeys := TList<IKMSKeyMetadata>.Create;
  FKeyMap := TDictionary<string, IKMSKeyMetadata>.Create;
end;

procedure TNewSecretForm.FormDestroy(Sender: TObject);
begin
  FKeyMap.Free;
  FEncryptionKeys.Free;
  FKeyAliases.Free;
end;

function TNewSecretForm.GetCreateSecretRequest: ISecretsManagerCreateSecretRequest;
var
  LKmsKey: IKMSKeyMetadata;
begin
  Result := TSecretsManagerCreateSecretRequest.Create(EditName.Text, MemoPlaintext.Text);
  Result.Description := MemoDescription.Text;
  if EditEncryptionKey.ItemIndex >= 0 then
  begin
    LKmsKey := KeyMap[EditEncryptionKey.Items[EditEncryptionKey.ItemIndex]];
    Result.KmsKeyId := LKmsKey.KeyId;
  end;
end;

function TNewSecretForm.GetCurrentRegion: string;
begin
  Result := FCurrentRegion;
end;

function TNewSecretForm.GetKMSClient: IKMSClient;
begin
  Result := FKMSClient;
end;

procedure TNewSecretForm.LoadKeyAliases;
var
  LRequest: IKMSListAliasesRequest;
  LResponse: IKMSListAliasesResponse;
begin
  KeyAliases.Clear;
  LRequest := TKMSListAliasesRequest.Create;
  LResponse := KMSClient.ListAliases(LRequest);
  if LResponse.IsSuccessful then
  begin
    repeat
      for var LAlias in LResponse.Aliases do
        if LAlias.AliasName.Equals('alias/aws/secretsmanager')
          or not LAlias.AliasName.StartsWith('alias/aws') then
            KeyAliases.Add(LAlias);
      if LResponse.Truncated then
      begin
        LRequest.Marker := LResponse.NextMarker;
        LResponse := KMSClient.ListAliases(LRequest);
      end;
    until not LResponse.Truncated.Value;
  end;
end;

procedure TNewSecretForm.MemoPlaintextChange(Sender: TObject);
begin
  ValidateInputs;
end;

procedure TNewSecretForm.LoadEncryptionKeys;
var
  LListRequest: IKMSListKeysRequest;
  LListResponse: IKMSListKeysResponse;
  LDescribeResponse: IKMSDescribeKeyResponse;
  LKeyMetadata: IKMSKeyMetadata;
begin
  LListRequest := TKMSListKeysRequest.Create;
  repeat
    if Assigned(LListResponse) and LListResponse.Truncated.Value then
      LListRequest.Marker := LListResponse.NextMarker;
    LListResponse := KMSClient.ListKeys(LListRequest);
    if LListResponse.IsSuccessful then
      for var LKey in LListResponse.Keys do
        begin
          LDescribeResponse := KMSClient.DescribeKey(LKey.KeyArn);
          if LDescribeResponse.IsSuccessful then
          begin
            LKeyMetadata := LDescribeResponse.KeyMetadata;
            if not LKeyMetadata.KeySpec.Equals('SYMMETRIC_DEFAULT') then
              Continue;

            if not LKeyMetadata.KeyUsage.Equals('ENCRYPT_DECRYPT') then
              Continue;

            EncryptionKeys.Add(LKeyMetadata);
          end;
        end;
  until not LListResponse.IsSuccessful or not LListResponse.Truncated.Value;
end;

procedure TNewSecretForm.SetCurrentRegion(const ACurrentRegion: string);
var
  LOptions: IKMSOptions;
begin
  FCurrentRegion := ACurrentRegion;
  LOptions := TKMSOptions.Create;
  LOptions.Region := CurrentRegion;
  KMSClient := TKMSClient.Create(LOptions);
end;

procedure TNewSecretForm.SetKMSClient(const AKMSClient: IKMSClient);
begin
  FKMSClient := AKMSClient;
  ActReloadEncryptionKeys.Execute;
end;

procedure TNewSecretForm.ValidateInputs;
begin
  BtnStore.Enabled := not EditName.Text.IsEmpty
    and not MemoPlaintext.Text.IsEmpty;
end;

end.
