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
    Vsource,
    Load,
    Line,
    Transformer;

procedure ExportCKV(FileNm: String);

{Exports  properties for all  Circuit Elements}

var
    F: TextFile;
    i, j, k: Integer;
    cValues: pComplexArray;
    BusName: String;
    FileName: String;
    pVsrc: TVsourceObj;
    pLine: TLineObj;
    pLoad: TLoadObj;
    pXf: TTransfObj;
    Bus: TDSSbus;

begin

    if ActiveCircuit[ActiveActor] = NIL then
        Exit;

    pVsrc := ActiveCircuit[ActiveActor].Sources.First;
    if pVsrc <> NIL then
    try
        Assignfile(F, GetOutputDirectory + 'VSource.csv');
        ReWrite(F);

        Writeln(F, 'name,enabled,n_phases,n_conds,base_freq,terminal1,terminal2,base_kv,per_unit,angle,src_frequency,z_spec_type,mva_sc3,mva_sc1,i_sc3,i_sc1,r1,x1,r2,x2,r0,x0,x1r1,x0r0,scan_type,sequence_type,spectrum');

        while pVsrc <> NIL do
        begin
            if pVsrc.ClassNameIs('TVSourceObj') then // pIsrc are in the same list
            begin
                pVsrc.DumpPropertiesCSV(F);
                Writeln(F);
            end;
            pVsrc := ActiveCircuit[ActiveActor].Sources.Next;
        end;
    finally
        CloseFile(F);
    end;

    pLine := ActiveCircuit[ActiveActor].Lines.First;
    if pLine <> NIL then
    try
        Assignfile(F, GetOutputDirectory + 'Line.csv');
        ReWrite(F);

        Writeln(F, 'name,enabled,n_phases,n_conds,base_freq,terminal1,terminal2,length,units,line_code,geometry');

        while pLine <> NIL do
        begin
            pLine.DumpPropertiesCSV(F);
            Writeln(F);
            pLine := ActiveCircuit[ActiveActor].Lines.Next;
        end;
    finally
        CloseFile(F);
    end;

    pLoad := ActiveCircuit[ActiveActor].Loads.First;
    if pLoad <> NIL then
    try
        Assignfile(F, GetOutputDirectory + 'Load.csv');
        ReWrite(F);

        Writeln(F, 'name,enabled,n_phases,n_conds,base_freq,terminal1,kv,kw,kvar,kva,pf,model,vmin_pu,vmax_pu,r_neut,x_neut,connection,spec_type,status,yearly,daily,duty,spectrum');

        while pLoad <> NIL do
        begin
            pLoad.DumpPropertiesCSV(F);
            Writeln(F);
            pLoad := ActiveCircuit[ActiveActor].Loads.Next;
        end;
    finally
        CloseFile(F);
    end;

    pXf := ActiveCircuit[ActiveActor].Transformers.First;
    if pXf <> NIL then
    try
        Assignfile(F, GetOutputDirectory + 'Transformer.csv');
        ReWrite(F);

        Writeln(F, 'name,enabled,n_phases,n_conds,base_freq,x_hl,x_ht,x_lt,pct_load_loss,ppm_anti_float');

        while pXf <> NIL do
        begin
            pXf.DumpPropertiesCSV(F);
            Writeln(F);
            pXf := ActiveCircuit[ActiveActor].Transformers.Next;
        end;
    finally
        CloseFile(F);
    end;

    pXf := ActiveCircuit[ActiveActor].Transformers.First;
    if pXf <> NIL then
    try
        Assignfile(F, GetOutputDirectory + 'Winding.csv');
        ReWrite(F);

        Writeln(F, 'transformer,winding,terminal,connection,kv,kva,tap,r_pct,r_neut,x_neut,max_tap,min_tap,num_taps');

        while pXf <> NIL do
        begin
            pXf.DumpWindingPropertiesCSV(F);
            pXf := ActiveCircuit[ActiveActor].Transformers.Next;
        end;
    finally
        CloseFile(F);
    end;
end;

end.
