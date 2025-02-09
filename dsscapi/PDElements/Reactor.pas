unit Reactor;

{
  ----------------------------------------------------------
  Copyright (c) 2008-2015, Electric Power Research Institute, Inc.
  All rights reserved.
  ----------------------------------------------------------
}

{   10-26-00  Created from Capacitor  object
    3-2-06 Added Parallel Option and corrected frequency adjustments
           RMATRIX, Xmatrix untested
    2013   Added Symmetrical component specification and frequency-dependence for simplr
           R+jX model


Basic  Reactor

  Uses same rules as Capacitor and Fault for connections

  Implemented as a two-terminal constant impedance (Power Delivery Element)
  Defaults to a Shunt Reactor but can be connected as a two-terminal series reactor

  If Parallel=Yes, then the R and X components are treated as being in parallel

  Bus2 connection defaults to 0 node of Bus1 (if Bus2 has the default bus connection
  at the time Bus1 is defined.  Therefore, if only Bus1 is specified, a shunt Reactor results.
  If delta connected, Bus2 is set to node zero of Bus1 and nothing is returned in the lower
  half of YPrim - all zeroes.

  If an ungrounded wye is desired, explicitly set Bus2= and set all nodes the same,
    e.g. Bus1.4.4.4   (uses 4th node of Bus1 as neutral point)
        or BusNew.1.1.1  (makes a new bus for the neutral point)
  You must specify the nodes or you will get a series Reactor!

  A series Reactor is specified simply by setting bus2 and declaring the connection
  to be Wye.  If the connection is specified as delta, nothing will be connected to Bus2.
  In fact the number of terminals is set to 1.

  Reactance may be specified as:

     1.  kvar and kv ratings at base frequency.  impedance.  Specify kvar as total for
         all phases. For 1-phase, kV = Reactor coil kV rating.
         For 2 or 3-phase, kV is line-line three phase. For more than 3 phases, specify
         kV as actual coil voltage.
     2.  Series Resistance, R, and Reactance, X, in ohns at base frequency to be used in each phase.  If specified in this manner,
         the given value is always used whether wye or delta.  X may be specified as Inductance, LmH, in mH.
         The Z property may also be used to specify R and X in an array.
     3.  A R and X  matrices .
         If conn=wye then 2-terminal through device
         If conn=delta then 1-terminal.
         Ohms at base frequency
         Note that Rmatix may be in parallel with Xmatric (set parallel = Yes)
     4.  As symmetrical component values using Z1, Z2, and Z0 complex array properties.
         Z2 defaults to Z1, but can be set to a different value.

}
interface

uses
    Command,
    DSSClass,
    PDClass,
    PDElement,
    uComplex,
    UcMatrix,
    ArrayDef,
    XYCurve;

type

    TReactor = class(TPDClass)
    PRIVATE
        procedure Domatrix(var Matrix: pDoubleArray; ActorID: Integer);

        procedure InterpretConnection(const S: String);
        procedure ReactorSetbus1(const s: String);
    PROTECTED
        function MakeLike(const ReactorName: String): Integer; OVERRIDE;
        procedure DefineProperties;  // Add Properties of this class to propName
    PUBLIC
        constructor Create;
        destructor Destroy; OVERRIDE;

        function Edit(ActorID: Integer): Integer; OVERRIDE;     // uses global parser
        function Init(Handle: Integer; ActorID: Integer): Integer; OVERRIDE;
        function NewObject(const ObjName: String): Integer; OVERRIDE;
    end;

    TReactorObj = class(TPDElement)
{$IFDEF DSS_CAPI}
    PUBLIC
{$ELSE}
    PRIVATE
{$ENDIF}
        R, Rp, Gp,
        X, L,
        kvarrating,
        kvrating: Double;
        Z, Z1, Z2, Z0: Complex;
        Rmatrix, Gmatrix,
        XMatrix, Bmatrix: pDoubleArray;  // If not nil then overrides C

        Connection: Integer;   // 0 or 1 for wye (default) or delta, respectively
        SpecType: Integer;   // 1=kvar, 2=R+jX, 3=R and X matrices, 4=sym components

        IsParallel: Boolean;
        RpSpecified: Boolean;
        Bus2Defined: Boolean;
        Z2Specified: Boolean;
        Z0Specified: Boolean;


    PUBLIC

        RCurve: String;
        RCurveObj: TXYCurveObj;
        LCurve: String;
        LCurveObj: TXYCurveObj;


        constructor Create(ParClass: TDSSClass; const ReactorName: String);
        destructor Destroy; OVERRIDE;

        procedure GetLosses(var TotalLosses, LoadLosses, NoLoadLosses: Complex; ActorID: Integer); OVERRIDE;

        procedure MakePosSequence(ActorID: Integer); OVERRIDE;  // Make a positive Sequence Model

        procedure RecalcElementData(ActorID: Integer); OVERRIDE;
        procedure CalcYPrim(ActorID: Integer); OVERRIDE;
        function GetPropertyValue(Index: Integer): String; OVERRIDE;
        procedure InitPropertyValues(ArrayOffset: Integer); OVERRIDE;
        procedure DumpProperties(var F: TextFile; Complete: Boolean); OVERRIDE;
        procedure DumpPropertiesCSV(var F: TextFile); OVERRIDE;

                // CIM XML access - this is only tested for the IEEE 8500-node feeder
        property SimpleR: Double READ R;
        property SimpleX: Double READ X;
    end;

var
    ActiveReactorObj: TReactorObj;

implementation

uses
    ParserDel,
    DSSClassDefs,
    DSSGlobals,
    Sysutils,
    Mathutil,
    Utilities;

const
    NumPropsThisClass = 19;

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
constructor TReactor.Create;  // Creates superstructure for all Reactor objects
begin
    inherited Create;
    Class_Name := 'Reactor';
    DSSClassType := DSSClassType + REACTOR_ELEMENT;

    ActiveElement := 0;

    DefineProperties;

    CommandList := TCommandList.Create(Slice(PropertyName^, NumProperties));
    CommandList.Abbrev := TRUE;
end;

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
destructor TReactor.Destroy;

begin
    // ElementList and  CommandList freed in inherited destroy
    inherited Destroy;
end;

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
procedure TReactor.DefineProperties;
begin

    Numproperties := NumPropsThisClass;
    CountProperties;   // Get inherited property count
    AllocatePropertyArrays;


     // Define Property names
    PropertyName^[1] := 'bus1';
    PropertyName^[2] := 'bus2';
    PropertyName^[3] := 'phases';
    PropertyName^[4] := 'kvar';
    PropertyName^[5] := 'kv';
    PropertyName^[6] := 'conn';
    PropertyName^[7] := 'Rmatrix';
    PropertyName^[8] := 'Xmatrix';
    PropertyName^[9] := 'Parallel';
    PropertyName^[10] := 'R';
    PropertyName^[11] := 'X';
    PropertyName^[12] := 'Rp';
    PropertyName^[13] := 'Z1';
    PropertyName^[14] := 'Z2';
    PropertyName^[15] := 'Z0';
    PropertyName^[16] := 'Z';
    PropertyName^[17] := 'RCurve';
    PropertyName^[18] := 'LCurve';
    PropertyName^[19] := 'LmH';

     // define Property help values

    PropertyHelp^[1] := 'Name of first bus. Examples:' + CRLF +
        'bus1=busname' + CRLF +
        'bus1=busname.1.2.3' + CRLF + CRLF +
        'Bus2 property will default to this bus, node 0, unless previously specified. ' +
        'Only Bus1 need be specified for a Yg shunt reactor.';
    PropertyHelp^[2] := 'Name of 2nd bus. Defaults to all phases connected ' +
        'to first bus, node 0, (Shunt Wye Connection) ' +
        'except when Bus2 is specifically defined.' + CRLF + CRLF +
        'Not necessary to specify for delta (LL) connection';
    PropertyHelp^[3] := 'Number of phases.';
    PropertyHelp^[4] := 'Total kvar, all phases.  Evenly divided among phases. Only determines X. Specify R separately';
    PropertyHelp^[5] := 'For 2, 3-phase, kV phase-phase. Otherwise specify actual coil rating.';
    PropertyHelp^[6] := '={wye | delta |LN |LL}  Default is wye, which is equivalent to LN. If Delta, then only one terminal.';
    PropertyHelp^[7] := 'Resistance matrix, lower triangle, ohms at base frequency. Order of the matrix is the number of phases. ' +
        'Mutually exclusive to specifying parameters by kvar or X.';
    PropertyHelp^[8] := 'Reactance matrix, lower triangle, ohms at base frequency. Order of the matrix is the number of phases. ' +
        'Mutually exclusive to specifying parameters by kvar or X.';
    PropertyHelp^[9] := '{Yes | No}  Default=No. Indicates whether Rmatrix and Xmatrix are to be considered in parallel. ' +
        'Default is series. For other models, specify R and Rp.';
    PropertyHelp^[10] := 'Resistance (in series with reactance), each phase, ohms. ' +
        'This property applies to REACTOR specified by either kvar or X. See also help on Z.';
    PropertyHelp^[11] := 'Reactance, each phase, ohms at base frequency. See also help on Z and LmH properties.';
    PropertyHelp^[12] := 'Resistance in parallel with R and X (the entire branch). Assumed infinite if not specified.';
    PropertyHelp^[13] := 'Positive-sequence impedance, ohms, as a 2-element array representing a complex number. Example: ' + CRLF + CRLF +
        'Z1=[1, 2]  ! represents 1 + j2 ' + CRLF + CRLF +
        'If defined, Z1, Z2, and Z0 are used to define the impedance matrix of the REACTOR. ' +
        'Z1 MUST BE DEFINED TO USE THIS OPTION FOR DEFINING THE MATRIX.' + CRLF + CRLF +
        'Side Effect: Sets Z2 and Z0 to same values unless they were previously defined.';
    PropertyHelp^[14] := 'Negative-sequence impedance, ohms, as a 2-element array representing a complex number. Example: ' + CRLF + CRLF +
        'Z2=[1, 2]  ! represents 1 + j2 ' + CRLF + CRLF +
        'Used to define the impedance matrix of the REACTOR if Z1 is also specified. ' + CRLF + CRLF +
        'Note: Z2 defaults to Z1 if it is not specifically defined. If Z2 is not equal to Z1, the impedance matrix is asymmetrical.';
    PropertyHelp^[15] := 'Zer0-sequence impedance, ohms, as a 2-element array representing a complex number. Example: ' + CRLF + CRLF +
        'Z0=[3, 4]  ! represents 3 + j4 ' + CRLF + CRLF +
        'Used to define the impedance matrix of the REACTOR if Z1 is also specified. ' + CRLF + CRLF +
        'Note: Z0 defaults to Z1 if it is not specifically defined. ';
    PropertyHelp^[16] := 'Alternative way of defining R and X properties. Enter a 2-element array representing R +jX in ohms. Example:' + CRLF + CRLF +
        'Z=[5  10]   ! equivalent to R=5  X=10 ';
    PropertyHelp^[17] := 'Name of XYCurve object, previously defined, describing per-unit variation of phase resistance, R, vs. frequency. Applies to resistance specified by R or Z property. ' +
        'If actual values are not known, R often increases by approximately the square root of frequency.';
    PropertyHelp^[18] := 'Name of XYCurve object, previously defined, describing per-unit variation of phase inductance, L=X/w, vs. frequency. Applies to reactance specified by X, LmH, Z, or kvar property.' +
        'L generally decreases somewhat with frequency above the base frequency, approaching a limit at a few kHz.';
    PropertyHelp^[19] := 'Inductance, mH. Alternate way to define the reactance, X, property.';


    ActiveProperty := NumPropsThisClass;
    inherited DefineProperties;  // Add defs of inherited properties to bottom of list

end;


//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function TReactor.NewObject(const ObjName: String): Integer;
begin
   // create a new object of this class and add to list
    with ActiveCircuit[ActiveActor] do
    begin
        ActiveCktElement := TReactorObj.Create(Self, ObjName);
        Result := AddObjectToList(ActiveDSSObject[ActiveActor]);
    end;
end;


//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
procedure TReactor.Domatrix(var Matrix: pDoubleArray; ActorID: Integer);
var
    OrderFound, j: Integer;
    MatBuffer: pDoubleArray;

begin
    with ActiveReactorObj do
    begin
        MatBuffer := Allocmem(Sizeof(Double) * Fnphases * Fnphases);
        OrderFound := Parser[ActorID].ParseAsSymMatrix(Fnphases, MatBuffer);

        if OrderFound > 0 then    // Parse was successful Else don't change Matrix
        begin    {X}
            Reallocmem(Matrix, Sizeof(Matrix^[1]) * Fnphases * Fnphases);
            for j := 1 to Fnphases * Fnphases do
                Matrix^[j] := MatBuffer^[j];
        end;

        ReallocMem(MatBuffer, 0);
    end;
end;

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
procedure TReactor.InterpretConnection(const S: String);

// Accepts
//    delta or LL           (Case insensitive)
//    Y, wye, or LN
var
    TestS: String;

begin
    with ActiveReactorObj do
    begin
        TestS := lowercase(S);
        case TestS[1] of
            'y', 'w':
                Connection := 0;  {Wye}
            'd':
                Connection := 1;  {Delta or line-Line}
            'l':
                case Tests[2] of
                    'n':
                        Connection := 0;
                    'l':
                        Connection := 1;
                end;

        end;
        case Connection of
            1:
                Nterms := 1;  // Force reallocation of terminals
            0:
                if Fnterms <> 2 then
                    Nterms := 2;
        end;
    end;
end;

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
procedure TReactor.ReactorSetbus1(const s: String);

var
    s2: String;
    i, dotpos: Integer;

   // Special handling for Bus 1
   // Set Bus2 = Bus1.0.0.0

begin
    with ActiveReactorObj do
    begin
        SetBus(1, S);

     // Default Bus2 to zero node of Bus1 if not already defined. (Wye Grounded connection)

        if not Bus2Defined then
        begin
         // Strip node designations from S
            dotpos := Pos('.', S);
            if dotpos > 0 then
                S2 := Copy(S, 1, dotpos - 1)
            else
                S2 := Copy(S, 1, Length(S));  // copy up to Dot
            for i := 1 to Fnphases do
                S2 := S2 + '.0';

            SetBus(2, S2);
            IsShunt := TRUE;
        end;
    end;
end;


//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function TReactor.Edit(ActorID: Integer): Integer;

var
    ParamPointer: Integer;
    ParamName: String;
    Param: String;

begin
    Result := 0;
  // continue parsing with contents of Parser
    ActiveReactorObj := ElementList.Active;
    ActiveCircuit[ActorID].ActiveCktElement := ActiveReactorObj;  // use property to set this value


    with ActiveReactorObj do
    begin

        ParamPointer := 0;
        ParamName := Parser[ActorID].NextParam;
        Param := Parser[ActorID].StrValue;
        while Length(Param) > 0 do
        begin
            if Length(ParamName) = 0 then
                Inc(ParamPointer)
            else
                ParamPointer := CommandList.GetCommand(ParamName);

            if (ParamPointer > 0) and (ParamPointer <= NumProperties) then
                PropertyValue[ParamPointer] := Param;

            case ParamPointer of
                0:
                    DoSimpleMsg('Unknown parameter "' + ParamName + '" for Object "' + Class_Name + '.' + Name + '"', 230);
                1:
                    ReactorSetbus1(param);
                2:
                begin
                    Setbus(2, param);
                end;
                3:
{ Numphases := Parser.IntValue};  // see below
                4:
                    kvarRating := Parser[ActorID].Dblvalue;
                5:
                    kvRating := Parser[ActorID].Dblvalue;
                6:
                    InterpretConnection(Param);
                7:
                    DoMatrix(RMatrix, ActorID);
                8:
                    DoMatrix(XMatrix, ActorID);
                9:
                    IsParallel := InterpretYesNo(Param);
                10:
                    R := Parser[ActorID].Dblvalue;
                11:
                    X := Parser[ActorID].Dblvalue;
                12:
                    Rp := Parser[ActorID].Dblvalue;
                13:
                    Z1 := InterpretComplex(Param);
                14:
                    Z2 := InterpretComplex(Param);
                15:
                    Z0 := InterpretComplex(Param);
                16:
                    Z := InterpretComplex(Param);
                17:
                    RCurve := Param;
                18:
                    LCurve := Param;
                19:
                    L := Parser[ActorID].DblValue / 1000.0;  // convert from mH to H
            else
            // Inherited Property Edits
                ClassEdit(ActiveReactorObj, ParamPointer - NumPropsThisClass)
            end;

         // Some specials ...
            case ParamPointer of
                1:
                begin
                    PropertyValue[2] := GetBus(2);   // this gets modified
                    PrpSequence^[2] := 0;       // Reset this for save function
                end;
                2:
                    if CompareText(StripExtension(GetBus(1)), StripExtension(GetBus(2))) <> 0 then
                    begin
                        IsShunt := FALSE;
                        Bus2Defined := TRUE;
                    end;
                3:
                    if Fnphases <> Parser[ActorID].IntValue then
                    begin
                        Nphases := Parser[ActorID].IntValue;
                        NConds := Fnphases;  // Force Reallocation of terminal info
                        Yorder := Fnterms * Fnconds;
                    end;
                4:
                    SpecType := 1;   // X specified by kvar, kV
                7, 8:
                    SpecType := 3;
                11:
                    SpecType := 2;   // X specified directly rather than computed from kvar
                12:
                    RpSpecified := TRUE;
                13:
                begin
                    SpecType := 4;    // have to set Z1 to get this mode
                    if not Z2Specified then
                        Z2 := Z1;
                    if not Z0Specified then
                        Z0 := Z1;
                end;
                14:
                    Z2Specified := TRUE;
                15:
                    Z0Specified := TRUE;
                16:
                begin
                    R := Z.re;
                    X := Z.im;
                    SpecType := 2;
                end;
                17:
                    RCurveObj := XYCurveClass[ActorID].Find(RCurve);
                18:
                    LCurveObj := XYCurveClass[ActorID].Find(LCurve);
                19:
                begin
                    SpecType := 2;
                    X := L * TwoPi * BaseFrequency;
                end
            else
            end;

         //YPrim invalidation on anything that changes impedance values
            case ParamPointer of
                3..16:
                    YprimInvalid[ActorID] := TRUE;
                17:
                    if RCurveObj = NIL then
                        DoSimpleMsg('Resistance-frequency curve XYCurve.' + RCurve + ' not Found.', 2301);
                18:
                    if LCurveObj = NIL then
                        DoSimpleMsg('Inductance-frequency curve XYCurve.' + LCurve + ' not Found.', 2301);
                19:
                    YprimInvalid[ActorID] := TRUE;
            else
            end;

            ParamName := Parser[ActorID].NextParam;
            Param := Parser[ActorID].StrValue;
        end;

        RecalcElementData(ActorID);
    end;

end;

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function TReactor.MakeLike(const ReactorName: String): Integer;
var
    OtherReactor: TReactorObj;
    i: Integer;
begin
    Result := 0;
   {See if we can find this Reactor name in the present collection}
    OtherReactor := Find(ReactorName);
    if OtherReactor <> NIL then
        with ActiveReactorObj do
        begin

            if Fnphases <> OtherReactor.Fnphases then
            begin
                NPhases := OtherReactor.Fnphases;
                NConds := Fnphases; // force reallocation of terminals and conductors

                Yorder := Fnconds * Fnterms;
                YprimInvalid[ActiveActor] := TRUE;

            end;

            R := OtherReactor.R;
            X := OtherReactor.X;
            Rp := OtherReactor.Rp;

            RpSpecified := OtherReactor.RpSpecified;
            IsParallel := OtherReactor.IsParallel;

            kvarrating := OtherReactor.kvarrating;
            kvrating := OtherReactor.kvrating;
            Connection := OtherReactor.Connection;
            SpecType := OtherReactor.SpecType;

            Z := OtherReactor.Z;
            Z1 := OtherReactor.Z1;
            Z2 := OtherReactor.Z2;
            Z0 := OtherReactor.Z0;
            Z2Specified := OtherReactor.Z2Specified;
            Z0Specified := OtherReactor.Z0Specified;


            RCurve := OtherReactor.RCurve;
            RCurveobj := OtherReactor.RCurveobj;
            LCurve := OtherReactor.LCurve;
            LCurveobj := OtherReactor.LCurveobj;

            if OtherReactor.Rmatrix = NIL then
                Reallocmem(Rmatrix, 0)
            else
            begin
                Reallocmem(Rmatrix, SizeOf(Rmatrix^[1]) * Fnphases * Fnphases);
                for i := 1 to Fnphases * Fnphases do
                    Rmatrix^[i] := OtherReactor.Rmatrix^[i];
            end;

            if OtherReactor.Xmatrix = NIL then
                Reallocmem(Xmatrix, 0)
            else
            begin
                Reallocmem(Xmatrix, SizeOf(Xmatrix^[1]) * Fnphases * Fnphases);
                for i := 1 to Fnphases * Fnphases do
                    Xmatrix^[i] := OtherReactor.Xmatrix^[i];
            end;

            ClassMakeLike(OtherReactor);  // Take care of inherited class properties

            for i := 1 to ParentClass.NumProperties do
                PropertyValue[i] := OtherReactor.PropertyValue[i];
            Result := 1;
        end
    else
        DoSimpleMsg('Error in Reactor MakeLike: "' + ReactorName + '" Not Found.', 231);


end;

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function TReactor.Init(Handle: Integer; ActorID: Integer): Integer;

begin
    DoSimpleMsg('Need to implement TReactor.Init', -1);
    REsult := 0;
end;


//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//      TReactor Obj
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TReactorObj.Create(ParClass: TDSSClass; const ReactorName: String);

begin
    inherited Create(ParClass);
    Name := LowerCase(ReactorName);
    DSSObjType := ParClass.DSSClassType;

    NPhases := 3;  // Directly set conds and phases
    Fnconds := 3;
    Nterms := 2;  // Force allocation of terminals and conductors

    Setbus(2, (GetBus(1) + '.0.0.0'));  // Default to grounded wye

    IsShunt := TRUE;

    Rmatrix := NIL;
    Xmatrix := NIL;
    Gmatrix := NIL;
    Bmatrix := NIL;

    kvarrating := 100.0;
    kvrating := 12.47;
    X := SQR(kvrating) * 1000.0 / kvarrating;
    R := 0.0;
    Rp := 0.0;  // Indicates it has not been set to a proper value
    IsParallel := FALSE;
    RpSpecified := FALSE;
    Bus2Defined := FALSE;
    Z2Specified := FALSE;
    Z0Specified := FALSE;
    Connection := 0;   // 0 or 1 for wye (default) or delta, respectively
    SpecType := 1; // 1=kvar, 2=Cuf, 3=Cmatrix
    NormAmps := kvarRating * SQRT3 / kvrating;
    EmergAmps := NormAmps * 1.35;
    FaultRate := 0.0005;
    PctPerm := 100.0;
    HrsToRepair := 3.0;
    Yorder := Fnterms * Fnconds;

    RCurve := '';
    RCurveObj := NIL;
    LCurve := '';
    LCurveObj := NIL;

    RecalcElementData(ActiveActor);

    InitPropertyValues(0);
end;

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
destructor TReactorObj.Destroy;
begin
    ReallocMem(Rmatrix, 0);
    ReallocMem(Xmatrix, 0);
    ReallocMem(Gmatrix, 0);
    ReallocMem(Bmatrix, 0);
    inherited destroy;
end;

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
procedure TReactorObj.RecalcElementData(ActorID: Integer);
var
    KvarPerPhase, PhasekV: Double;
    i, CheckError: Integer;

begin

    case SpecType of

        1:
        begin // kvar
            kvarPerPhase := kvarRating / Fnphases;
            case Connection of
                1:
                begin  // Line-to-Line
                    PhasekV := kVRating;
                end;
            else
            begin  //  line-to-neutral
                case Fnphases of
                    2, 3:
                        PhasekV := kVRating / SQRT3;  // Assume three phase system
                else
                    PhasekV := kVRating;
                end;
            end;
            end;
            X := SQR(PhasekV) * 1000.0 / kvarPerPhase;
            L := X / twopi / BaseFrequency;
          {Leave R as specified}
            NormAmps := kvarPerPhase / PhasekV;
            EmergAmps := NormAmps * 1.35;
        end;
        2:
        begin // R + j X
          // Nothing much to do
            L := X / twopi / BaseFrequency;
        end;
        3:
        begin // Matrices

        end;
    end;

    if RpSpecified and (Rp <> 0.0) then
        Gp := 1.0 / Rp
    else
        Gp := 0.0; // default to 0,0 if Rp=0;

    if IsParallel and (SpecType = 3) then
    begin

        ReAllocmem(Gmatrix, SizeOf(Gmatrix^[1]) * Fnphases * Fnphases);
        ReAllocmem(Bmatrix, SizeOf(Bmatrix^[1]) * Fnphases * Fnphases);

         {Copy Rmatrix to Gmatrix and Invert}
        for i := 1 to Fnphases * Fnphases do
            Gmatrix^[i] := RMatrix^[i];
// should be Gmatrix         ETKInvert(Rmatrix, Fnphases, CheckError);
        ETKInvert(Gmatrix, Fnphases, CheckError);
        if CheckError > 0 then
        begin
            DoSimpleMsg('Error inverting R Matrix for Reactor.' + name + ' - G is zeroed.', 232);
            for i := 1 to Fnphases * Fnphases do
                Gmatrix^[i] := 0.0;
        end;

         {Copy Xmatrix to Bmatrix and Invert}
        for i := 1 to Fnphases * Fnphases do
            Bmatrix^[i] := -XMatrix^[i];
        ETKInvert(Bmatrix, Fnphases, CheckError);
        if CheckError > 0 then
        begin
            DoSimpleMsg('Error inverting X Matrix for Reactor.' + name + ' - B is zeroed.', 233);
            for i := 1 to Fnphases * Fnphases do
                Bmatrix^[i] := 0.0;
        end;
    end;


end;

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
procedure TReactorObj.CalcYPrim(ActorID: Integer);

var
    Value, Value1, Value2: Complex;
    Calpha1, CAlpha2: Complex;
 //  Y0, Y1, Y2 : Complex;
    i, j, idx: Integer;
    FreqMultiplier: Double;
    ZValues: pComplexArray;
    YPrimTemp,
    ZMatrix{, Ymatrix }: TCMatrix;
    RValue, LValue: Double;

begin

// Normally build only Yprim Shunt, but if there are 2 terminals and
// Bus1 <> Bus 2


    if YprimInvalid[ActorID] then
    begin    // Reallocate YPrim if something has invalidated old allocation
        if YPrim_Shunt <> NIL then
            YPrim_Shunt.Free;
        YPrim_Shunt := TcMatrix.CreateMatrix(Yorder);
        if Yprim_Series <> NIL then
            Yprim_Series.Free;
        Yprim_Series := TcMatrix.CreateMatrix(Yorder);
        if YPrim <> NIL then
            YPrim.Free;
        YPrim := TcMatrix.CreateMatrix(Yorder);
    end
    else
    begin
        YPrim_Series.Clear; // zero out YPrim
        YPrim_Shunt.Clear; // zero out YPrim
        Yprim.Clear;
    end;

    if IsShunt then
        YPrimTemp := YPrim_Shunt
    else
        YPrimTemp := Yprim_Series;


    with YPrimTemp do
    begin

        FYprimFreq := ActiveCircuit[ActorID].Solution.Frequency;
        FreqMultiplier := FYprimFreq / BaseFrequency;

     {If GIC simulation, Resistance Only }
        if ActiveCircuit[ActorID].Solution.Frequency < 0.51 then
        begin    // 0.5 Hz is cutoff
            if X > 0.0 then
                if R <= 0.0 then
                    R := X / 50.0;   // Assume X/R = 50
            FYprimFreq := 0.0;        // Set these to 0.0 for GIC model
            FreqMultiplier := 0.0;    // sets reactance part to zero
        end;

    { Now, Put in Yprim matrix }

        case SpecType of

            1, 2:
            begin   {Some form of R and X specified}
               // Adjust for frequency
                if Assigned(RCurveObj) then
                    RValue := R * RCurveObj.GetYValue(FYprimFreq)
                else
                    RValue := R;
                if Assigned(LCurveObj) then
                    LValue := L * LCurveObj.GetYValue(FYprimFreq)
                else
                    LValue := L;

                Value := Cinv(Cmplx(RValue, LValue * Twopi * FYprimFreq));
               // Add in Rp Value if specified
                if RpSpecified then
                    Caccum(Value, Cmplx(Gp, 0.0));

                case Connection of
                    1:
                    begin   // Line-Line
                        Value2 := CmulReal(Value, 2.0);
                        Value := cnegate(Value);
                        for i := 1 to Fnphases do
                        begin
                            SetElement(i, i, Value2);
                            for j := 1 to i - 1 do
                                SetElemSym(i, j, Value);
                        end;
                        // Remainder of the matrix is all zero
                    end;
                else
                begin // Wye
                    for i := 1 to Fnphases do
                    begin
                        SetElement(i, i, Value);     // Elements are only on the diagonals
                        SetElement(i + Fnphases, i + Fnphases, Value);
                        SetElemSym(i, i + Fnphases, cnegate(Value));
                    end;
                end;
                end;

            end;

            3:
            begin    // Z matrix specified
            {Compute Z matrix}

             { Put in Parallel R & L }
                if IsParallel then
                begin  {Build Z as a Y Matrix}

                    for i := 1 to Fnphases do
                    begin
                        for j := 1 to Fnphases do
                        begin
                            idx := (j - 1) * Fnphases + i;
                       {FreqMultiplier = 0 signifies GIC model where we only need R part}
                            if FreqMultiplier > 0.0 then
                                Value := Cmplx(Gmatrix^[idx], Bmatrix^[idx] / FreqMultiplier)
                            else
                                Value := Cmplx(Gmatrix^[idx], 0.0);
                            SetElement(i, j, Value);
                            SetElement(i + Fnphases, j + Fnphases, Value);
                            SetElemSym(i, j + Fnphases, Cnegate(Value));
                        end;
                    end;

                end
                else
                begin   {For Series R and X}
                    Zmatrix := TcMatrix.CreateMatrix(Fnphases);
                    ZValues := Zmatrix.GetValuesArrayPtr(Fnphases);  // So we can stuff array fast
                 { Put in Series R & L }
                    for i := 1 to Fnphases * Fnphases do
                    begin
                   // Correct the impedances for frequency
                        ZValues^[i] := Cmplx(RMatrix^[i], Xmatrix^[i] * FreqMultiplier);
                    end;

                    ZMatrix.Invert;  {Invert in place - is now Ymatrix}
                    if ZMatrix.InvertError > 0 then
                    begin       {If error, put in tiny series conductance}
                        DoErrorMsg('TReactorObj.CalcYPrim', 'Matrix Inversion Error for Reactor "' + Name + '"',
                            'Invalid impedance specified. Replaced with tiny conductance.', 234);
                        ZMatrix.Clear;
                        for i := 1 to Fnphases do
                            ZMatrix.SetElement(i, i, Cmplx(epsilon, 0.0));
                    end;

                    for i := 1 to Fnphases do
                    begin
                        for j := 1 to Fnphases do
                        begin
                            Value := Zmatrix.GetElement(i, j);
                            SetElement(i, j, Value);
                            SetElement(i + Fnphases, j + Fnphases, Value);
                            SetElemSym(i, j + Fnphases, Cnegate(Value));
                        end;
                    end;

                    Zmatrix.Free;
                end;
            end;

            4:
            begin  // Symmetrical component Z's specified

(***

   parallel doesn't make sense
              If IsParallel Then
               Begin

                 If Cabs(Z0) > 0.0 Then Y0 := Cinv(Z0) Else Y0 := Cmplx(1.0e12, 0.0);
                 If Cabs(Z1) > 0.0 Then Y1 := Cinv(Z1) Else Y1 := Cmplx(1.0e12, 0.0);
                 If Cabs(Z2) > 0.0 Then Y2 := Cinv(Z2) Else Y2 := Cmplx(1.0e12, 0.0);

                  {Assumes the sequence networks are in parallel}
                 Ymatrix := TcMatrix.CreateMatrix(Fnphases);

                // diagonal elements  -- all the same
                 If Fnphases=1 Then // assume positive sequence only model
                     Value := Y1
                 Else
                     Value := Cadd(Y2, Cadd(Y1, Y0));

                 Value.im := Value.im / FreqMultiplier; // Correct the impedances for frequency
                 Value    := CdivReal(Value, 3.0);
                 With Ymatrix Do FOR i := 1 to Fnphases  Do SetElement(i, i, Value);



                 If FnPhases = 3 Then     // otherwise undefined
                 Begin
                     Calpha1 := Conjg(Calpha);   // Change it to agree with textbooks
                     Calpha2 := Cmul(Calpha1, Calpha1);  // Alpha squared  = 1 /_ 240 = 1/_-120
                     Value2  := Cadd(Cmul(Calpha2,Y2),Cadd(Cmul(Calpha1, Y1), Y0));
                     Value1  := Cadd(Cmul(Calpha2,Y1),Cadd(Cmul(Calpha1, Y2), Y0));

                     Value1.im := Value1.im / FreqMultiplier; // Correct the impedances for frequency
                     Value2.im := Value2.im / FreqMultiplier; // Correct the impedances for frequency

                     Value1 := CdivReal(Value1, 3.0);
                     Value2 := CdivReal(Value2, 3.0);
                     With Ymatrix Do Begin
                       //Lower Triangle
                         SetElement(2, 1, Value1);
                         SetElement(3, 1, Value2);
                         SetElement(3, 2, Value1);
                       //Upper Triangle
                         SetElement(1, 2, Value2);
                         SetElement(1, 3, Value1);
                         SetElement(2, 3, Value2);
                     End;
                 End;

                 FOR i := 1 to Fnphases Do  BEGIN       // could be asymmetric
                    FOR j := 1 to Fnphases Do  BEGIN
                       Value := Ymatrix.GetElement(i,j);
                       SetElement(i, j, Value);
                       SetElement(i+Fnphases, j+Fnphases, Value);
                       SetElement(i, j+Fnphases, Cnegate(Value));
                       SetElement(i+Fnphases, j, Cnegate(Value));
                     END;
                  END;

                  Ymatrix.Free;

               End
               Else Begin
***)
                {Series R+jX }

                Zmatrix := TcMatrix.CreateMatrix(Fnphases);

                 // diagonal elements  -- all the same
                if Fnphases = 1 then // assume positive sequence only model
                    Value := Z1
                else
                    Value := Cadd(Z2, Cadd(Z1, Z0));

                Value.im := Value.im * FreqMultiplier; // Correct the impedances for frequency
                Value := CdivReal(Value, 3.0);
                for i := 1 to Fnphases do
                begin
                    Zmatrix.SetElement(i, i, Value)
                end;

                if FnPhases = 3 then     // otherwise undefined
                begin

                   // There are two possible off-diagonal elements  if Z1 <> Z2
                   // Calpha is defined as 1 /_ -120 instead of 1 /_ 120

                    Calpha1 := Conjg(Calpha);   // Change it to agree with textbooks
                    Calpha2 := Cmul(Calpha1, Calpha1);  // Alpha squared  = 1 /_ 240 = 1/_-120
                    Value2 := Cadd(Cmul(Calpha2, Z2), Cadd(Cmul(Calpha1, Z1), Z0));
                    Value1 := Cadd(Cmul(Calpha2, Z1), Cadd(Cmul(Calpha1, Z2), Z0));

                    Value1.im := Value1.im * FreqMultiplier; // Correct the impedances for frequency
                    Value2.im := Value2.im * FreqMultiplier; // Correct the impedances for frequency

                    Value1 := CdivReal(Value1, 3.0);
                    Value2 := CdivReal(Value2, 3.0);
                    with Zmatrix do
                    begin
                     //Lower Triangle
                        SetElement(2, 1, Value1);
                        SetElement(3, 1, Value2);
                        SetElement(3, 2, Value1);
                     //Upper Triangle
                        SetElement(1, 2, Value2);
                        SetElement(1, 3, Value1);
                        SetElement(2, 3, Value2);
                    end;

                end;

                ZMatrix.Invert;  {Invert in place - is now Ymatrix}
                if ZMatrix.InvertError > 0 then
                begin       {If error, put in tiny series conductance}
                    DoErrorMsg('TReactorObj.CalcYPrim', 'Matrix Inversion Error for Reactor "' + Name + '"',
                        'Invalid impedance specified. Replaced with tiny conductance.', 234);
                    ZMatrix.Clear;
                    for i := 1 to Fnphases do
                        ZMatrix.SetElement(i, i, Cmplx(epsilon, 0.0));
                end;

                for i := 1 to Fnphases do
                begin
                    for j := 1 to Fnphases do
                    begin
                        Value := Zmatrix.GetElement(i, j);
                        SetElement(i, j, Value);
                        SetElement(i + Fnphases, j + Fnphases, Value);
                        SetElement(i, j + Fnphases, Cnegate(Value));
                        SetElement(i + Fnphases, j, Cnegate(Value));
                    end;
                end;

                Zmatrix.Free;

            end;
       //    END;
        end;

    end; {With YPRIM}

    // Set YPrim_Series based on diagonals of YPrim_shunt  so that CalcVoltages doesn't fail
    if IsShunt then
    begin
        if (Nphases = 1) and (not ActiveCircuit[ActorID].PositiveSequence) then  // assume a neutral or grounding reactor; Leave diagonal in the circuit
            for i := 1 to Yorder do
                Yprim_Series.SetElement(i, i, Yprim_Shunt.Getelement(i, i))
        else
            for i := 1 to Yorder do
                Yprim_Series.SetElement(i, i, CmulReal(Yprim_Shunt.Getelement(i, i), 1.0e-10));
    end;

    Yprim.Copyfrom(YPrimTemp);
    {Don't Free YPrimTemp - It's just a pointer to an existing complex matrix}

    inherited CalcYPrim(ActorID);

    YprimInvalid[ActorID] := FALSE;
end;

procedure TReactorObj.DumpProperties(var F: TextFile; Complete: Boolean);

var
    i, j, k: Integer;

begin
    inherited DumpProperties(F, Complete);

    with ParentClass do
        for k := 1 to NumProperties do
        begin
            case k of  // was 'CASE i of' - good example of reason to remove all warnings 
                7:
                    if Rmatrix <> NIL then
                    begin
                        Write(F, PropertyName^[k], '= (');
                        for i := 1 to Fnphases do
                        begin
                            for j := 1 to Fnphases do
                                Write(F, Format('%-.5g', [RMatrix^[(i - 1) * Fnphases + j]]), ' ');
                            if i <> Fnphases then
                                Write(F, '|');
                        end;
                        Writeln(F, ')');
                    end;
                8:
                    if Xmatrix <> NIL then
                    begin
                        Write(F, PropertyName^[k], '= (');
                        for i := 1 to Fnphases do
                        begin
                            for j := 1 to Fnphases do
                                Write(F, Format('%-.5g', [XMatrix^[(i - 1) * Fnphases + j]]), ' ');
                            if i <> Fnphases then
                                Write(F, '|');
                        end;
                        Writeln(F, ')');
                    end;
                13:
                    Writeln(F, Format('~ Z1=[%-.8g, %-.8g]', [Z1.re, Z1.im]));
                14:
                    Writeln(F, Format('~ Z2=[%-.8g, %-.8g]', [Z2.re, Z2.im]));
                15:
                    Writeln(F, Format('~ Z0=[%-.8g, %-.8g]', [Z0.re, Z0.im]));
                16:
                    Writeln(F, Format('~ Z =[%-.8g, %-.8g]', [R, X]));
                19:
                    Writeln(F, Format('~ LmH=%-.8g', [L * 1000.0]));
            else
                Writeln(F, '~ ', PropertyName^[k], '=', PropertyValue[k]);
            end;
        end;

end;

procedure TReactorObj.DumpPropertiesCSV(var F: TextFile);

var
    i: Integer;

begin
    inherited DumpPropertiesCSV(F);

    Write(F, Format(',%s', [FirstBus]));

    if Bus2Defined then
        Write(F, Format(',%s', [NextBus]))
    else
        Write(F, ',');

    Write(F, Format(',%s', [ConnectionToString(Connection)]));

    case SpecType of
        1:
            Write(F, ',kvar');
        2:
            Write(F, ',z');
        else
            Write(F, ',');
    end;

    Write(F, Format(',%.16g,%.16g,%.16g', [kvarRating, kvRating, R, X]));
end;

procedure TReactorObj.GetLosses(var TotalLosses, LoadLosses, NoLoadLosses: Complex; ActorID: Integer);
var
    i: Integer;
begin

  {Only report No Load Losses if Rp defined and Reactor is a shunt device;
   Else do default behavior.}

    if (RpSpecified and IsShunt and (Rp <> 0.0)) then
    begin

        TotalLosses := Losses[ActorID];  // Side effect: computes Iterminal and Vterminal
     {Compute losses in Rp Branch from voltages across shunt element -- node to ground}
        NoLoadLosses := CZERO;
        with ActiveCircuit[ActorID].Solution do
            for i := 1 to FNphases do
                with NodeV^[NodeRef^[i]] do
                    Caccum(NoLoadLosses, cmplx((SQR(re) + SQR(im)) / Rp, 0.0));  // V^2/Rp

        if ActiveCircuit[ActorID].PositiveSequence then
            CmulReal(NoLoadLosses, 3.0);
        LoadLosses := Csub(TotalLosses, NoLoadLosses);  // Subtract no load losses from total losses

    end

    else
        inherited;   {do the default Cktelement behaviors}

end;

function TReactorObj.GetPropertyValue(Index: Integer): String;
begin

    case Index of
        10:
            Result := Format('%-.8g', [R]);
        11:
            Result := Format('%-.8g', [X]);
          {Special cases for array properties}
        13:
            Result := Format('[%-.8g, %-.8g]', [Z1.re, Z1.im]);
        14:
            Result := Format('[%-.8g, %-.8g]', [Z2.re, Z2.im]);
        15:
            Result := Format('[%-.8g, %-.8g]', [Z0.re, Z0.im]);
        16:
            Result := Format('[%-.8g, %-.8g]', [R, X]);
        19:
            Result := Format('%-.8g', [L * 1000.0]);
    else
        Result := inherited GetPropertyValue(index);
    end;

end;

procedure TReactorObj.InitPropertyValues(ArrayOffset: Integer);
begin

    PropertyValue[1] := GetBus(1);
    PropertyValue[2] := GetBus(2);
    PropertyValue[3] := '3';
    PropertyValue[4] := '1200';
    PropertyValue[5] := '12.47';
    PropertyValue[6] := 'wye';
    PropertyValue[7] := '';
    PropertyValue[8] := '';
    PropertyValue[9] := 'NO';  // Parallel
    PropertyValue[10] := '0';  // R series
    PropertyValue[11] := Format('%-.6g', [X]);  //X
    PropertyValue[12] := '0';  //Rp
    PropertyValue[13] := '[0 0]';  //Z1
    PropertyValue[14] := '[0 0]';  //Z2
    PropertyValue[15] := '[0 0]';  //Z0
    PropertyValue[16] := '[0 0]';  //Z
    PropertyValue[17] := '';
    PropertyValue[18] := '';
    PropertyValue[19] := Format('%-.8g', [X / TwoPi / BaseFrequency * 1000.0]);  //X

    inherited  InitPropertyValues(NumPropsThisClass);

     //  Override Inherited properties
    PropertyValue[NumPropsThisClass + 1] := Str_Real(Normamps, 0);
    PropertyValue[NumPropsThisClass + 2] := Str_Real(Emergamps, 0);
    PropertyValue[NumPropsThisClass + 3] := Str_Real(FaultRate, 0);
    PropertyValue[NumPropsThisClass + 4] := Str_Real(PctPerm, 0);
    PropertyValue[NumPropsThisClass + 5] := Str_Real(HrsToRepair, 0);

    ClearPropSeqArray;

end;


procedure TReactorObj.MakePosSequence(ActorID: Integer);
var
    S: String;
    kvarperphase, phasekV, Rs, Rm: Double;
    i, j: Integer;

begin
    {If FnPhases>1 Then }
    begin
        S := ' ';
        case SpecType of

            1:
            begin // kvar
                kvarPerPhase := kvarRating / 3.0;  // divide among 3 phases Fnphases;
                if (FnPhases > 1) or (Connection <> 0) then
                    PhasekV := kVRating / SQRT3
                else
                    PhasekV := kVRating;

                S := 'Phases=1 ' + Format(' kV=%-.5g kvar=%-.5g', [PhasekV, kvarPerPhase]);
              {Leave R as specified}

            end;
            2:
            begin // R + j X
                S := 'Phases=1 ';
            end;
            3:
                if FnPhases > 1 then
                begin // Matrices
                    S := 'Phases=1 ';
              // R1
                    Rs := 0.0;   // Avg Self
                    for i := 1 to FnPhases do
                        Rs := Rs + Rmatrix^[(i - 1) * Fnphases + i];
                    Rs := Rs / FnPhases;
                    Rm := 0.0;     //Avg mutual
                    for i := 2 to FnPhases do
                        for j := i to FnPhases do
                            Rm := Rm + Rmatrix^[(i - 1) * Fnphases + j];
                    Rm := Rm / (FnPhases * (Fnphases - 1.0) / 2.0);

                    S := S + Format(' R=%-.5g', [(Rs - Rm)]);

              // X1
                    Rs := 0.0;   // Avg Self
                    for i := 1 to FnPhases do
                        Rs := Rs + Xmatrix^[(i - 1) * Fnphases + i];
                    Rs := Rs / FnPhases;
                    Rm := 0.0;     //Avg mutual
                    for i := 2 to FnPhases do
                        for j := i to FnPhases do
                            Rm := Rm + Xmatrix^[(i - 1) * Fnphases + j];
                    Rm := Rm / (FnPhases * (Fnphases - 1.0) / 2.0);

                    S := S + Format(' X=%-.5g', [(Rs - Rm)]);

                end;
            4:
            begin // symmetrical components  Z1 specified
                S := 'Phases=1 ';
            end;

        end;

        Parser[ActorID].CmdString := S;
        Edit(ActorID);

    end;


    inherited;

end;

end.
