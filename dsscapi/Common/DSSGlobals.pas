unit DSSGlobals;
{
  ----------------------------------------------------------
  Copyright (c) 2008-2019, Electric Power Research Institute, Inc.
  All rights reserved.
  ----------------------------------------------------------
}


{ Change Log
 8-14-99  SolutionAbort Added

 10-12-99 AutoAdd constants added;
 4-17-00  Added IsShuntCapacitor routine, Updated constants
 10-08-02 Moved Control Panel Instantiation and show to here
 11-6-02  Removed load user DLL because it was causing a conflict
}

{$WARN UNIT_PLATFORM OFF}

interface

Uses Classes, DSSClassDefs, DSSObject, DSSClass, ParserDel, Hashlist, PointerList, PDELement,
     UComplex, Arraydef, CktElement, Circuit, IniRegSave, {$IFNDEF FPC}
     {$IFDEF MSWINDOWS}
     Graphics, System.IOUtils,
     {$ENDIF}
     {$ENDIF} inifiles,

     {Some units which have global vars defined here}
     Executive,
     solution,
     Spectrum,
     LoadShape,
     TempShape,
     PriceShape,
     XYCurve,
     GrowthShape,
     Monitor,
     EnergyMeter,
     Sensor,
     TCC_Curve,
     Feeder,
     WireData,
     CNData,
     TSData,
     LineSpacing,
     Storage,
     PVSystem,
     InvControl,
     ExpControl,
     {$IFNDEF FPC}ProgressForm, vcl.dialogs,{$ENDIF}
     {$IFDEF UNIX}BaseUnix,{$ENDIF}
     variants,
     Strutils,
     Types,
     SyncObjs,
     YMatrix,

     XfmrCode,
     Line,
     LineCode,
     LineGeometry,
     VSource,
     ISource,
     VCCS,
     ExecOptions,
     Load,
     Transformer,
     RegControl,
     Capacitor,
     Reactor,
     CapControl,
     Fault,
     Generator,
     GenDispatcher,
     StorageController,
     Relay,
     Recloser,
     Fuse,
     SwtControl,
     UPFC,
     UPFCControl,
     ESPVLControl,
     IndMach012,
     GICsource, // GIC source
     AutoTrans, // Auto Transformer
     VSConverter,
     GICLine,
     GICTransformer;


CONST
      CRLF = sLineBreak;

      PI =  3.14159265359;

      TwoPi = 2.0 * PI;

      RadiansToDegrees = 57.29577951;

      EPSILON = 1.0e-12;   // Default tiny floating point
      EPSILON2 = 1.0e-3;   // Default for Real number mismatch testing

      POWERFLOW  = 1;  // Load model types for solution
      ADMITTANCE = 2;

      // For YPrim matrices
      ALL_YPRIM = 0;
      SERIES = 1;
      SHUNT  = 2;

      {Control Modes}
      CONTROLSOFF = -1;
      EVENTDRIVEN =  1;
      TIMEDRIVEN  =  2;
      MULTIRATE   =  3;
      CTRLSTATIC  =  0;

      {Randomization Constants}
      GAUSSIAN  = 1;
      UNIFORM   = 2;
      LOGNORMAL = 3;

      {Autoadd Constants}
      GENADD = 1;
      CAPADD = 2;

      {ERRORS}
      SOLUTION_ABORT = 99;

      {For General Sequential Time Simulations}
      USEDAILY  = 0;
      USEYEARLY = 1;
      USEDUTY   = 2;
      USENONE   =-1;

      {Earth Model}
      SIMPLECARSON  = 1;
      FULLCARSON    = 2;
      DERI          = 3;

      {Profile Plot Constants}
      PROFILE3PH = 9999; // some big number > likely no. of phases
      PROFILEALL = 9998;
      PROFILEALLPRI = 9997;
      PROFILELLALL = 9996;
      PROFILELLPRI = 9995;
      PROFILELL    = 9994;
      PROFILEPUKM = 9993;  // not mutually exclusive to the other choices 9999..9994
      PROFILE120KFT = 9992;  // not mutually exclusive to the other choices 9999..9994

VAR

   DLLFirstTime   :Boolean=TRUE;
   DLLDebugFile   :TextFile;
   ProgramName    :String;
{$IFNDEF DSS_CAPI} // Disable DSS_Registry completely when building the DSS_CAPI DLL
   DSS_Registry   :TIniRegSave; // Registry   (See Executive)
{$ENDIF}
{$IFDEF DSS_CAPI}
   DSS_CAPI_INFO_SPARSE_COND : Boolean;
   // Global variables for the OpenDSS Viewer
   DSS_CAPI_EARLY_ABORT : Boolean;
   DSS_CAPI_ALLOW_EDITOR: Boolean;
   DSS_CAPI_LOADS_TERMINAL_CHECK: Boolean = True;
{$ENDIF}
   DSS_Viz_installed   :Boolean=False; // OpenDSS viewer (flag to mark a local installation)
   DSS_Viz_path: String;
   DSS_Viz_enable: Boolean=False;

   IsDLL,
   NoFormsAllowed  :Boolean;

   ActiveCircuit   :Array of TDSSCircuit;
   ActiveDSSClass  :Array of TDSSClass;
   LastClassReferenced:Array of Integer;  // index of class of last thing edited
   ActiveDSSObject :Array of TDSSObject;
   MaxCircuits     :Integer;
   MaxBusLimit     :Integer; // Set in Validation
   MaxAllocationIterations :Integer;
   Circuits        :TPointerList;
   DSSObjs         :Array of TPointerList;

   AuxParser       :Array of TParser;  // Auxiliary parser for use by anybody for reparsing values

//{****} DebugTrace:TextFile;


   ErrorPending       :Boolean;
   CmdResult,
   ErrorNumber        :Integer;
   LastErrorMessage   :String;

   DefaultEarthModel  :Integer;
   ActiveEarthModel   :Array of Integer;

   LastFileCompiled   :String;
   LastCommandWasCompile :Boolean;

   CALPHA             :Complex;  {120-degree shift constant}
   SQRT2              :Double;
   SQRT3              :Double;
   InvSQRT3           :Double;
   InvSQRT3x1000      :Double;
   SolutionAbort      :Boolean;
   InShowResults      :Boolean;
   Redirect_Abort     :Boolean;
   In_Redirect        :Boolean;
   DIFilesAreOpen     :array of Boolean;
   AutoShowExport     :Boolean;
   SolutionWasAttempted : Array of Boolean;

   GlobalHelpString   :String;
   GlobalPropertyValue:String;
   GlobalResult       :String;
   LastResultFile     :String;
   VersionString      :String;

   LogQueries         :Boolean;
   QueryFirstTime     :Boolean;
   QueryLogFileName   :String;
   QueryLogFile       :TextFile;

   DefaultEditor    :String;     // normally, Notepad
   DefaultFontSize  :Integer;
   DefaultFontName  :String;
   DefaultFontStyles :{$IFNDEF FPC}TFontStyles{$ELSE}Integer{$ENDIF};
   DSSFileName      :String;     // Name of current exe or DLL
   DSSDirectory     :String;     // where the current exe resides
   StartupDirectory :String;     // Where we started
   DataDirectory    :array of String;     // used to be DSSDataDirectory
   OutputDirectory  :array of String;     // output files go here, same as DataDirectory if writable
   CircuitName_     :array of String;     // Name of Circuit with a "_" appended
   ActiveYPrim      :Array of pComplexArray; // Created to solve the problems

   DefaultBaseFreq  :Double;
   DaisySize        :Double;

   // Some commonly used classes   so we can find them easily
   LoadShapeClass     :Array of TLoadShape;
   TShapeClass        :Array of TTshape;
   PriceShapeClass    :Array of TPriceShape;
   XYCurveClass       :Array of TXYCurve;
   GrowthShapeClass   :Array of TGrowthShape;
   SpectrumClass      :Array of TSpectrum;
   SolutionClass      :Array of TDSSClass;
   EnergyMeterClass   :Array of TEnergyMeter;
   // FeederClass        :TFeeder;
   MonitorClass       :Array of TDSSMonitor;
   SensorClass        :Array of TSensor;
   TCC_CurveClass     :Array of TTCC_Curve;
   WireDataClass      :Array of TWireData;
   CNDataClass        :Array of TCNData;
   TSDataClass        :Array of TTSData;
   LineSpacingClass   :Array of TLineSpacing;
   LineCodeClass      :Array of TLineCode;
   LineGeometryClass      :Array of TLineGeometry;
   StorageClass       :Array of TStorage;
   PVSystemClass      :Array of TPVSystem;
   InvControlClass    :Array of TInvControl;
   ExpControlClass    :Array of TExpControl;
   
   XfmrCodeClass      :Array of TXfmrCode;
   LineClass          :Array of TLine;
   VSourceClass       :Array of TVSource;
   ISourceClass       :Array of TISource;
   VCSSClass          :Array of TVCCS;
   LoadClass          :Array of TLoad;
   TransformerClass   :Array of TTransf;
   RegControlClass    :Array of TRegControl;
   CapacitorClass     :Array of TCapacitor;
   ReactorClass       :Array of TReactor;
   CapControlClass    :Array of TCapControl;
   FaultClass         :Array of TFault;
   GeneratorClass     :Array of TGenerator;
   GenDispatcherClass :Array of TGenDispatcher;
   StorageControllerClass: Array of TStorageController;
   RelayClass         :Array of TRelay;
   RecloserClass      :Array of TRecloser;
   FuseClass          :Array of TFuse;
   SwtControlClass    :Array of TSwtControl;
   UPFCClass          :Array of TUPFC;
   UPFCControlClass   :Array of TUPFCControl;
   ESPVLControlClass  :Array of TESPVLControl;
   IndMach012Class    :Array of TIndMach012;
   GICsourceClass     :Array of TGICsource; // GIC source
   AutoTransClass     :Array of TAutoTrans; // Auto Transformer
   VSConverterClass   :Array of TVSConverter;
   GICTransformerClass:Array of TGICTransformer;
   GICLineClass       :Array of TGICLine;
   ActiveVSource      :Array of TVsource;   // created on 01/14/2019 to facilitate actors to modify VSources while simulating

   EventStrings       :Array of TStringList;
   SavedFileList      :Array of TStringList;
   ErrorStrings       :Array of TStringList;

   DSSClassList       :Array of TPointerList; // pointers to the base class types
   ClassNames         :Array of THashList;

   UpdateRegistry     :Boolean;  // update on program exit
   CPU_Freq           : int64;          // Used to store the CPU frequency
   CPU_Cores          : integer;
   ActiveActor        : integer;
   NumOfActors        : integer;
   ActorCPU           : Array of integer;
   ActorStatus        : Array of integer;
   ActorProgressCount : Array of integer;
   {$IFNDEF FPC}
   ActorProgress      : Array of TProgress;
   {$ENDIF}
   ActorPctProgress   : Array of integer;
   ActorHandle        : Array of TSolver;

   IsSolveAll,
   AllActors,
   ADiakoptics,
   Parallel_enabled,
   ConcatenateReports,

   ProgressCmd,
   IncMat_Ordered     : Boolean;
   Parser             : Array of TParser;
   ActorMA_Msg        : Array of TEvent;  // Array to handle the events of each actor


{*******************************************************************************
*    Nomenclature:                                                             *
*                  OV_ Overloads                                               *
*                  VR_ Voltage report                                          *
*                  DI_ Demand interval for each meter. Moved to EnergyMeter.pas*
*                  SDI_ System Demand interval                                 *
*                  TDI_ DI Totals                                              *
*                  FM_  Meter Totals                                           *
*                  SM_  System Meter                                           *
*                  EMT_  Energy Meter Totals                                   *
*                  PHV_  Phase Voltage Report. Moved to EnergyMeter.pas        *
*     These prefixes are applied to the variables of each file mapped into     *
*     Memory using the MemoryMap_Lib                                           *
********************************************************************************
}
   OV_MHandle             : array of TBytesStream;  // a. Handle to the file in memory
   VR_MHandle             : array of TBytesStream;
   SDI_MHandle            : array of TBytesStream;
   TDI_MHandle            : array of TBytesStream;
   SM_MHandle             : array of TBytesStream;
   EMT_MHandle            : array of TBytesStream;
   FM_MHandle             : array of TBytesStream;

//*********** Flags for appending Files*****************************************
   OV_Append              : array of Boolean;
   VR_Append              : array of Boolean;
   DI_Append              : array of Boolean;
   SDI_Append             : array of Boolean;
   TDI_Append             : array of Boolean;
   SM_Append              : array of Boolean;
   EMT_Append             : array of Boolean;
   PHV_Append             : array of Boolean;
   FM_Append              : array of Boolean;

//***********************Seasonal QSTS variables********************************
   SeasonalRating         : Boolean;    // Tells the energy meter if the seasonal rating feature is active
   SeasonSignal           : String;     // Stores the name of the signal for selecting the rating dynamically

   DSSExecutive: Array of TExecutive;

   DSSClasses             : TDSSClasses;

PROCEDURE DoErrorMsg(Const S, Emsg, ProbCause :String; ErrNum:Integer);
PROCEDURE DoSimpleMsg(Const S :String; ErrNum:Integer);

PROCEDURE ClearAllCircuits;

PROCEDURE SetObject(const param :string);
FUNCTION  SetActiveBus(const BusName:String):Integer;
PROCEDURE SetDataPath(const PathName:String);

PROCEDURE SetLastResultFile(Const Fname:String);

PROCEDURE MakeNewCircuit(Const Name:String);

PROCEDURE AppendGlobalResult(Const s:String);
PROCEDURE AppendGlobalResultCRLF(const S:String);  // Separate by CRLF

PROCEDURE ResetQueryLogFile;
PROCEDURE WriteQueryLogFile(Const Prop, S:String);

PROCEDURE WriteDLLDebugFile(Const S:String);

{$IFNDEF DSS_CAPI} // Disable DSS_Registry completely when building the DSS_CAPI DLL
PROCEDURE ReadDSS_Registry;
PROCEDURE WriteDSS_Registry;
{$ENDIF}

FUNCTION IsDSSDLL(Fname:String):Boolean;

Function GetOutputDirectory:String;

Procedure MyReallocMem(Var p:Pointer; newsize:integer);
Function MyAllocMem(nbytes:Cardinal):Pointer;

procedure New_Actor_Slot();
procedure New_Actor(ActorID:  Integer);
procedure Wait4Actors(WType : Integer);

procedure DoClone();

procedure Delay(TickTime : Integer);


implementation



USES  {Forms,   Controls,}
     {$IFDEF MSWINDOWS}
     Windows,
     {$ENDIF}
     SysUtils,
     {$IFDEF DSS_CAPI}
//     CAPI_Metadata,
     {$ENDIF}
     {$IFDEF FPC}
     resource, versiontypes, versionresource, dynlibs, CmdForms,
       {$IFNDEF WINDOWS}
       cpucount,
       {$ENDIF}
     {$ELSE}
     DSSForms, SHFolder,
     ScriptEdit,
     {$ENDIF}
     Parallel_Lib;
     {Intrinsic Ckt Elements}

TYPE

   THandle = NativeUint;

   TDSSRegister = function(var ClassName: pchar):Integer;  // Returns base class 1 or 2 are defined
   // Users can only define circuit elements at present

VAR

   LastUserDLLHandle: THandle;
   DSSRegisterProc:TDSSRegister;   // of last library loaded

{$IFDEF FPC}
FUNCTION GetDefaultDataDirectory: String;
Begin
{$IFDEF UNIX}
  Result := GetEnvironmentVariable('HOME') + PathDelim + 'Documents';
{$ENDIF}
{$IF (defined(Windows) or defined(MSWindows))}
  Result := GetEnvironmentVariable('HOMEDRIVE') + GetEnvironmentVariable('HOMEPATH') + PathDelim + 'Documents';
{$ENDIF}
end;

FUNCTION GetDefaultScratchDirectory: String;
Begin
  {$IFDEF UNIX}
  Result := '/tmp';
  {$ENDIF}
  {$IF (defined(Windows) or defined(MSWindows))}
  Result := GetEnvironmentVariable('LOCALAPPDATA');
  {$ENDIF}
End;
{$ELSE}
FUNCTION GetDefaultDataDirectory: String;
Var
  ThePath:Array[0..MAX_PATH] of char;
Begin
  FillChar(ThePath, SizeOF(ThePath), #0);
  {$IFDEF MSWINDOWS}
  SHGetFolderPath (0, CSIDL_PERSONAL, 0, 0, ThePath);
  {$ENDIF}
  Result := ThePath;
End;

FUNCTION GetDefaultScratchDirectory: String;
Var
  ThePath:Array[0..MAX_PATH] of char;
Begin
  FillChar(ThePath, SizeOF(ThePath), #0);
  {$IFDEF MSWINDOWS}
  SHGetFolderPath (0, CSIDL_LOCAL_APPDATA, 0, 0, ThePath);
  {$ENDIF}
  Result := ThePath;
End;
{$ENDIF}

function GetOutputDirectory:String;
begin
  Result := OutputDirectory[ActiveActor];
end;

{--------------------------------------------------------------}
FUNCTION IsDSSDLL(Fname:String):Boolean;

Begin
    Result := FALSE;

    // Ignore if "DSSLIB.DLL"
    If CompareText(ExtractFileName(Fname),'dsslib.dll')=0 Then Exit;

   LastUserDLLHandle := LoadLibrary(pchar(Fname));
   IF LastUserDLLHandle <> 0 then BEGIN

   // Assign the address of the DSSRegister proc to DSSRegisterProc variable
    @DSSRegisterProc := GetProcAddress(LastUserDLLHandle, 'DSSRegister');
    IF @DSSRegisterProc <> nil THEN Result := TRUE
    ELSE FreeLibrary(LastUserDLLHandle);

  END;

End;

//----------------------------------------------------------------------------
PROCEDURE DoErrorMsg(Const S, Emsg, ProbCause:String; ErrNum:Integer);

VAR
    Msg:String;
    Retval:Integer;
Begin
     writeln(stderr, S);
     Halt(1);

     Msg := Format('Error %d Reported From OpenDSS Intrinsic Function: ', [Errnum])+ CRLF  + S
             + CRLF   + CRLF + 'Error Description: ' + CRLF + Emsg
             + CRLF   + CRLF + 'Probable Cause: ' + CRLF+ ProbCause;

     If Not NoFormsAllowed Then Begin

         If In_Redirect Then
         Begin
           RetVal := DSSMessageDlg(Msg, FALSE);
           If RetVal = -1 Then Redirect_Abort := True;
         End
         Else
           DSSMessageDlg(Msg, TRUE);

     End
     Else
     Begin
        {$IFDEF DSS_CAPI}
        if DSS_CAPI_EARLY_ABORT then
            Redirect_Abort := True;
        {$ENDIF}
     End;

     LastErrorMessage := Msg;
     ErrorNumber := ErrNum;
     AppendGlobalResultCRLF(Msg);
     SolutionAbort  :=  True;
End;

//----------------------------------------------------------------------------
PROCEDURE AppendGlobalResultCRLF(const S:String);

Begin
    If Length(GlobalResult) > 0
    THEN GlobalResult := GlobalResult + CRLF + S
    ELSE GlobalResult := S;

    ErrorStrings[ActiveActor].Add(Format('(%d) %s' ,[ErrorNumber, S]));  // Add to Error log
End;

//----------------------------------------------------------------------------
PROCEDURE DoSimpleMsg(Const S:String; ErrNum:Integer);

VAR
    Retval:Integer;
Begin
    writeln(stderr, S);
    Halt(1);

      IF Not NoFormsAllowed Then Begin
        IF In_Redirect THEN
        Begin
         RetVal := DSSMessageDlg(Format('(%d) OpenDSS %s%s', [Errnum, CRLF, S]), FALSE);
            {$IFDEF DSS_CAPI}
            if DSS_CAPI_EARLY_ABORT then
                Redirect_Abort := True;
            {$ENDIF}
            IF RetVal = -1 THEN
                Redirect_Abort := True;
       End
       ELSE
         DSSInfoMessageDlg(Format('(%d) OpenDSS %s%s', [Errnum, CRLF, S]));
    End
    Else
    Begin
        {$IFDEF DSS_CAPI}
        if DSS_CAPI_EARLY_ABORT then
            Redirect_Abort := True;
        {$ENDIF}
      End;

     LastErrorMessage := S;
     ErrorNumber := ErrNum;
     AppendGlobalResultCRLF(S);
End;



//----------------------------------------------------------------------------
PROCEDURE SetObject(const param :string);

{Set object active by name}

VAR
   dotpos :Integer;
   ObjName, ObjClass :String;

Begin

      // Split off Obj class and name
      dotpos := Pos('.', Param);
      CASE dotpos OF
         0:ObjName := Copy(Param, 1, Length(Param));  // assume it is all name; class defaults
      ELSE Begin
           ObjClass := Copy(Param, 1, dotpos-1);
           ObjName  := Copy(Param, dotpos+1, Length(Param));
           End;
      End;

      IF Length(ObjClass) > 0 THEN SetObjectClass(ObjClass);

      ActiveDSSClass[ActiveActor] := DSSClassList[ActiveActor].Get(LastClassReferenced[ActiveActor]);
      IF ActiveDSSClass[ActiveActor] <> Nil THEN
      Begin
        IF Not ActiveDSSClass[ActiveActor].SetActive(Objname) THEN
        Begin // scroll through list of objects untill a match
          DoSimpleMsg('Error! Object "' + ObjName + '" not found.'+ CRLF + parser[ActiveActor].CmdString, 904);
        End
        ELSE
        With ActiveCircuit[ActiveActor] Do
        Begin
           CASE ActiveDSSObject[ActiveActor].DSSObjType OF
                DSS_OBJECT: ;  // do nothing for general DSS object

           ELSE Begin   // for circuit types, set ActiveCircuit Element, too
                 ActiveCktElement := ActiveDSSClass[ActiveActor].GetActiveObj;
                End;
           End;
        End;
      End
      ELSE
        DoSimpleMsg('Error! Active object type/class is not set.', 905);

End;

//----------------------------------------------------------------------------
FUNCTION SetActiveBus(const BusName:String):Integer;


Begin

   // Now find the bus and set active
   Result := 0;

   WITH ActiveCircuit[ActiveActor] Do
     Begin
        If BusList.ListSize=0 Then Exit;   // Buslist not yet built
        ActiveBusIndex := BusList.Find(BusName);
        IF   ActiveBusIndex=0 Then
          Begin
            Result := 1;
            AppendGlobalResult('SetActiveBus: Bus ' + BusName + ' Not Found.');
          End;
     End;

End;

PROCEDURE ClearAllCircuits;
var
  I : integer;
Begin

    for I := 1 to NumOfActors do
    begin
      if ActiveCircuit[I] <> nil then
      begin
        ActiveActor   :=  I;
        ActiveCircuit[I].NumCircuits := 0;
        FreeAndNil(ActiveCircuit[I]);
        Parser[I].Free;
        Parser[I] :=  nil;
        // In case the actor hasn't been destroyed
        if ActorHandle[I] <> nil then
        Begin
          ActorHandle[I].Send_Message(EXIT_ACTOR);
          ActorHandle[I].WaitFor;
          FreeAndNil(ActorHandle[I]);
        End;
      end;
    end;
    Circuits.Free;
    Circuits := TPointerList.Create(2);   // Make a new list of circuits
    // Revert on key global flags to Original States
    DefaultEarthModel     := DERI;
    LogQueries            := FALSE;
    MaxAllocationIterations := 2;
    ActiveActor           :=  1;
End;



PROCEDURE MakeNewCircuit(Const Name:String);

//Var
//   handle :Integer;
Var
    S:String;

Begin

    if ActiveActor <= CPU_Cores then
    begin
       If ActiveCircuit[ActiveActor] = nil Then
       Begin
           ActiveCircuit[ActiveActor] := TDSSCircuit.Create(Name);
           ActiveDSSObject[ActiveActor]:= ActiveSolutionObj;
           {*Handle := *}
           Circuits.Add(ActiveCircuit[ActiveActor]);
           Inc(ActiveCircuit[ActiveActor].NumCircuits);
           S                          := Parser[ActiveActor].Remainder;    // Pass remainder of string on to vsource.
           {Create a default Circuit}
           SolutionABort              := FALSE;
           {Voltage source named "source" connected to SourceBus}
           DSSExecutive[ActiveActor].Command       := 'New object=vsource.source Bus1=SourceBus ' + S;  // Load up the parser as if it were read in
           // Creates the thread for the actor if not created before
           If ActorHandle[ActiveActor]  = nil then New_Actor(ActiveActor);


       End
       Else
       Begin
           DoErrorMsg('MakeNewCircuit',
                      'Cannot create new circuit.',
                      'Max. Circuits Exceeded.'+CRLF+
                      '(Max no. of circuits='+inttostr(Maxcircuits)+')', 906);
       End;
    end
    else
    begin
           DoErrorMsg('MakeNewCircuit',
                      'Cannot create new circuit.',
                      'All the available CPUs have being assigned', 7000);

    end;
End;


PROCEDURE AppendGlobalResult(Const S:String);

// Append a string to Global result, separated by commas

Begin
    If Length(GlobalResult)=0 Then
        GlobalResult := S
    Else
        GlobalResult := GlobalResult + ', ' + S;
End;



{$IFDEF DSS_CAPI}
FUNCTION GetDSSVersion: String;
BEGIN
    Result := 'DSS v8';
    //Result := 'DSS C-API Library version ' + DSS_CAPI_VERSION +
    //          ' revision ' + DSS_CAPI_REV +
    //          ' based on OpenDSS SVN ' + DSS_CAPI_SVN_REV +
    //          ' (v8/parallel-machine variation)'
    //{$IFDEF DSS_CAPI_MVMULT}
    //          + ' MVMULT'
    //{$ENDIF}
    //          ;
END;
{$ELSE}
{$IFDEF FPC}
FUNCTION GetDSSVersion: String;
(* Unlike most of AboutText (below), this takes significant activity at run-    *)
 (* time to extract version/release/build numbers from resource information      *)
 (* appended to the binary.                                                      *)

VAR     Stream: TResourceStream;
         vr: TVersionResource;
         fi: TVersionFixedInfo;

BEGIN
   RESULT:= 'Unknown.';
   TRY

 (* This raises an exception if version info has not been incorporated into the  *)
 (* binary (Lazarus Project -> Project Options -> Version Info -> Version        *)
 (* numbering).                                                                  *)

     Stream:= TResourceStream.CreateFromID(HINSTANCE, 1, PChar(RT_VERSION));
     TRY
       vr:= TVersionResource.Create;
       TRY
         vr.SetCustomRawDataStream(Stream);
         fi:= vr.FixedInfo;
         RESULT := 'Version ' + IntToStr(fi.FileVersion[0]) + '.' + IntToStr(fi.FileVersion[1]) +
                ' release ' + IntToStr(fi.FileVersion[2]) + ' build ' + IntToStr(fi.FileVersion[3]) + LineEnding;
         vr.SetCustomRawDataStream(nil)
       FINALLY
         vr.Free
       END
     FINALLY
       Stream.Free
     END
   EXCEPT
   END
End;
{$ELSE}
FUNCTION GetDSSVersion: String;
var

  InfoSize, Wnd: DWORD;
  VerBuf: Pointer;
  FI: PVSFixedFileInfo;
  VerSize: DWORD;
  MajorVer, MinorVer, BuildNo, RelNo :DWORD;
  iLastError: DWord;

Begin
    Result := 'Unknown.' ;

    InfoSize := GetFileVersionInfoSize(PChar(DSSFileName), Wnd);
    if InfoSize <> 0 then
    begin
      GetMem(VerBuf, InfoSize);
      try
        if GetFileVersionInfo(PChar(DSSFileName), Wnd, InfoSize, VerBuf) then
          if VerQueryValue(VerBuf, '\', Pointer(FI), VerSize) then  Begin
            MinorVer := FI.dwFileVersionMS and $FFFF;
            MajorVer := (FI.dwFileVersionMS and $FFFF0000) shr 16;
            BuildNo :=  FI.dwFileVersionLS and $FFFF;
            RelNo := (FI.dwFileVersionLS and $FFFF0000) shr 16;
            Result := Format('%d.%d.%d.%d',[MajorVer, MinorVer, RelNo, BuildNo]);
            End;
      finally
        FreeMem(VerBuf);
      end;
    end
    else
    begin
      iLastError := GetLastError;
      Result := Format('GetFileVersionInfo failed: (%d) %s',
               [iLastError, SysErrorMessage(iLastError)]);
    end;

End;
    {$ENDIF}
{$ENDIF}


PROCEDURE WriteDLLDebugFile(Const S:String);

Begin

        AssignFile(DLLDebugFile, OutputDirectory[ActiveActor] + 'DSSDLLDebug.TXT');
        If DLLFirstTime then Begin
           Rewrite(DLLDebugFile);
           DLLFirstTime := False;
        end
        Else Append( DLLDebugFile);
        Writeln(DLLDebugFile, S);
        CloseFile(DLLDebugFile);

End;

{$IFNDEF UNIX}
function IsDirectoryWritable(const Dir: String): Boolean;
var
  TempFile: array[0..MAX_PATH] of Char;
begin
  if GetTempFileName(PChar(Dir), 'DA', 0, TempFile) <> 0 then
    {$IFDEF FPC}Result := DeleteFile(TempFile){$ELSE}
    {$IFDEF MSWINDOWS}
      Result := Windows.DeleteFile(TempFile)
    {$ENDIF}
    {$ENDIF}
  else
    Result := False;
end;
{$ELSE}
function IsDirectoryWritable(const Dir: String): Boolean;
begin
  Result := (FpAccess(PChar(Dir), X_OK or W_OK) = 0);
end;
{$ENDIF}

PROCEDURE SetDataPath(const PathName:String);
var
  ScratchPath: String;
// Pathname may be null
BEGIN
  if (Length(PathName) > 0) and not DirectoryExists(PathName) then Begin
  // Try to create the directory
    if not CreateDir(PathName) then Begin
      DosimpleMsg('Cannot create ' + PathName + ' directory.', 907);
      Exit;
    End;
  End;

  DataDirectory[ActiveActor] := PathName;

  // Put a \ on the end if not supplied. Allow a null specification.
  If Length(DataDirectory[ActiveActor]) > 0 Then Begin
    ChDir(DataDirectory[ActiveActor]);   // Change to specified directory
    If DataDirectory[ActiveActor][Length(DataDirectory[ActiveActor])] <> PathDelim Then DataDirectory[ActiveActor] := DataDirectory[ActiveActor] + PathDelim;
  End;

  // see if DataDirectory is writable. If not, set OutputDirectory to the user's appdata
  if IsDirectoryWritable(DataDirectory[ActiveActor]) then begin
    OutputDirectory[ActiveActor] := DataDirectory[ActiveActor];
  end else begin
    ScratchPath := GetDefaultScratchDirectory + PathDelim + ProgramName + PathDelim;
    if not DirectoryExists(ScratchPath) then CreateDir(ScratchPath);
    OutputDirectory[ActiveActor] := ScratchPath;
  end;
END;

{$IFNDEF DSS_CAPI} // Disable DSS_Registry completely when building the DSS_CAPI DLL
PROCEDURE ReadDSS_Registry;
Var  TestDataDirectory:string;
Begin
  DSS_Registry.Section := 'MainSect';
     DefaultEditor    := DSS_Registry.ReadString('Editor', 'Notepad.exe' );
     DefaultFontSize  := StrToInt(DSS_Registry.ReadString('ScriptFontSize', '8' ));
     DefaultFontName  := DSS_Registry.ReadString('ScriptFontName', 'MS Sans Serif' );
  {$IFNDEF FPC}
     DefaultFontStyles := [];
     If DSS_Registry.ReadBool('ScriptFontBold', TRUE)    Then DefaultFontStyles := DefaultFontStyles + [fsbold];
     If DSS_Registry.ReadBool('ScriptFontItalic', FALSE) Then DefaultFontStyles := DefaultFontStyles + [fsItalic];
  {$ENDIF}
  DefaultBaseFreq  := StrToInt(DSS_Registry.ReadString('BaseFrequency', '60' ));
  LastFileCompiled := DSS_Registry.ReadString('LastFile', '' );
  TestDataDirectory :=   DSS_Registry.ReadString('DataPath', DataDirectory[ActiveActor]);
  If SysUtils.DirectoryExists (TestDataDirectory) Then SetDataPath (TestDataDirectory)
                                        Else SetDataPath (DataDirectory[ActiveActor]);
End;


PROCEDURE WriteDSS_Registry;
Begin
  If UpdateRegistry Then  Begin
      DSS_Registry.Section := 'MainSect';
      DSS_Registry.WriteString('Editor',        DefaultEditor);
      DSS_Registry.WriteString('ScriptFontSize', Format('%d',[DefaultFontSize]));
      DSS_Registry.WriteString('ScriptFontName', Format('%s',[DefaultFontName]));
      DSS_Registry.WriteBool('ScriptFontBold', {$IFDEF FPC}False{$ELSE}(fsBold in DefaultFontStyles){$ENDIF});
      DSS_Registry.WriteBool('ScriptFontItalic', {$IFDEF FPC}False{$ELSE}(fsItalic in DefaultFontStyles){$ENDIF});
      DSS_Registry.WriteString('BaseFrequency', Format('%d',[Round(DefaultBaseFreq)]));
      DSS_Registry.WriteString('LastFile',      LastFileCompiled);
      DSS_Registry.WriteString('DataPath', DataDirectory[ActiveActor]);
  End;
End;
{$ENDIF}

PROCEDURE ResetQueryLogFile;
Begin
     QueryFirstTime := TRUE;
End;


PROCEDURE WriteQueryLogfile(Const Prop, S:String);

{Log file is written after a query command if LogQueries is true.}

Begin

  TRY
        QueryLogFileName :=  OutputDirectory[ActiveActor] + 'QueryLog.CSV';
        AssignFile(QueryLogFile, QueryLogFileName);
        If QueryFirstTime then
        Begin
             Rewrite(QueryLogFile);  // clear the file
             Writeln(QueryLogFile, 'Time(h), Property, Result');
             QueryFirstTime := False;
        end
        Else Append( QueryLogFile);

        Writeln(QueryLogFile,Format('%.10g, %s, %s',[ActiveCircuit[ActiveActor].Solution.DynaVars.dblHour, Prop, S]));
        CloseFile(QueryLogFile);
  EXCEPT
        On E:Exception Do DoSimpleMsg('Error writing Query Log file: ' + E.Message, 908);
  END;

End;

PROCEDURE SetLastResultFile(Const Fname:String);

Begin
      LastResultfile := Fname;
      ParserVars.Add('@lastfile', Fname);
End;

Function MyAllocMem(nbytes:Cardinal):Pointer;
Begin
    Result := AllocMem(Nbytes);
    WriteDLLDebugFile(Format('Allocating %d bytes @ %p',[nbytes, Result]));
End;

Procedure MyReallocMem(Var p:Pointer; newsize:Integer);

Begin
     WriteDLLDebugFile(Format('Reallocating @ %p, new size= %d', [p, newsize]));
     ReallocMem(p, newsize);
End;

// Function to validate the installation and path of the OpenDSS Viewer
function GetIni(s,k: string; d: string; f: string=''): string; overload;
var
  ini: TMemIniFile;
begin
  Result := d;
  if f = '' then
  begin
    ini := TMemIniFile.Create(lowercase(ChangeFileExt(ParamStr(0),'.ini')));
  end
  else
  begin
    if not FileExists(f) then Exit;
    ini := TMemIniFile.Create(f);
  end;
  if ini.ReadString(s,k,'') = '' then
  begin
    ini.WriteString(s,k,d);
    ini.UpdateFile;
  end;
  Result := ini.ReadString(s,k,d);
  FreeAndNil(ini);
end;

// Waits for all the actors running tasks
procedure Wait4Actors(WType : Integer);
var
  i       : Integer;
  Flag    : Boolean;

Begin
// WType defines the starting point in which the actors will be evaluated,
// modification introduced in 01-10-2019 to facilitate the coordination
// between actors when a simulation is performed using A-Diakoptics
  for i := (WType +1) to NumOfActors do
  Begin
    Try
      if ActorStatus[i] = 0 then
      Begin
        Flag  :=  true;
        while Flag do
          Flag  := ActorMA_Msg[i].WaitFor(10) = TWaitResult.wrTimeout;
      End;
    Except
      On EOutOfMemory Do
          Dosimplemsg('Exception Waiting for the parallel thread to finish a job"', 7006);
    End;
  End;
end;

// Clones the active Circuit as many times as requested if possible
procedure DoClone();
var
  i,
  NumClones   : Integer;
  Ref_Ckt     : String;
Begin
    Ref_Ckt             := LastFileCompiled;
    Parser[ActiveActor].NextParam;
    NumClones           := Parser[ActiveActor].IntValue;
    Parallel_enabled    := False;
    if ((NumOfActors + NumClones) <= CPU_Cores) and (NumClones > 0) then
    Begin
      for i := 1 to NumClones do
      Begin
        New_Actor_Slot;
        DSSExecutive[ActiveActor].Command          :=  'compile "' + Ref_Ckt + '"';
        // sets the previous maxiterations and controliterations
        ActiveCircuit[ActiveActor].solution.MaxIterations         :=  ActiveCircuit[1].solution.MaxIterations;
        ActiveCircuit[ActiveACtor].solution.MaxControlIterations  :=  ActiveCircuit[1].solution.MaxControlIterations;
        // Solves the circuit
        CmdResult := ExecOptions.DoSetCmd(1);
      End;

    End
    else
    Begin
      if NumClones > 0 then
        DoSimpleMsg('There are no more CPUs available', 7001)
      else
        DoSimpleMsg('The number of clones requested is invalid', 7004)
    End;
End;

// Prepares memory to host a new actor
procedure New_Actor_Slot();
Begin
  if NumOfActors < CPU_Cores then
  begin
    inc(NumOfActors);
    GlobalResult              :=  inttostr(NumOfActors);
    ActiveActor               :=  NumOfActors;
    ActorCPU[ActiveActor]     :=  ActiveActor -1;
    DSSExecutive[ActiveActor] :=  TExecutive.Create;  // Make a DSS object
    Parser[ActiveActor]       :=  TParser.Create;
    AuxParser[ActiveActor]    :=  TParser.Create;
    DSSExecutive[ActiveActor].CreateDefaultDSSItems;
  end
  else DoSimpleMsg('There are no more CPUs available', 7001)
End;

// Creates a new actor
procedure New_Actor(ActorID:  Integer);
{$IFNDEF DSS_CAPI}
Var
  ScriptEd    : TScriptEdit;
{$ENDIF}
{$IFDEF FPC}
Begin
 ActorHandle[ActorID] :=  TSolver.Create(True,ActorCPU[ActorID],ActorID,nil,ActorMA_Msg[ActorID]); // TEMC: TODO: text-mode callback
 ActorHandle[ActorID].Priority :=  tpTimeCritical;
 ActorHandle[ActorID].Start;
 ActorStatus[ActorID] :=  1;
End;
{$ELSE}
var
 ScriptEd    : TScriptEdit;
Begin
 ActorHandle[ActorID] :=  TSolver.Create(True,ActorCPU[ActorID],ActorID,ScriptEd.UpdateSummaryform,ActorMA_Msg[ActorID]);
 ActorHandle[ActorID].Priority :=  {$IFDEF MSWINDOWS}tpTimeCritical{$ELSE}6{$ENDIF};
 ActorHandle[ActorID].Resume;
 ActorStatus[ActorID] :=  1;
End;
{$ENDIF}

{$IFNDEF FPC}
// Validates the installation and path of the OpenDSS Viewer
function CheckOpenDSSViewer: Boolean;
var FileName: string;
begin
  DSS_Viz_path:=GetIni('Application','path','', TPath.GetHomePath+'\OpenDSS_Viewer\settings.ini');
  // to make it compatible with the function
  FileName  :=  stringreplace(DSS_Viz_path, '\\' ,'\',[rfReplaceAll, rfIgnoreCase]);
  FileName  :=  stringreplace(FileName, '"' ,'',[rfReplaceAll, rfIgnoreCase]);
  // returns true only if the executable exists
  Result:=fileexists(FileName);
end;
{$ENDIF}

procedure Delay(TickTime : Integer);
 var
 Past: longint;
 begin
 Past := GetTickCount64;
 repeat

 Until (GetTickCount64 - Past) >= longint(TickTime);
end;



initialization

//***************Initialization for Parallel Processing*************************
{$IFDEF WINDOWS}
   CPU_Cores        :=  CPUCount;
{$ELSE}
   CPU_Cores        :=  GetLogicalCpuCount; // FreePascal's CPUCount returns 1 on Linux
{$ENDIF}
   setlength(ActiveCircuit,CPU_Cores + 1);
   {$IFNDEF FPC}setlength(ActorProgress,CPU_Cores + 1);{$ENDIF}
   setlength(ActorCPU,CPU_Cores + 1);
   setlength(ActorProgressCount,CPU_Cores + 1);
   setlength(ActiveDSSClass,CPU_Cores + 1);
   setlength(DataDirectory,CPU_Cores + 1);
   setlength(OutputDirectory,CPU_Cores + 1);
   setlength(CircuitName_,CPU_Cores + 1);
   setlength(ActorPctProgress,CPU_Cores + 1);
   setlength(ActiveDSSObject,CPU_Cores + 1);
   setlength(LastClassReferenced,CPU_Cores + 1);
   setlength(DSSObjs,CPU_Cores + 1);
   setlength(ActiveEarthModel,CPU_Cores + 1);
   setlength(DSSClassList,CPU_Cores + 1);
   setlength(ClassNames,CPU_Cores + 1);
   setlength(MonitorClass,CPU_Cores + 1);
   setlength(LoadShapeClass,CPU_Cores + 1);
   setlength(TShapeClass,CPU_Cores + 1);
   setlength(PriceShapeClass,CPU_Cores + 1);
   setlength(XYCurveClass,CPU_Cores + 1);
   setlength(GrowthShapeClass,CPU_Cores + 1);
   setlength(SpectrumClass,CPU_Cores + 1);
   setlength(SolutionClass,CPU_Cores + 1);
   setlength(EnergyMeterClass,CPU_Cores + 1);
   setlength(SensorClass,CPU_Cores + 1);
   setlength(TCC_CurveClass,CPU_Cores + 1);
   setlength(WireDataClass,CPU_Cores + 1);
   setlength(CNDataClass,CPU_Cores + 1);
   setlength(TSDataClass,CPU_Cores + 1);
   setlength(LineSpacingClass,CPU_Cores + 1);
   setlength(StorageClass,CPU_Cores + 1);
   setlength(PVSystemClass,CPU_Cores + 1);
   setlength(InvControlClass,CPU_Cores + 1);
   setlength(ExpControlClass,CPU_Cores + 1);
   setlength(EventStrings,CPU_Cores + 1);
   setlength(SavedFileList,CPU_Cores + 1);
   setlength(ErrorStrings,CPU_Cores + 1);
   setlength(ActorHandle,CPU_Cores + 1);
   setlength(Parser,CPU_Cores + 1);
   setlength(AuxParser,CPU_Cores + 1);
   setlength(ActiveYPrim,CPU_Cores + 1);
   SetLength(SolutionWasAttempted,CPU_Cores + 1);
   SetLength(ActorStatus,CPU_Cores + 1);
   SetLength(ActorMA_Msg,CPU_Cores + 1);

   setlength(LineClass,CPU_Cores + 1);
   setlength(VSourceClass,CPU_Cores + 1);
   setlength(ISourceClass,CPU_Cores + 1);
   setlength(VCSSClass,CPU_Cores + 1);
   setlength(LoadClass,CPU_Cores + 1);
   setlength(TransformerClass,CPU_Cores + 1);
   setlength(RegControlClass,CPU_Cores + 1);
   setlength(CapacitorClass,CPU_Cores + 1);
   setlength(ReactorClass,CPU_Cores + 1);
   setlength(CapControlClass,CPU_Cores + 1);
   setlength(FaultClass,CPU_Cores + 1);
   setlength(GeneratorClass,CPU_Cores + 1);
   setlength(GenDispatcherClass,CPU_Cores + 1);
   setlength(StorageControllerClass,CPU_Cores + 1);
   setlength(RelayClass,CPU_Cores + 1);
   setlength(RecloserClass,CPU_Cores + 1);
   setlength(FuseClass,CPU_Cores + 1);
   setlength(SwtControlClass,CPU_Cores + 1);
   setlength(UPFCClass,CPU_Cores + 1);
   setlength(UPFCControlClass,CPU_Cores + 1);
   setlength(ESPVLControlClass,CPU_Cores + 1);
   setlength(IndMach012Class,CPU_Cores + 1);
   setlength(GICsourceClass,CPU_Cores + 1);
   setlength(AutoTransClass,CPU_Cores + 1);
   setlength(VSConverterClass,CPU_Cores + 1);
   
   SetLength(ActiveVSource,CPU_Cores + 1);
   
   setlength(LineCodeClass,CPU_Cores + 1);
   setlength(LineGeometryClass,CPU_Cores + 1);
   setlength(XfmrCodeClass,CPU_Cores + 1);
   setlength(GICLineClass,CPU_Cores + 1);
   setlength(GICTransformerClass,CPU_Cores + 1);

   // Init pointer repositories for the EnergyMeter in multiple cores

   SetLength(OV_MHandle,CPU_Cores + 1);
   SetLength(VR_MHandle,CPU_Cores + 1);
   SetLength(SDI_MHandle,CPU_Cores + 1);
   SetLength(TDI_MHandle,CPU_Cores + 1);
   SetLength(SM_MHandle,CPU_Cores + 1);
   SetLength(EMT_MHandle,CPU_Cores + 1);
   SetLength(FM_MHandle,CPU_Cores + 1);
   SetLength(OV_Append,CPU_Cores + 1);
   SetLength(VR_Append,CPU_Cores + 1);
   SetLength(DI_Append,CPU_Cores + 1);
   SetLength(SDI_Append,CPU_Cores + 1);
   SetLength(TDI_Append,CPU_Cores + 1);
   SetLength(SM_Append,CPU_Cores + 1);
   SetLength(EMT_Append,CPU_Cores + 1);
   SetLength(PHV_Append,CPU_Cores + 1);
   SetLength(FM_Append,CPU_Cores + 1);
   SetLength(DIFilesAreOpen,CPU_Cores + 1);
   SetLength(DSSExecutive,CPU_Cores + 1);


   for ActiveActor := 1 to CPU_Cores do
   begin
    ActiveCircuit[ActiveActor]        :=  nil;
    {$IFNDEF FPC}ActorProgress[ActiveActor]        :=  nil; {$ENDIF}
    ActiveDSSClass[ActiveActor]       :=  nil;
    EventStrings[ActiveActor]         := TStringList.Create;
    SavedFileList[ActiveActor]        := TStringList.Create;
    ErrorStrings[ActiveActor]         := TStringList.Create;
    ErrorStrings[ActiveActor].Clear;
    ActorHandle[ActiveActor]          :=  nil;
    Parser[ActiveActor]               :=  nil;
    ActorStatus[ActiveActor]          :=  1;

    OV_MHandle[ActiveActor]           :=  nil;
    VR_MHandle[ActiveActor]           :=  nil;
    SDI_MHandle[ActiveActor]          :=  nil;
    TDI_MHandle[ActiveActor]          :=  nil;
    SM_MHandle[ActiveActor]           :=  nil;
    EMT_MHandle[ActiveActor]          :=  nil;
    FM_MHandle[ActiveActor]           :=  nil;
    DIFilesAreOpen[ActiveActor]       :=  FALSE;

    ActiveVSource[Activeactor]        :=  nil;
    DSSObjs[ActiveActor]              :=  nil;
    DSSClassList[ActiveActor]         :=  nil;
   end;

   DSSClasses             :=  nil;
   ProgressCmd            :=  False;

   Allactors              :=  False;
   ActiveActor            :=  1;
   NumOfActors            :=  1;
   ActorCPU[ActiveActor]  :=  0;
   Parser[ActiveActor]    :=  Tparser.Create;

//   ActiveActor            :=  0;
//   NumOfActors            :=  0;
//   New_Actor_Slot();

   {$IFDEF FPC}
   ProgramName      := 'OpenDSSCmd';  // for now...
   {$ELSE}
   ProgramName            :=  'OpenDSS';
   {$ENDIF}
   DSSFileName            :=  GetDSSExeFile;
   DSSDirectory           :=  ExtractFilePath(DSSFileName);
   ADiakoptics            :=  False;  // Disabled by default

   SeasonalRating         :=  False;
   SeasonSignal           :=  '';

   {Various Constants and Switches}
   {$IFDEF FPC}NoFormsAllowed  := TRUE;{$ENDIF}

   CALPHA                := Cmplx(-0.5, -0.866025); // -120 degrees phase shift
   SQRT2                 := Sqrt(2.0);
   SQRT3                 := Sqrt(3.0);
   InvSQRT3              := 1.0/SQRT3;
   InvSQRT3x1000         := InvSQRT3 * 1000.0;
   CmdResult             := 0;
   //DIFilesAreOpen        := FALSE;
   ErrorNumber           := 0;
   ErrorPending          := FALSE;
   GlobalHelpString      := '';
   GlobalPropertyValue   := '';
   LastResultFile        := '';
   In_Redirect           := FALSE;
   InShowResults         := FALSE;
   IsDLL                 := FALSE;
   LastCommandWasCompile := FALSE;
   LastErrorMessage      := '';
   MaxCircuits           := 1;  //  Not required anymore. planning to remove it
   MaxAllocationIterations := 2;
   SolutionAbort         := FALSE;
   AutoShowExport        := FALSE;
   SolutionWasAttempted[ActiveActor]  := FALSE;

   DefaultBaseFreq       := 60.0;
   DaisySize             := 1.0;
   DefaultEarthModel     := DERI;
   ActiveEarthModel[ActiveActor]      := DefaultEarthModel;
   Parallel_enabled      :=  False;
   ConcatenateReports    :=  False;


   {Initialize filenames and directories}


   // want to know if this was built for 64-bit, not whether running on 64 bits
   // (i.e. we could have a 32-bit build running on 64 bits; not interested in that
{$IFDEF DSS_CAPI}
{$IFDEF CPUX64}
   VersionString    := GetDSSVersion + ' (64-bit build)';
{$ELSE ! CPUX86}
   VersionString    := GetDSSVersion + ' (32-bit build)';
{$ENDIF}
{$ELSE}
{$IFDEF CPUX64}
   VersionString    := 'Version ' + GetDSSVersion + ' (64-bit build)';
{$ELSE ! CPUX86}
   VersionString    := 'Version ' + GetDSSVersion + ' (32-bit build)';
{$ENDIF}
{$ENDIF}

   StartupDirectory := GetCurrentDir + PathDelim;
{$IFNDEF DSS_CAPI}
   SetDataPath (GetDefaultDataDirectory + PathDelim + ProgramName + PathDelim);
{$ELSE} // Use the current working directory as the initial datapath when using DSS_CAPI
   SetDataPath (StartupDirectory);
{$ENDIF}

{$IFNDEF DSS_CAPI}
{$IFNDEF FPC}
   DSS_Registry     := TIniRegSave.Create('\Software\' + ProgramName);
{$ELSE}
        DSS_Registry     := TIniRegSave.Create(DataDirectory[ActiveActor] + 'opendsscmd.ini');
{$ENDIF}
{$ELSE}
   IF GetEnvironmentVariable('DSS_BASE_FREQUENCY') <> '' THEN
   BEGIN
      DefaultBaseFreq  := StrToInt(GetEnvironmentVariable('DSS_BASE_FREQUENCY'));
   END;
{$ENDIF}

   AuxParser[ActiveActor]        := TParser.Create;

   {$IFDEF Darwin}
      DefaultEditor := GetEnvironmentVariable('EDITOR');

      // If there is no EDITOR environment variable, keep the old behavior
      if (DefaultEditor = '') then
      DefaultEditor   := 'open -t';
      DefaultFontSize := 12;
      DefaultFontName := 'Geneva';
   {$ENDIF}
   {$IFDEF Linux}
      DefaultEditor := GetEnvironmentVariable('EDITOR');

      // If there is no EDITOR environment variable, keep the old behavior
      if (DefaultEditor = '') then
      DefaultEditor   := 'xdg-open';
      DefaultFontSize := 10;
      DefaultFontName := 'Arial';
   {$ENDIF}
   {$IF (defined(Windows) or defined(MSWindows))}
      DefaultEditor   := 'NotePad.exe';
      DefaultFontSize := 8;
      DefaultFontName := 'MS Sans Serif';
   {$ENDIF}

   {$IFNDEF FPC}NoFormsAllowed   := FALSE;{$ENDIF}

   LogQueries       := FALSE;
   QueryLogFileName := '';
   UpdateRegistry   := TRUE;
   {$IFNDEF MSWINDOWS}
   CPU_Freq := 1000; // until we can query it
   //clock_gettime
   {$ELSE}
   QueryPerformanceFrequency(CPU_Freq);
   {$ENDIF}

   IsMultithread    :=  True;
   //WriteDLLDebugFile('DSSGlobals');

{$IFNDEF FPC}
  DSS_Viz_installed:= CheckOpenDSSViewer; // OpenDSS Viewer (flag for detected installation)
{$ENDIF}
{$IFDEF DSS_CAPI}
   DSS_CAPI_INFO_SPARSE_COND := (GetEnvironmentVariable('DSS_CAPI_INFO_SPARSE_COND') = '1');

   // Default is True, disable at initialization only when DSS_CAPI_EARLY_ABORT = 0
   DSS_CAPI_EARLY_ABORT := (GetEnvironmentVariable('DSS_CAPI_EARLY_ABORT') <> '0');

   // Default is False, enable at initialization when DSS_CAPI_ALLOW_EDITOR = 1
   DSS_CAPI_ALLOW_EDITOR := (GetEnvironmentVariable('DSS_CAPI_ALLOW_EDITOR') = '1');
{$ENDIF}

Finalization

  // Dosimplemsg('Enter DSSGlobals Unit Finalization.');
//  YBMatrix.Finish_Ymatrix_Critical;   // Ends the critical segment for the YMatrix class




  ClearAllCircuits;

  for ActiveActor := 1 to NumOfActors do
  Begin
    if ActorHandle[ActiveActor] <> nil then
    Begin
      With DSSExecutive[ActiveActor] Do If RecorderOn Then Recorderon := FALSE;
{$IFNDEF DSS_CAPI}
      DSSExecutive[ActiveActor].Free;  {Writes to Registry}
      DSS_Registry.Free;  {Close Registry}
{$ENDIF}

      EventStrings[ActiveActor].Free;
      SavedFileList[ActiveActor].Free;
      ErrorStrings[ActiveActor].Free;
      ActorHandle[ActiveActor].Free;
      Auxparser[ActiveActor].Free;
    End;
  End;
End.



