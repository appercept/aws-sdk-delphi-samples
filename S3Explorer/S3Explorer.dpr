program S3Explorer;

uses
  System.StartUpCopy,
  FMX.Forms,
  Form.Main in 'Form.Main.pas' {MainForm},
  Form.ObjectDetails in 'Form.ObjectDetails.pas' {ObjectDetailsForm},
  Form.FileUpload in 'Form.FileUpload.pas' {FileUploadForm},
  Frame.PartProgress in 'Frame.PartProgress.pas' {PartProgressFrame: TFrame};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
