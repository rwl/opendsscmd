unit ExportCSV;

interface

procedure ExportCKV(FileNm: String);
procedure ExportDSSClassCKV(ClassName: String; FileHeader: String);

implementation

uses
    uComplex,
    Arraydef,
    Sysutils,
    DSSClass,
    DSSClassDefs,
    DSSGlobals,
    Circuit,
    Bus,
    Line,
    Utilities,
    CktElement,
    Transformer,
    LoadShape;

procedure ExportDSSClassCKV(ClassName: String; FileHeader: String);
var
    F: TextFile;

    pCls: TDSSClass;
    pElem: TDSSCktElement;
    pLine: TLine;

begin
    if (ClassName = 'Switch') then
        pCls := DSSClassList[ActiveActor].Get(ClassNames[ActiveActor].Find('Line'))
    else begin
        pCls := DSSClassList[ActiveActor].Get(ClassNames[ActiveActor].Find(ClassName));
    end;
    pElem := pCls.ElementList.First;
    if pElem <> NIL then
    try
        Assignfile(F, GetOutputDirectory + ClassName + '.csv');
        ReWrite(F);

        Writeln(F, FileHeader);

        while pElem <> NIL do
        begin
            if (ClassName = 'LoadShape') and (pElem.Name = 'default') then
            else begin
                if (ClassName = 'Switch') and (not TLineObj(pElem).IsSwitch) then begin
                  pElem := pCls.ElementList.Next;
                  continue;
                end;
                if (ClassName = 'Line') and TLineObj(pElem).IsSwitch then begin 
                  pElem := pCls.ElementList.Next;
                  continue;
                end;
                // if (ClassName = 'Switch') then
                //     if not TLine(pElem).IsSwitch then continue;
                // else if (ClassName = 'Line') then
                //     if TLine(pElem).IsSwitch then continue;
                // if (ClassName = 'Switch') then begin
                //     pLine = pElem;
                //     if not pLine.IsSwitch then continue;
                // if (ClassName = 'Line') then begin
                //     pLine = pElem;
                //     if pLine.IsSwitch then continue;
                // end
                pElem.DumpPropertiesCSV(F);
                Writeln(F);
            end;
            pElem := pCls.ElementList.Next;
        end;
    finally
        CloseFile(F);
    end;
end;


procedure ExportCKV(FileNm: String);

{Exports  properties for all  Circuit Elements}

var
    F: TextFile;
    i: Integer;
    BusName: String;
    LoadShapeDir: String;
    CktElemHeader: String;
    CoordDefined: Boolean;

    pElem: TDSSCktElement;

    pXf: TTransfObj;
    pBus: TDSSbus;
    clsShape: TLoadShape;
    pShape: TLoadShapeObj;

begin

    if ActiveCircuit[ActiveActor] = NIL then
        Exit;

    CktElemHeader := 'name,enabled,n_phases,n_conds,base_freq';

    ExportDSSClassCKV('VSource', CktElemHeader + ',terminal1,terminal2,base_kv,per_unit,angle,src_frequency,z_spec_type,mva_sc3,mva_sc1,i_sc3,i_sc1,r1,x1,r2,x2,r0,x0,x1r1,x0r0,scan_type,sequence_type,spectrum');
    ExportDSSClassCKV('ISource', CktElemHeader + ',terminal1,terminal2,amps,angle,src_frequency,spectrum');
    ExportDSSClassCKV('Load', CktElemHeader + ',terminal1,kv,kw,kvar,kva,pf,model,vmin_pu,vmax_pu,r_neut,x_neut,connection,spec_type,status,yearly,daily,duty,spectrum');
    ExportDSSClassCKV('Generator', CktElemHeader + ',terminal,kv,kw,pf,model,connection,duty,fixed,v_min_pu,v_max_pu,max_kvar,min_kvar,balanced,spectrum');

    ExportDSSClassCKV('Capacitor', CktElemHeader + ',terminal1,terminal2,connection,num_steps,spec_type,kvar,kv,c,r,xl');
    ExportDSSClassCKV('Reactor', CktElemHeader + ',terminal1,terminal2,connection,spec_type,kvar,kv,r,x');
    ExportDSSClassCKV('Line', CktElemHeader + ',terminal1,terminal2,length,units,switch,line_code,geometry');
    ExportDSSClassCKV('Switch', CktElemHeader + ',terminal1,terminal2,length,units,switch,line_code,geometry');
    ExportDSSClassCKV('Transformer', CktElemHeader + ',x_hl,x_ht,x_lt,pct_load_loss,ppm_anti_float');

    ExportDSSClassCKV('RegControl', 'transformer,winding,v_reg,bandwidth,pt_ratio,ct_rating,r,x,bus,bus_node,delay,v_limit,max_tap_change,pt_phase,remote_pt_ratio');
    ExportDSSClassCKV('CapControl', 'capacitor,element,terminal,control_type,pt_ratio,ct_ratio,off_setting,on_setting,delay,dead_time,ct_phase,pt_phase,pct_min_kvar');

    ExportDSSClassCKV('LineCode', 'name,n_phases,r1,x1,r0,x0,c1,c0,units,r_matrix,x_matrix,c_matrix,rg,xg,rho,symmetrical_components');
    ExportDSSClassCKV('LineGeometry', 'name,n_phases,n_conds,reduce,rho_earth,x_coords,heights,units,spacing,wires,cn_cables,ts_cables');
    ExportDSSClassCKV('LineSpacing', 'name,n_phases,n_conds,x_coords,heights,units');
    ExportDSSClassCKV('WireData', 'name,r,r_dc,r_units,gmr,gmr_units,radius,radius_units,normal_amps,emergency_amps');
    ExportDSSClassCKV('CNData', 'name,n_phases,n_conds,eps_r,ins_layer,dia_ins,dia_cable,k_strand,dia_strand,gmr_strand,r_strand');
    ExportDSSClassCKV('TSData', 'name,n_phases,n_conds,eps_r,ins_layer,dia_ins,dia_cable,dia_shield,tape_layer,tape_lap');
    ExportDSSClassCKV('LoadShape', 'name,n_pts,interval,mean,std_dev,use_actual');

    ExportDSSClassCKV('Monitor', 'name,enabled,element,terminal,value,sequence,magnitude,pos_seq,residual,p_polar');
    ExportDSSClassCKV('EnergyMeter', 'name,enabled,element,terminal,excess,radial,voltage_only,kva_normal,kva_emerg,peak_currents');

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

    with ActiveCircuit[ActiveActor] do
    begin
        CoordDefined := False;
        for i := 1 to NumBuses do
            if Buses^[i].CoordDefined then
            begin
                CoordDefined := True;
                break;
            end;

        if CoordDefined then
        try
            Assignfile(F, GetOutputDirectory + 'Bus.csv');
            ReWrite(F);

            Writeln(F, 'name,x,y');

            for i := 1 to NumBuses do
            begin
                pBus := Buses^[i];
                Writeln(F, Format('%s,%.16g,%.16g', [BusList.Get(i), pBus.x, pBus.y]));
            end;
        finally
            CloseFile(F);
        end;
    end;

    LoadShapeDir := GetOutputDirectory + 'LoadShape' + PathDelim;
    clsShape := DSSClassList[ActiveActor].Get(ClassNames[ActiveActor].Find('loadshape'));
    pShape := clsShape.ElementList.First;
    while pShape <> NIL do
    begin
        if pShape.Name = 'default' then
        begin
            pShape := clsShape.ElementList.Next;
            continue;
        end;
        try
            if not DirectoryExists(LoadShapeDir) then CreateDir(LoadShapeDir);
            Assignfile(F, LoadShapeDir + pShape.Name + '.csv');
            ReWrite(F);

            Write(F, 'mult');
            if pShape.Hours <> NIL then Write(F, ',hours');
            if Assigned(pShape.QMultipliers) then Write(F, ',q_mult');
            Writeln(F);

            for i := 1 to pShape.NumPoints do
            begin
                Write(F, Format('%.16g', [pShape.PMultipliers[i]]));
                if pShape.Hours <> NIL then
                    Write(F, Format('%.16g', [pShape.Hours[i]]));
                if Assigned(pShape.QMultipliers) then
                    Write(F, Format('%.16g', [pShape.QMultipliers[i]]));
                Writeln(F);
            end;
        finally
            CloseFile(F);
            pShape := clsShape.ElementList.Next;
        end;
    end;
end;

end.
