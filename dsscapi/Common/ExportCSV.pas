unit ExportCSV;

interface

procedure ExportCKV(FileNm: String);

implementation

uses
    uComplex,
    Arraydef,
    Sysutils,
    DSSClassDefs,
    DSSGlobals,
    Circuit,
    Bus,
    Utilities,
    Vsource;

procedure ExportCKV(FileNm: String);

{Exports  properties for all  Circuit Elements}

var
    F: TextFile;
    i, j, k: Integer;
    cValues: pComplexArray;
    BusName: String;
    FileName: String;
    pVsrc: TVsourceObj;
    Bus: TDSSbus;

begin

    if ActiveCircuit[ActiveActor] = NIL then
        Exit;

    FileName := GetOutputDirectory + 'VSource.csv';

    try
        Assignfile(F, FileName);
        ReWrite(F);

        with ActiveCircuit[ActiveActor] do
        begin
            Writeln(F, 'name,enabled,n_phases,base_freq,terminal1,terminal2,base_kv,per_unit,angle,src_frequency,z_spec_type,mva_sc3,mva_sc1,i_sc3,i_sc1,r1,x1,r2,x2,r0,x0,x1r1,x0r0,scan_type,sequence_type,spectrum');
            
            pVsrc := ActiveCircuit[ActiveActor].Sources.First; // pIsrc are in the same list
            while pVsrc <> NIL do
            begin
                if pVsrc.ClassNameIs('TVSourceObj') then
                begin
                    Write(F, pVsrc.Name);
                    if pVsrc.Enabled then Write(F, ',true') else Write(F, ',false');
                    Write(F, Format(',%d,%g', [pVsrc.NPhases, pVsrc.BaseFrequency]));

                    // Bus := Buses^[pVsrc.Terminals^[1].BusRef];
                    // BusName := BusList.Get(pVsrc.Terminals^[1].BusRef);

                    // Write(F, BusName);
                    Write(F, Format(',%s', [BusList.Get(pVsrc.Terminals^[1].BusRef)]));
                    for i := 1 to pVsrc.NConds do
                        Write(F, Format('.%d', [pVsrc.Terminals^[1].TermNodeRef^[i]]));

                    if pVsrc.Bus2Defined then
                    begin
                        Write(F, Format(',%s', [BusList.Get(pVsrc.Terminals^[2].BusRef)]));
                        for i := 1 to pVsrc.NConds do
                            Write(F, Format('.%d', [pVsrc.Terminals^[2].TermNodeRef^[i]]));
                    end
                    else
                        Write(F, ',');

                    Write(F, Format(',%g,%g,%g', [pVsrc.kVBase, pVsrc.PerUnit, pVsrc.Angle]));
                    Writeln(F);
                end;
                pVsrc := ActiveCircuit[ActiveActor].Sources.Next;
            end;
        end;

    finally

        CloseFile(F);

    end;

end;

end.
