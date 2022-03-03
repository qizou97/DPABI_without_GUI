function dpabi_noGUI(Cfg_file,work_dir,StartingDirName,ROI_altas_name)

% use dpabi pipeline without GUI
% Cfg_file, work_dir , StartingDirName and ROI_atlas_name in dpabi as fuction inputs.
% Cfg_file mat file from dipabi GUI selection saving.
% if you dont do FC with ROI altas, make ROI_altas_name='', if not, make  ROI_altas_name= 'altas_name' such as 'aal.nii'
% command: matlab -nodisplay "$nojvm" -nosplash -r "dpabi_noGUI('/home/pc/fMRI/data/tmp.mat','/home/pc/fMRI/data','FunImg', 'aal.nii')" 
% kill progress command: ps -ef|grep 'matlab'|grep -v  'ii'|cut -c 9-16|xargs kill -9

    dpabi_dir = '/Users/zouqi/matlab_tools/DPABI_V6.1_220101';   %dpabi install dir，需要自行修改路径
    template_dir = [dpabi_dir,'/Templates/'];
    
    sub_dir = dir([work_dir, '/',StartingDirName]);
    log_file = [work_dir, '/log.txt'];

    [D1, ~] = size(sub_dir);
    SubjectID = cell(D1-2, 1);


    for i = 3:D1
        SubjectID{i-2} = sub_dir(i).name;
    end
    

    load(Cfg_file)
    Cfg.WorkingDir = '';
    Cfg.DataProcessDir  = '';
    Cfg.SubjectID = SubjectID;
    if Cfg.IsCalFC == 1 || Cfg.IsExtractROISignals == 1
        if size(ROI_altas_name) == 0
            disp('there is no ROI_atlas_name')
            return
        else 
            Cfg.CalFC.ROIDef = {[template_dir, ROI_altas_name]};
        end
    end
    Cfg.StartingDirName = StartingDirName;
    
    f1 = fopen(log_file,'w+');
    diary(log_file)
    diary on
    
    DPARSFA_run(Cfg,work_dir,'',0);

    fclose(f1);

    disp('Success!')
    diary off

end

