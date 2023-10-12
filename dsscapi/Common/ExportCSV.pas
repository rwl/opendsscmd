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
            Writeln(F, 'name,enabled,n_phases,n_conds,base_freq,terminal1,terminal2,base_kv,per_unit,angle,src_frequency,z_spec_type,mva_sc3,mva_sc1,i_sc3,i_sc1,r1,x1,r2,x2,r0,x0,x1r1,x0r0,scan_type,sequence_type,spectrum');

            pVsrc := ActiveCircuit[ActiveActor].Sources.First;
            while pVsrc <> NIL do
            begin
                if pVsrc.ClassNameIs('TVSourceObj') then // pIsrc are in the same list
                begin
                    pVsrc.DumpPropertiesCSV(F, ActiveActor);
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
