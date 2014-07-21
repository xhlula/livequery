unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, IdSocketHandle, IdBaseComponent,
  IdComponent, IdUDPBase, IdUDPServer, ComCtrls, Themes,
  SynEdit, SynEditHighlighter, SynHighlighterSQL, ExtCtrls,
  StdCtrls, StrUtils, DateUtils, ActnList,
  ToolWin, ImgList, ActnMan, ActnCtrls,
  PlatformDefaultStyleActnCtrls;

type
  TfrmMain = class(TForm)
    UDPServer: TIdUDPServer;
    SynSQLSyn1: TSynSQLSyn;
    pnlQuery: TPanel;
    lvQueries: TListView;
    ActionList1: TActionList;
    ImageList1: TImageList;
    ActionToolBar1: TActionToolBar;
    ActionManager1: TActionManager;
    actnClear: TAction;
    actnListen: TAction;
    Panel1: TPanel;
    SynEdit: TSynEdit;
    Panel2: TPanel;
    lvResult: TListView;
    memMessage: TMemo;
    Splitter1: TSplitter;
    procedure FormCreate(Sender: TObject);

    procedure actnClearExecute(Sender: TObject);
    procedure actnListenExecute(Sender: TObject);
    procedure lvQueriesChange(Sender: TObject; Item: TListItem; Change: TItemChange);
    procedure lvQueriesCompare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
    procedure UDPServerUDPRead(AThread: TIdUDPListenerThread;
      AData: TBytes; ABinding: TIdSocketHandle);
  private
    FNew: Integer;
    FAutoInc: Integer;
  
    procedure ResultSetToListView(json: string);
  public
    function FindGroupByCaption(const S: string): Integer;
    procedure UpdateCaption;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses superobject;

procedure TfrmMain.actnClearExecute(Sender: TObject);
begin
  lvQueries.Clear;
  SynEdit.Clear;
  memMessage.Visible := False;
  lvResult.Visible   := False;
  FNew := 0;
  FAutoInc := 0;
  UpdateCaption;
end;

procedure TfrmMain.actnListenExecute(Sender: TObject);
begin
  //
end;

function TfrmMain.FindGroupByCaption(const S: string): Integer;
begin
  Result := -1;
  for Result := 0 to lvQueries.Groups.Count -1 do
    if lvQueries.Groups[Result].Header = S then
      Exit;

  with lvQueries.Groups.Add do
  begin
    Header := S;
    Result := GroupID;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  DoubleBuffered := True;
  SynEdit.DoubleBuffered := True;
  FNew := 0;
end;

procedure TfrmMain.lvQueriesChange(Sender: TObject; Item: TListItem; Change: TItemChange);
begin
  if Assigned(lvQueries.Selected) and (lvQueries.Selected.SubItems.Text <> '') then
  begin
    SynEdit.Text       := lvQueries.Selected.SubItems[0];
    memMessage.Text    := lvQueries.Selected.SubItems[1];
    ResultSetToListView(lvQueries.Selected.SubItems[2]);

    memMessage.Visible := lvResult.Items.Count = 0;
    
    lvResult.Visible   := not memMessage.Visible;
    if lvQueries.Selected.GroupID = 0 then
    begin
      Dec(FNew);
      UpdateCaption;
    end;

    lvQueries.Selected.GroupID := 1;
  end
  else
  begin
    SynEdit.Text       := '';
    memMessage.Text    := '';
    memMessage.Visible := False;
    lvResult.Visible   := False;
  end;
end;

procedure TfrmMain.lvQueriesCompare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
begin
  Compare := Integer(Item2.Data) - Integer(Item1.Data);
end;

procedure TfrmMain.ResultSetToListView(json: string);
var
  Obj: ISuperObject;
  Item, Entry: TSuperAvlEntry;
  I: Integer;
  listItem: TListItem;
  Col: TListColumn;
begin
  Obj := SO(json);

  try
    lvResult.Items.BeginUpdate;
    lvResult.Items.Clear;
    lvResult.Columns.Clear;

    if Obj.AsArray.Length = 0 then
      Exit;

    with lvResult.Columns.Add do
    begin
      Caption := '';
      Width := 30;
    end;
    
    for Item in Obj.AsArray[0].AsObject do
    begin
      Col := lvResult.Columns.Add;
      Col.Width := -1;         
      Col.Width := -2;
      Col.Caption := Item.Name;
    end;

    for I := 0 to Obj.AsArray.Length - 1 do
    begin
      listItem := lvResult.Items.Add;
      listItem.Caption := IntToStr(listItem.Index + 1);

      for Item in Obj.AsArray[I].AsObject do
        listItem.SubItems.Add(Item.Value.AsString);
    end;


    // ignore first column, which is the row number
    for I := 1 to lvResult.Columns.Count - 1 do
      if lvResult.Columns[i].Width < 100 then
        lvResult.Columns[i].Width := 100;
  finally
    lvResult.Items.EndUpdate;
    lvResult.Refresh;
    
  end;
end;

procedure TfrmMain.UDPServerUDPRead(AThread: TIdUDPListenerThread; AData: TBytes; ABinding: TIdSocketHandle);
var
  Msg: AnsiString;
  Obj: ISuperObject;
begin
  if not actnListen.Checked then
    Exit;

  SetString(Msg, PAnsiChar(@AData[0]), Length(AData));

  Obj := SO(Msg);

  FlashWindow(Application.Handle, True);
  Inc(FNew);
  UpdateCaption;
  with lvQueries.Items.Add do
  begin
    GroupID := 0; //FindGroupByCaption(Obj.AsObject.S['remote_address']);
    Caption := FormatDateTime('hh:mm:ss', Now);
    SubItems.Add(Obj.AsObject.S['query']);
    SubItems.Add(Obj.AsObject.S['message']);
    SubItems.Add(Obj.AsObject.S['rows']);

    if Obj.AsObject.B['error'] then
      ImageIndex := 3
    else
      ImageIndex := 4;

    Data := Pointer(FAutoInc);
    Inc(FAutoInc);
  end;
end;

procedure TfrmMain.UpdateCaption;
begin
  if FNew <= 0 then
    Caption := Application.Title
  else
    Caption := Format('[%d] %s', [FNew, Application.Title]);
end;

end.
