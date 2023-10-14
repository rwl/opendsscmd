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
    CktElement,

    Vsource,
    Isource,
    Load,
    Generator,

    Line,
    Transformer,

    LineCode,
    LineGeometry,
    LineSpacing,
    WireData,
    CNData,
    TSData;

procedure ExportCKV(FileNm: String);

{Exports  properties for all  Circuit Elements}

var
    F: TextFile;
    i, j, k: Integer;
    cValues: pComplexArray;
    BusName: String;
    FileName: String;

    pElem: TDSSCktElement;

    pVsrc: TVsourceObj;
    pIsrc: TIsourceObj;
    pLoad: TLoadObj;
    pGen: TGeneratorObj;

    pLine: TLineObj;
    pXf: TTransfObj;
    Bus: TDSSbus;

    clsCode: TLineCode;
    clsGeom: TLineGeometry;
    clsWire: TWireData;
    clsSpac: TLineSpacing;
    clsTape: TTSData;
    clsConc: TCNData;

    pCode: TLineCodeObj;
    pGeom: TLineGeometryObj;
    pWire: TWireDataObj;
    pSpac: TLineSpacingObj;
    pTape: TTSDataObj;
    pConc: TCNDataObj;

begin

    if ActiveCircuit[ActiveActor] = NIL then
        Exit;

    pVsrc := ActiveCircuit[ActiveActor].Sources.First;
    while pVsrc <> NIL do
    begin
        if pVsrc.ClassNameIs('TVSourceObj') then
        begin
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
            break;
        end
        else
            pVsrc := ActiveCircuit[ActiveActor].Sources.Next;
    end;

    pIsrc := ActiveCircuit[ActiveActor].Sources.First;
    while pVsrc <> NIL do
    begin
        if pVsrc.ClassNameIs('TISourceObj') then
        begin
            try
                Assignfile(F, GetOutputDirectory + 'ISource.csv');
                ReWrite(F);

                Writeln(F, 'name,enabled,n_phases,n_conds,base_freq,terminal1,terminal2,amps,angle,src_frequency,spectrum');

                while pIsrc <> NIL do
                begin
                    if pIsrc.ClassNameIs('TISourceObj') then // pVsrc are in the same list
                    begin
                        pIsrc.DumpPropertiesCSV(F);
                        Writeln(F);
                    end;
                    pIsrc := ActiveCircuit[ActiveActor].Sources.Next;
                end;
            finally
                CloseFile(F);
            end;
            break;
        end
        else
            pIsrc := ActiveCircuit[ActiveActor].Sources.Next;
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

    pGen := ActiveCircuit[ActiveActor].Generators.First;
    if pGen <> NIL then
    try
        Assignfile(F, GetOutputDirectory + 'Generator.csv');
        ReWrite(F);

        Writeln(F, 'name,enabled,n_phases,n_conds,base_freq,terminal,kv,kw,pf,model,connection,duty,fixed,v_min_pu,v_max_pu,max_kvar,min_kvar,balanced,spectrum');

        while pGen <> NIL do
        begin
            pGen.DumpPropertiesCSV(F);
            Writeln(F);
            pGen := ActiveCircuit[ActiveActor].Generators.Next;
        end;
    finally
        CloseFile(F);
    end;

    pElem := ActiveCircuit[ActiveActor].PDElements.First;
    while pElem <> NIL do
    begin
        if (CLASSMASK and pElem.DSSObjType) = CAP_ELEMENT then
        begin
            try
                Assignfile(F, GetOutputDirectory + 'Capacitor.csv');
                ReWrite(F);

                Writeln(F, 'name,enabled,n_phases,n_conds,base_freq,terminal1,terminal2,connection,num_steps,spec_type,kvar,kv,c,r,xl');

                while pElem <> NIL do
                begin
                    if (CLASSMASK and pElem.DSSObjType) = CAP_ELEMENT then
                    begin
                        pElem.DumpPropertiesCSV(F);
                        Writeln(F);
                    end;
                    pElem := ActiveCircuit[ActiveActor].PDElements.Next;
                end;
            finally
                CloseFile(F);
            end;
            break;
        end
        else
            pElem := ActiveCircuit[ActiveActor].PDElements.Next;
    end;

    pElem := ActiveCircuit[ActiveActor].PDElements.First;
    while pElem <> NIL do
    begin
        if (CLASSMASK and pElem.DSSObjType) = REACTOR_ELEMENT then
        begin
            try
                Assignfile(F, GetOutputDirectory + 'Reactor.csv');
                ReWrite(F);

                Writeln(F, 'name,enabled,n_phases,n_conds,base_freq,terminal1,terminal2,connection,spec_type,kvar,kv,r,x');

                while pElem <> NIL do
                begin
                    if (CLASSMASK and pElem.DSSObjType) = REACTOR_ELEMENT then
                    begin
                        pElem.DumpPropertiesCSV(F);
                        Writeln(F);
                    end;
                    pElem := ActiveCircuit[ActiveActor].PDElements.Next;
                end;
            finally
                CloseFile(F);
            end;
            break;
        end
        else
            pElem := ActiveCircuit[ActiveActor].PDElements.Next;
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

    clsCode := DSSClassList[ActiveActor].Get(ClassNames[ActiveActor].Find('linecode'));
    pCode := clsCode.ElementList.First;
    if pCode <> NIL then
    try
        Assignfile(F, GetOutputDirectory + 'LineCode.csv');
        ReWrite(F);

        Writeln(F, 'name,n_phases,r1,x1,r0,x0,c1,c0,units,r_matrix,x_matrix,c_matrix,rg,xg,rho,symmetrical_components');

        while pCode <> NIL do
        begin
            pCode.DumpPropertiesCSV(F);
            Writeln(F);
            pCode := clsCode.ElementList.Next;
        end;
    finally
        CloseFile(F);
    end;

    clsGeom := DSSClassList[ActiveActor].Get(ClassNames[ActiveActor].Find('linegeometry'));
    pGeom := clsGeom.ElementList.First;
    if pGeom <> NIL then
    try
        Assignfile(F, GetOutputDirectory + 'LineGeometry.csv');
        ReWrite(F);

        Writeln(F, 'name,n_phases,n_conds,reduce,rho_earth,x_coords,heights,units,spacing,wires,cn_cables,ts_cables');

        while pGeom <> NIL do
        begin
            pGeom.DumpPropertiesCSV(F);
            Writeln(F);
            pGeom := clsGeom.ElementList.Next;
        end;
    finally
        CloseFile(F);
    end;

    clsSpac := DSSClassList[ActiveActor].Get(ClassNames[ActiveActor].Find('linespacing'));
    pSpac := clsSpac.ElementList.First;
    if pSpac <> NIL then
    try
        Assignfile(F, GetOutputDirectory + 'LineSpacing.csv');
        ReWrite(F);

        Writeln(F, 'name,n_phases,n_conds,x_coords,heights,units');

        while pSpac <> NIL do
        begin
            pSpac.DumpPropertiesCSV(F);
            Writeln(F);
            pSpac := clsSpac.ElementList.Next;
        end;
    finally
        CloseFile(F);
    end;

    clsWire := DSSClassList[ActiveActor].Get(ClassNames[ActiveActor].Find('wiredata'));
    pWire := clsWire.ElementList.First;
    if pWire <> NIL then
    try
        Assignfile(F, GetOutputDirectory + 'WireData.csv');
        ReWrite(F);

        Writeln(F, 'name,r,r_dc,r_units,gmr,gmr_units,radius,radius_units,normal_amps,emergency_amps');

        while pWire <> NIL do
        begin
            pWire.DumpPropertiesCSV(F);
            Writeln(F);
            pWire := clsWire.ElementList.Next;
        end;
    finally
        CloseFile(F);
    end;

    clsConc := DSSClassList[ActiveActor].Get(ClassNames[ActiveActor].Find('CNData'));
    pConc := clsConc.ElementList.First;
    if pConc <> NIL then
    try
        Assignfile(F, GetOutputDirectory + 'CNData.csv');
        ReWrite(F);

        Writeln(F, 'name,n_phases,n_conds,eps_r,ins_layer,dia_ins,dia_cable,k_strand,dia_strand,gmr_strand,r_strand');

        while pConc <> NIL do
        begin
            pConc.DumpPropertiesCSV(F);
            Writeln(F);
            pConc := clsConc.ElementList.Next;
        end;
    finally
        CloseFile(F);
    end;

    clsTape := DSSClassList[ActiveActor].Get(ClassNames[ActiveActor].Find('TSData'));
    pTape := clsTape.ElementList.First;
    if pTape <> NIL then
    try
        Assignfile(F, GetOutputDirectory + 'TSData.csv');
        ReWrite(F);

        Writeln(F, 'name,n_phases,n_conds,eps_r,ins_layer,dia_ins,dia_cable,dia_shield,tape_layer,tape_lap');

        while pTape <> NIL do
        begin
            pTape.DumpPropertiesCSV(F);
            Writeln(F);
            pTape := clsTape.ElementList.Next;
        end;
    finally
        CloseFile(F);
    end;
end;

end.
