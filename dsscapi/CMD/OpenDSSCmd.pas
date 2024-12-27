program OpenDSSCmd;

{
  Copyright (c) 2008-2014, Electric Power Research Institute, Inc.
  Copyright (c) 2016 Battelle Memorial Institute
  Copyright (c) 2020 Richard Lincoln
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification,
  are permitted provided that the following conditions are met:
      *	Redistributions of source code must retain the above copyright notice,
        this list of conditions and the following disclaimer.
      *	Redistributions in binary form must reproduce the above copyright notice,
        this list of conditions and the following disclaimer in the documentation
        and/or other materials provided with the distribution.
      *	Neither the name of the Electric Power Research Institute, Inc.,
        nor the names of its contributors may be used to endorse or promote products
        derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY Electric Power Research Institute, Inc., "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  ARE DISCLAIMED. IN NO EVENT SHALL Electric Power Research Institute, Inc.,
  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE.
}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  SysUtils,
	Classes,
	CustApp,

  CmdForms in 'CmdForms.pas',
  MyDSSClassDefs in 'MyDSSClassDefs.Pas',

  AutoAdd in '..\Common\AutoAdd.pas',
  Bus in '..\Common\Bus.pas',
  Circuit in '..\Common\Circuit.pas',
  CktElement in '..\Common\CktElement.pas',
  CktElementClass in '..\Common\CktElementClass.pas',
  Conductor in '..\Common\Conductor.pas',
  ControlQueue in '..\Common\ControlQueue.pas',
  Diakoptics in '..\Common\Diakoptics.pas',
  DSSCallBackRoutines in '..\Common\DSSCallBackRoutines.pas',
  DSSClass in '..\Common\DSSClass.pas',
  DSSClassDefs in '..\Common\DSSClassDefs.pas',
  DSSGlobals in '..\Common\DSSGlobals.pas',
  EventQueue in '..\Common\EventQueue.pas',
  ExportCIMXML in '..\Common\ExportCIMXML.pas',
  ExportResults in '..\Common\ExportResults.pas',
  ExportCSV in '..\Common\ExportCSV.pas',
  Feeder in '..\Common\Feeder.pas',
  KLUSolve in '..\Common\KLUSolve.pas',
  Notes in '..\Common\Notes.pas',
  ShowResults in '..\Common\ShowResults.pas',
  Solution in '..\Common\Solution.pas',
  SolutionAlgs in '..\Common\SolutionAlgs.pas',
  Sparse_Math in '..\Common\Sparse_Math.pas',
  Terminal in '..\Common\Terminal.pas',
  TOPExport in '..\Common\TOPExport.pas',
  Utilities in '..\Common\Utilities.pas',
  Ymatrix in '..\Common\Ymatrix.pas',

  ExecCommands in '..\Executive\ExecCommands.pas',
  ExecHelper in '..\Executive\ExecHelper.pas',
  ExecOptions in '..\Executive\ExecOptions.pas',
  Executive in '..\Executive\Executive.pas',
  ExportOptions in '..\Executive\ExportOptions.pas',
  ShowOptions in '..\Executive\ShowOptions.pas',

  Arraydef in '..\Shared\Arraydef.pas',
  CktTree in '..\Shared\CktTree.pas',
  Command in '..\Shared\Command.pas',
  Dynamics in '..\Shared\Dynamics.pas',
  IniRegSave in '..\Shared\IniRegSave.pas',
  HashList in '..\Shared\HashList.pas',
  LineUnits in '..\Shared\LineUnits.pas',
  mathutil in '..\Shared\mathutil.pas',
  PointerList in '..\Shared\PointerList.pas',
  Pstcalc in '..\Shared\Pstcalc.pas',
  StackDef in '..\Shared\StackDef.pas',
  Ucmatrix in '..\Shared\Ucmatrix.pas',
  Ucomplex in '..\Shared\Ucomplex.pas',

  cpucount in '..\Parallel_Lib\cpucount.pas',
  Parallel_Lib in '..\Parallel_Lib\Parallel_Lib.pas',

  ParserDel in '..\Parser\ParserDel.pas',
  RPN in '..\Parser\RPN.pas',

  CapControl in '..\Controls\CapControl.pas',
  CapControlVars in '..\Controls\CapControlVars.pas',
  CapUserControl in '..\Controls\CapUserControl.pas',
  ControlClass in '..\Controls\ControlClass.pas',
  ControlElem in '..\Controls\ControlElem.pas',
  ExpControl in '..\Controls\ExpControl.pas',
  UPFCControl in '..\Controls\UPFCControl.pas',
  GenDispatcher in '..\Controls\GenDispatcher.pas',
  InvControl in '..\Controls\InvControl.pas',
  Recloser in '..\Controls\Recloser.pas',
  RegControl in '..\Controls\RegControl.pas',
  Relay in '..\Controls\Relay.pas',
  StorageController in '..\Controls\StorageController.pas',
  SwtControl in '..\Controls\SwtControl.pas',
  ESPVLControl in '..\Controls\ESPVLControl.pas',

  CableConstants in '..\General\CableConstants.pas',
  CableData in '..\General\CableData.pas',
  CNData in '..\General\CNData.pas',
  CNLineConstants in '..\General\CNLineConstants.pas',
  ConductorData in '..\General\ConductorData.pas',
  DSSObject in '..\General\DSSObject.pas',
  GrowthShape in '..\General\GrowthShape.pas',
  LineCode in '..\General\LineCode.pas',
  LineConstants in '..\General\LineConstants.pas',
  LineGeometry in '..\General\LineGeometry.pas',
  LineSpacing in '..\General\LineSpacing.pas',
  LoadShape in '..\General\LoadShape.pas',
  NamedObject in '..\General\NamedObject.pas',
  OHLineConstants in '..\General\OHLineConstants.pas',
  PriceShape in '..\General\PriceShape.pas',
  Spectrum in '..\General\Spectrum.pas',
  TCC_Curve in '..\General\TCC_Curve.pas',
  TempShape in '..\General\TempShape.pas',
  TSData in '..\General\TSData.pas',
  TSLineConstants in '..\General\TSLineConstants.pas',
  WireData in '..\General\WireData.pas',
  XfmrCode in '..\General\XfmrCode.pas',
  XYcurve in '..\General\XYcurve.pas',

  EnergyMeter in '..\Meters\EnergyMeter.pas',
  MeterClass in '..\Meters\MeterClass.pas',
  MeterElement in '..\Meters\MeterElement.pas',
  Monitor in '..\Meters\Monitor.pas',
  ReduceAlgs in '..\Meters\ReduceAlgs.pas',
  Sensor in '..\Meters\Sensor.pas',
  MemoryMap_lib in '..\Meters\MemoryMap_lib.pas',
  LD_fm_infos in '..\Meters\LD_fm_infos.pas',
  VLNodeVars in '..\Meters\VLNodeVars.pas',

  Equivalent in '..\PCElements\Equivalent.pas',
  Generator in '..\PCElements\generator.pas',
  GeneratorVars in '..\PCElements\GeneratorVars.pas',
  GenUserModel in '..\PCElements\GenUserModel.pas',
  GICLine in '..\PCElements\GICLine.pas',
  Isource in '..\PCElements\Isource.pas',
  Load in '..\PCElements\Load.pas',
  PCClass in '..\PCElements\PCClass.pas',
  PCElement in '..\PCElements\PCElement.pas',
  PVsystem in '..\PCElements\PVsystem.pas',
  PVSystemUserModel in '..\PCElements\PVSystemUserModel.pas',
  Storage in '..\PCElements\Storage.pas',
  StorageVars in '..\PCElements\StorageVars.pas',
  StoreUserModel in '..\PCElements\StoreUserModel.pas',
  UPFC in '..\PCElements\UPFC.pas',
  VCCS in '..\PCElements\vccs.pas',
  VSConverter in '..\PCElements\VSConverter.pas',
  VSource in '..\PCElements\VSource.pas',
  GICsource in '..\PCElements\GICsource.pas',
  IndMach012 in '..\PCElements\IndMach012.pas',

  Capacitor in '..\PDElements\Capacitor.pas',
  Fault in '..\PDElements\Fault.pas',
  Fuse in '..\PDElements\fuse.pas',
  GICTransformer in '..\PDElements\GICTransformer.pas',
  Line in '..\PDElements\Line.pas',
  PDClass in '..\PDElements\PDClass.pas',
  PDElement in '..\PDElements\PDElement.pas',
  Reactor in '..\PDElements\Reactor.pas',
  Transformer in '..\PDElements\Transformer.pas',
  AutoTrans in '..\PDElements\AutoTrans.pas';


function UserFinished(Cmd:String):boolean;
Begin
	result := false;
	cmd := LowerCase (Cmd);
	if cmd='' then 
		result := true
	else if cmd='exit' then 
		result := true
	else if cmd[1]='q' then
		result := true;
End;

type
  TCmdApplication = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

procedure TCmdApplication.DoRun;
var
  ErrorMsg, Cmd: String;
begin
	NoFormsAllowed := True;
	ActiveActor               :=  1;
	DSSExecutive[ActiveActor] := TExecutive.Create;  // Make a DSS object
	DSSExecutive[ActiveActor].CreateDefaultDSSItems;
	DataDirectory[ActiveActor] := StartupDirectory;
	OutputDirectory[ActiveActor] := StartupDirectory;

	NoFormsAllowed := False;  // messages will go to the console

	// quick check parameters
  ErrorMsg:=CheckOptions('h', 'help');
  if ErrorMsg<>'' then begin
    ShowException(Exception.Create(ErrorMsg));
    Terminate;
    Exit;
  end;

  // parse parameters
  if HasOption('h', 'help') then begin
    WriteHelp;
    Terminate;
    Exit;
  end;

	if paramcount > 0 then begin
		Cmd := 'compile ' + ParamStr(1);
		writeln(Cmd);
		DSSExecutive[ActiveActor].Command := Cmd;
		if DSSExecutive[ActiveActor].LastError <> '' then begin
				writeln(stderr, DSSExecutive[ActiveActor].LastError);
		end;
		Terminate;
	end else begin
		repeat begin
			write('>> ');
			readln(Cmd);
			DSSExecutive[ActiveActor].Command := Cmd;
			if DSSExecutive[ActiveActor].LastError <> '' then begin
				writeln(stderr, DSSExecutive[ActiveActor].LastError);
			end;
		end until UserFinished (Cmd);
	end;

  // stop program loop
  Terminate;
end;

constructor TCmdApplication.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
end;

destructor TCmdApplication.Destroy;
begin
  inherited Destroy;
end;

procedure TCmdApplication.WriteHelp;
begin
  { add your help code here }
  writeln('Usage: ', ExeName, ' -h');
end;

var
  Application: TCmdApplication;

begin
  Application:=TCmdApplication.Create(nil);
  Application.Title:='OpenDSSCmd';
  Application.Run;
	ExitCode := DSSExecutive[ActiveActor].Error;
  Application.Free;
end.
