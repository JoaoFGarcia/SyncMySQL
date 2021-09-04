unit uMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, System.Win.TaskbarCore,
  Vcl.Taskbar, Vcl.StdCtrls, Vcl.Menus, Vcl.AppEvnts,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage,
  cxEdit, cxNavigator, dxDateRanges, dxScrollbarAnnotations, Data.DB, cxDBData,
  cxGridLevel, cxClasses, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, Vcl.WinXPickers, dxCore, cxGridStrs, Vcl.Samples.Spin,
  uGlobal, DateUtils, FireDac.DApt, cxTimeEdit;

type
  TState = (stRunning, stPaused, stTerminated, stIdle);

  TfrmMain = class(TForm)
    tray: TTrayIcon;
    ppmTray: TPopupMenu;
    appEvents: TApplicationEvents;
    Sair1: TMenuItem;
    Restaurar1: TMenuItem;
    cxGrid1DBTableView1: TcxGridDBTableView;
    cxGrid1Level1: TcxGridLevel;
    cxGrid1: TcxGrid;
    Panel1: TPanel;
    Label1: TLabel;
    btnAlternar: TButton;
    Button1: TButton;
    mtMain: TFDMemTable;
    dsMain: TDataSource;
    mtMainDIA: TDateField;
    mtMainTIME: TTimeField;
    mtMainMESSAGE: TStringField;
    cxGrid1DBTableView1DIA: TcxGridDBColumn;
    cxGrid1DBTableView1TIME: TcxGridDBColumn;
    cxGrid1DBTableView1MESSAGE: TcxGridDBColumn;
    edtMinutes: TSpinEdit;
    procedure appEventsMinimize(Sender: TObject);
    procedure Sair1Click(Sender: TObject);
    procedure Restaurar1Click(Sender: TObject);
    procedure trayDblClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnAlternarClick(Sender: TObject);
  private
    procedure Restore;
    { Private declarations }
  public
    { Public declarations }
  end;

  TCore = class(TThread)
  private
    iInterval: Integer;
    procedure Log(sMessage: String);
  protected
    procedure Execute; override;
  public
    constructor Create(Interval: Integer); overload;
  end;

var
  frmMain: TfrmMain;
  Core: TCore;
  State: TState;

implementation

{$R *.dfm}

uses uConfig;

function GetState(): TState;
begin
  Result := State;
end;

procedure SetState(Value: TState);
begin
  State := Value;

  if State in [stRunning] then
    frmMain.btnAlternar.Caption := 'Parar'
  else
    frmMain.btnAlternar.Caption := 'Iniciar'
end;

procedure TfrmMain.Restore();
begin
  tray.Visible := False;
  Show();
  WindowState := wsNormal;
  Application.Restore();
end;

procedure TfrmMain.appEventsMinimize(Sender: TObject);
begin
  Hide();
  WindowState := wsMinimized;

  tray.Visible := True;
  tray.ShowBalloonHint;
end;

procedure TfrmMain.btnAlternarClick(Sender: TObject);
begin
  if State in [stIdle, stTerminated] then
  begin
    TGlobal.Interval := edtMinutes.Value * 60000;
    WriteConfig;

    Core := TCore.Create(TGlobal.Interval);
    Core.Start;
    SetState(stRunning);
  end
  else if State = stRunning then
  begin
    SetState(stTerminated);
    Core.Terminate;
  end;
end;

procedure TfrmMain.Button1Click(Sender: TObject);
begin
  frmConfig := TfrmConfig.Create(nil);
  frmConfig.ShowModal;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  State := stIdle;
  mtMain.CreateDataSet;
  if TGlobal.Interval > 0 then
    edtMinutes.Value := TGlobal.Interval div 60000;
end;

procedure TfrmMain.Restaurar1Click(Sender: TObject);
begin
  Restore;
end;

procedure TfrmMain.Sair1Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TfrmMain.trayDblClick(Sender: TObject);
begin
  Restore;
end;

constructor TCore.Create(Interval: Integer);
begin
  inherited Create(True);
  iInterval := Interval;
  Self.FreeOnTerminate := True;
end;

procedure TCore.Execute;
var
  Tables     : TStringList;
  tempTable,
  fName      : String;
  value      : WideString;
  tempField  : TField;
  Mount      : TStringList;
  Connection : TFDConnection;
  Query      : TFDQuery;

  i          : Integer;
  lastC      : Integer;
begin
  inherited;
  Log('Processo de cópias de segurança iniciado.');
  Log('Intervalo de ' + IntToStr(iInterval) + ' milisegundos');
  Connection := TFDConnection.Create(nil);
  Query      := TFDQuery.Create(nil);
  Tables     := TStringList.Create;
  Mount      := TStringList.Create;
  try
    Connection.DriverName := 'MySQL';
    Connection.Params.add('Server=' + TGlobal.DB.Host);
    Connection.Params.UserName := TGlobal.DB.Username;
    Connection.Params.Password := TGlobal.DB.Password;
    Connection.Params.Database := TGlobal.DB.Database;
    Query.Connection           := Connection;
    Query.SQL.Text             := 'SELECT TABLE_NAME AS TABLE_NAME'+
                                  '  FROM INFORMATION_SCHEMA.TABLES'+
                                  ' WHERE TABLE_SCHEMA = ' + QuotedStr(TGlobal.DB.Database)+
                                  '   AND TABLE_TYPE != "VIEW"';
    Connection.Connected := True;
    Query.Open();

    if Query.IsEmpty then
      Exit;

    Query.First;
    while not (Query.Eof) do
    begin
      Tables.Add(Query.FieldByName('TABLE_NAME').AsString);
      Query.Next;
    end;

    Connection.Close;

    while State in [stRunning] do
    begin
      Sleep(iInterval);

      Mount.Clear;

      if State in [stRunning] then
      begin
        Log('Realizando cópia de segurança...');
        Mount.Add('-- SyncMysql Backup');
        Mount.Add('--   Host:     ' + TGlobal.DB.host);
        Mount.Add('--   Database: ' + TGlobal.DB.Database);
        Mount.Add('--   Data: ' + TGlobal.DB.host);
        Mount.add('-- Triggered: ' + FormatDateTime('dd/mm/yyyy hh:mm', Now));

        Connection.Open;
        for tempTable in Tables do
        begin
          Query.SQL.Text := 'SELECT * FROM ' + tempTable + ';';
          Query.Open;

          if Query.IsEmpty then
            Continue;

          if Mount.Count > 0 then
          begin
            Mount.Add('');
            Mount.Add('');
          end;

          Mount.Add('/* -------------------------------------------- */');
          Mount.Add('/* ' + UpperCase(tempTable) + ' DATA */');
          //Mount.Add('DELETE FROM ' + UpperCase(tempTable) + ';');

          Mount.Add('INSERT IGNORE INTO ' + UpperCase(tempTable) + '(');
          for i := 0 to Query.Fields.Count - 1 do
          begin
            Mount[Mount.Count -1] := Mount[Mount.Count -1] + UpperCase(Query.Fields[i].FieldName);
            if not (i = Query.fields.Count -1) then
              Mount[Mount.Count -1] := Mount[Mount.Count -1] + ', ';
          end;

          Mount[Mount.Count -1] := Mount[Mount.Count -1] + ') VALUES';
          Query.FetchAll;
          Query.First;
          while not (Query.Eof) do
          begin
            Mount.Add('    (');
            lastC := Mount.count - 1;
            for i := 0 to Query.Fields.Count - 1 do
            begin;
              Value := EmptyStr;

              if Query.Fields[i].DataType in [ftInteger] then
                value := IntToStr(Query.Fields[i].AsInteger)
              else if Query.Fields[i].DataType in [ftFloat] then
                value := FloatToStr(Query.Fields[i].AsFloat)
              else
                value := QuotedStr(Query.Fields[i].AsString);

                Mount[lastC] := Mount[lastC] + value;

              if not (i = Query.fields.Count - 1) then
                Mount[lastC] := Mount[lastC] + ', ';
            end;
            if not (Query.RecNo = query.RecordCount) then
              Mount[lastC] := Mount[lastC] + '),';

            Query.Next;
          end;

          Mount[lastC] := Mount[lastC] + ');';

          Mount.Add('/* -------------------------------------------- */');
        end;
        fName := 'SyncMysql_' + FormatDateTime('ddmmyyyy_hhmm', Now) + '.sql';
        Mount.SaveToFile(TGlobal.SavePath  + '\' + fName);
        Log('Cópia salva em ' + fName);
      end;
    end;
  except
    on e: Exception do
    begin
      Log('Erro:' + e.Message);
    end;
  end;
  Log('Thread finalizado.');

  FreeAndNil(Connection);
  FreeAndNil(Query);
  FreeAndNil(Tables);
  FreeAndNil(Mount);
end;

procedure TCore.Log(sMessage: String);
begin
  Synchronize(Self,
    procedure
    begin
      frmMain.mtMain.DisableControls;
      frmMain.mtMain.Insert;
      frmMain.mtMainDIA.AsDateTime := Date;
      frmMain.mtMainTIME.AsDateTime := Time;
      frmMain.mtMainMESSAGE.AsString := sMessage;
      frmMain.mtMain.Post;
      frmMain.mtMain.EnableControls
    end);
end;

initialization

cxSetResourceString(@scxGridGroupByBoxCaption, 'Arraste um campo para agrupar');

end.
