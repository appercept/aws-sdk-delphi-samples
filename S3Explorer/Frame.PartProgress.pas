unit Frame.PartProgress;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation;

type
  TPartProgressFrame = class(TFrame)
    LblCaption: TLabel;
    PartProgressBar: TProgressBar;
  private
    const
    OneMebiByte = 1024 * 1024;

    var
    FPartNumber: Integer;
    FPartSize: Int64;
    FProgress: Int64;
    function GetProgress: Int64;
    procedure SetProgress(const AValue: Int64);
    function GetPartSize: Int64;
    procedure SetPartSize(const AValue: Int64);
    procedure SetPartNumber(const AValue: Integer);
    procedure UpdateCaption;
  public
    property PartNumber: Integer read FPartNumber write SetPartNumber;
    property PartSize: Int64 read GetPartSize write SetPartSize;
    property Progress: Int64 read GetProgress write SetProgress;
  end;

implementation

{$R *.fmx}

{ TPartProgressFrame }

function TPartProgressFrame.GetPartSize: Int64;
begin
  Result := FPartSize;
end;

function TPartProgressFrame.GetProgress: Int64;
begin
  Result := FProgress;
end;

procedure TPartProgressFrame.SetPartNumber(const AValue: Integer);
begin
  FPartNumber := AValue;
  Name := Format('PartProgressFrame%d', [PartNumber]);
  UpdateCaption;
end;

procedure TPartProgressFrame.SetPartSize(const AValue: Int64);
begin
  FPartSize := AValue;
  PartProgressBar.Max := PartSize;
  UpdateCaption;
end;

procedure TPartProgressFrame.SetProgress(const AValue: Int64);
begin
  FProgress := AValue;
  PartProgressBar.Value := Progress;
  UpdateCaption;
end;

procedure TPartProgressFrame.UpdateCaption;
begin
  LblCaption.Text := Format('Part %d: %.2f of %.2fMiB', [PartNumber, Progress / OneMebiByte, PartSize / OneMebiByte]);
end;

end.
