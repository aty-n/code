% preprocessing batch meant for a mixed cohort of lesion/non-lesion participants with available lesion masks 
% atyn 10.02.2024

% set environment
addpath('spm12path');
spm('defaults', 'FMRI');
spm_jobman('initcfg');

% define main directories and n subjects
bidsdir = 'bidsdir';
subdirs = dir(fullfile(bidsdir, 'sub-*'));
nSubs = numel(subdirs);

% initialize log file
log_fid = fopen('preprocessing_log.txt', 'w');
if log_fid == -1
    error('log file did not initialize.');
end

% main loop 
for s = 1:nSubs
    
    % define sth subject
    subid = subdirs(s).name;
    fprintf('processing %s\n', subid);

    % define func, anat, fmap folders
    func_dir = fullfile(bidsdir, subid, 'ses-01', 'func');
    anat_dir = fullfile(bidsdir, subid, 'ses-01', 'anat');
    fmap_dir = fullfile(bidsdir, subid, 'ses-01', 'fmap');

    % define func, anat files
    func_file = fullfile(func_dir, [subid '_ses-01_task-name_acq-epi_bold.nii']);
    anat_file = fullfile(anat_dir, [subid '_ses-01_acq-ir_T1w.nii']);
    mag_file = fullfile(fmap_dir, [subid '_ses-01_acq-epi_dir-AP_epi.nii']);
    file_fieldmaphaz = fullfile(fmap_dir, ['sc' subid '_ses-01_acq-epi_dir-AP_epi_fieldmaphz.nii']);
    file_epi_ph = fullfile(fmap_dir, ['sc' subid '_ses-01_acq-epi_dir-AP_epi_ph.nii']);

    % account for variation in fmap file names
    if exist(file_fieldmaphaz, 'file')
        phase_file = file_fieldmaphaz;
    elseif exist(file_epi_ph, 'file')
        phase_file = file_epi_ph;
    else
        phase_file = ''; % will be caught by missing_files below
    end

    % check whether files exist
    missing_files = {};    
    if ~exist(func_file, 'file')
        missing_files{end+1} = 'func_file';
    end
    if ~exist(anat_file, 'file')
        missing_files{end+1} = 'anat_file';
    end
    if ~exist(mag_file, 'file')
        missing_files{end+1} = 'mag_file';
    end
    if ~exist(phase_file, 'file')
        missing_files{end+1} = 'phase_file';
    end

    % for patients, check if lesion mask exists
    if ~startsWith(subid, 'sub-C')
        lesion_file = fullfile(anat_dir, [subid '_lesion-mask.nii']);
        if ~exist(lesion_file, 'file')
            missing_files{end+1} = 'lesion_file';
        end
    end
    
    % report missing files
    if ~isempty(missing_files)
        missing_files_str = strjoin(missing_files, ', ');
        fprintf(log_fid, '%s did not have all required files. missing: %s\n', subid, missing_files_str);
        continue;
    end

    
    % initiate single-subject preprocessing batch
    matlabbatch = {};

    matlabbatch{1}.cfg_basicio.file_dir.file_ops.cfg_named_file.name = 'func';
    matlabbatch{1}.cfg_basicio.file_dir.file_ops.cfg_named_file.files = {{func_file}};
    matlabbatch{2}.cfg_basicio.file_dir.file_ops.cfg_named_file.name = 'anat';
    matlabbatch{2}.cfg_basicio.file_dir.file_ops.cfg_named_file.files = {{anat_file}};
    matlabbatch{3}.cfg_basicio.file_dir.file_ops.cfg_named_file.name = 'magnitude';
    matlabbatch{3}.cfg_basicio.file_dir.file_ops.cfg_named_file.files = {{mag_file}};
    matlabbatch{4}.cfg_basicio.file_dir.file_ops.cfg_named_file.name = 'phase';
    matlabbatch{4}.cfg_basicio.file_dir.file_ops.cfg_named_file.files = {{phase_file}};
    
    % if control, do not define lesion file
    if startsWith(subid, 'sub-C') 

        matlabbatch{5}.cfg_basicio.file_dir.file_ops.cfg_named_file.name = 'null';
        matlabbatch{5}.cfg_basicio.file_dir.file_ops.cfg_named_file.files = {{anat_file}};
    
    % if patient, locate and select lesion file
    else 

        lesion_file = fullfile(anat_dir, [subid '_lesion-mask.nii']); % created by prepare_lesions.sh

        matlabbatch{5}.cfg_basicio.file_dir.file_ops.cfg_named_file.name = 'lesion';
        matlabbatch{5}.cfg_basicio.file_dir.file_ops.cfg_named_file.files = {{lesion_file}};
        
        % save lesion file for later use as 7th tissue class for segmentation
        matlabbatch{10}.spm.spatial.preproc.tissue(7).tpm(1) = cfg_dep('Named File Selector: lesion(1) - Files', substruct('.','val', '{}',{5}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files', '{}',{1}));
        matlabbatch{10}.spm.spatial.preproc.tissue(7).ngaus = Inf;
        matlabbatch{10}.spm.spatial.preproc.tissue(7).native = [1 0];
        matlabbatch{10}.spm.spatial.preproc.tissue(7).warped = [0 0];

    end
    
    % create voxel displacement map (vdm) for distortion correction
    % the required file has been created by running scale_hertz.m
    matlabbatch{6}.spm.tools.fieldmap.calculatevdm.subj.data.precalcfieldmap.precalcfieldmap(1) = cfg_dep('Named File Selector: phase(1) - Files', substruct('.','val', '{}',{4}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files', '{}',{1}));
    matlabbatch{6}.spm.tools.fieldmap.calculatevdm.subj.data.precalcfieldmap.magfieldmap(1) = cfg_dep('Named File Selector: magnitude(1) - Files', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files', '{}',{1}));
    matlabbatch{6}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsfile = {'code\spm12\toolbox\FieldMap\pm_defaults.m'};
    matlabbatch{6}.spm.tools.fieldmap.calculatevdm.subj.session.epi(1) = cfg_dep('Named File Selector: func(1) - Files', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files', '{}',{1}));
    matlabbatch{6}.spm.tools.fieldmap.calculatevdm.subj.matchvdm = 1;
    matlabbatch{6}.spm.tools.fieldmap.calculatevdm.subj.sessname = '1';
    matlabbatch{6}.spm.tools.fieldmap.calculatevdm.subj.writeunwarped = 0;
    matlabbatch{6}.spm.tools.fieldmap.calculatevdm.subj.anat = '';
    matlabbatch{6}.spm.tools.fieldmap.calculatevdm.subj.matchanat = 0;
   
    % realign and unwarp (using above vdm) func files
    matlabbatch{7}.spm.spatial.realignunwarp.data.scans(1) = cfg_dep('Named File Selector: func(1) - Files', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files', '{}',{1}));
    matlabbatch{7}.spm.spatial.realignunwarp.data.pmscan(1) = cfg_dep('Calculate VDM: Voxel displacement map (Subj 1, Session 1)', substruct('.','val', '{}',{6}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','vdmfile', '{}',{1}));
    matlabbatch{7}.spm.spatial.realignunwarp.eoptions.quality = 0.9;
    matlabbatch{7}.spm.spatial.realignunwarp.eoptions.sep = 4;
    matlabbatch{7}.spm.spatial.realignunwarp.eoptions.fwhm = 5;
    matlabbatch{7}.spm.spatial.realignunwarp.eoptions.rtm = 0;
    matlabbatch{7}.spm.spatial.realignunwarp.eoptions.einterp = 2;
    matlabbatch{7}.spm.spatial.realignunwarp.eoptions.ewrap = [0 0 0];
    matlabbatch{7}.spm.spatial.realignunwarp.eoptions.weight = '';
    matlabbatch{7}.spm.spatial.realignunwarp.uweoptions.basfcn = [12 12];
    matlabbatch{7}.spm.spatial.realignunwarp.uweoptions.regorder = 1;
    matlabbatch{7}.spm.spatial.realignunwarp.uweoptions.lambda = 100000;
    matlabbatch{7}.spm.spatial.realignunwarp.uweoptions.jm = 0;
    matlabbatch{7}.spm.spatial.realignunwarp.uweoptions.fot = [4 5];
    matlabbatch{7}.spm.spatial.realignunwarp.uweoptions.sot = [];
    matlabbatch{7}.spm.spatial.realignunwarp.uweoptions.uwfwhm = 4;
    matlabbatch{7}.spm.spatial.realignunwarp.uweoptions.rem = 1;
    matlabbatch{7}.spm.spatial.realignunwarp.uweoptions.noi = 5;
    matlabbatch{7}.spm.spatial.realignunwarp.uweoptions.expround = 'Average';
    matlabbatch{7}.spm.spatial.realignunwarp.uwroptions.uwwhich = [2 1];
    matlabbatch{7}.spm.spatial.realignunwarp.uwroptions.rinterp = 4;
    matlabbatch{7}.spm.spatial.realignunwarp.uwroptions.wrap = [0 0 0];
    matlabbatch{7}.spm.spatial.realignunwarp.uwroptions.mask = 1;
    matlabbatch{7}.spm.spatial.realignunwarp.uwroptions.prefix = 'u';
   
    % slice-timing correction 
    % required information appended to json files by slice_timing.m
    matlabbatch{8}.spm.temporal.st.scans{1}(1) = cfg_dep('Realign & Unwarp: Unwarped Images (Sess 1)', substruct('.','val', '{}',{7}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','sess', '()',{1}, '.','uwrfiles'));
    matlabbatch{8}.spm.temporal.st.nslices = 31;
    matlabbatch{8}.spm.temporal.st.tr = 2.8;
    matlabbatch{8}.spm.temporal.st.ta = 2.70967741935484;
    matlabbatch{8}.spm.temporal.st.so = [1 3 5 7 9 11 13 15 17 19 21 23 25 27 29 31 2 4 6 8 10 12 14 16 18 20 22 24 26 28 30];
    matlabbatch{8}.spm.temporal.st.refslice = 1;
    matlabbatch{8}.spm.temporal.st.prefix = 'a';
   
    % coregister anat and (unwarped) func
    matlabbatch{9}.spm.spatial.coreg.estwrite.ref(1) = cfg_dep('Realign & Unwarp: Unwarped Mean Image', substruct('.','val', '{}',{7}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','meanuwr'));
    matlabbatch{9}.spm.spatial.coreg.estwrite.source(1) = cfg_dep('Named File Selector: anat(1) - Files', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files', '{}',{1}));
    matlabbatch{9}.spm.spatial.coreg.estwrite.other = {''};
    matlabbatch{9}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
    matlabbatch{9}.spm.spatial.coreg.estwrite.eoptions.sep = [4 2];
    matlabbatch{9}.spm.spatial.coreg.estwrite.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
    matlabbatch{9}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7];
    matlabbatch{9}.spm.spatial.coreg.estwrite.roptions.interp = 4;
    matlabbatch{9}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0];
    matlabbatch{9}.spm.spatial.coreg.estwrite.roptions.mask = 0;
    matlabbatch{9}.spm.spatial.coreg.estwrite.roptions.prefix = 'r';
   
    % segment anat using k=6 tissue types (=7 for patients)
    % required lesion resampling to mni space done by prepare_lesions.sh
    matlabbatch{10}.spm.spatial.preproc.channel.vols(1) = cfg_dep('Coregister: Estimate & Reslice: Coregistered Images', substruct('.','val', '{}',{9}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','cfiles'));
    matlabbatch{10}.spm.spatial.preproc.channel.biasreg = 0.001;
    matlabbatch{10}.spm.spatial.preproc.channel.biasfwhm = 60;
    matlabbatch{10}.spm.spatial.preproc.channel.write = [0 1];
    matlabbatch{10}.spm.spatial.preproc.tissue(1).tpm = {'code\spm12\tpm\TPM.nii,1'};
    matlabbatch{10}.spm.spatial.preproc.tissue(1).ngaus = 1;
    matlabbatch{10}.spm.spatial.preproc.tissue(1).native = [1 0];
    matlabbatch{10}.spm.spatial.preproc.tissue(1).warped = [0 0];
    matlabbatch{10}.spm.spatial.preproc.tissue(2).tpm = {'code\spm12\tpm\TPM.nii,2'};
    matlabbatch{10}.spm.spatial.preproc.tissue(2).ngaus = 1;
    matlabbatch{10}.spm.spatial.preproc.tissue(2).native = [1 0];
    matlabbatch{10}.spm.spatial.preproc.tissue(2).warped = [0 0];
    matlabbatch{10}.spm.spatial.preproc.tissue(3).tpm = {'code\spm12\tpm\TPM.nii,3'};
    matlabbatch{10}.spm.spatial.preproc.tissue(3).ngaus = 2;
    matlabbatch{10}.spm.spatial.preproc.tissue(3).native = [1 0];
    matlabbatch{10}.spm.spatial.preproc.tissue(3).warped = [0 0];
    matlabbatch{10}.spm.spatial.preproc.tissue(4).tpm = {'code\spm12\tpm\TPM.nii,4'};
    matlabbatch{10}.spm.spatial.preproc.tissue(4).ngaus = 3;
    matlabbatch{10}.spm.spatial.preproc.tissue(4).native = [1 0];
    matlabbatch{10}.spm.spatial.preproc.tissue(4).warped = [0 0];
    matlabbatch{10}.spm.spatial.preproc.tissue(5).tpm = {'code\spm12\tpm\TPM.nii,5'};
    matlabbatch{10}.spm.spatial.preproc.tissue(5).ngaus = 4;
    matlabbatch{10}.spm.spatial.preproc.tissue(5).native = [1 0];
    matlabbatch{10}.spm.spatial.preproc.tissue(5).warped = [0 0];
    matlabbatch{10}.spm.spatial.preproc.tissue(6).tpm = {'code\spm12\tpm\TPM.nii,6'};
    matlabbatch{10}.spm.spatial.preproc.tissue(6).ngaus = 2;
    matlabbatch{10}.spm.spatial.preproc.tissue(6).native = [0 0];
    matlabbatch{10}.spm.spatial.preproc.tissue(6).warped = [0 0];
    matlabbatch{10}.spm.spatial.preproc.warp.mrf = 1;
    matlabbatch{10}.spm.spatial.preproc.warp.cleanup = 1;
    matlabbatch{10}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
    matlabbatch{10}.spm.spatial.preproc.warp.affreg = 'mni';
    matlabbatch{10}.spm.spatial.preproc.warp.fwhm = 0;
    matlabbatch{10}.spm.spatial.preproc.warp.samp = 3;
    matlabbatch{10}.spm.spatial.preproc.warp.write = [0 1];
    matlabbatch{10}.spm.spatial.preproc.warp.vox = NaN;
    matlabbatch{10}.spm.spatial.preproc.warp.bb = [NaN NaN NaN
                                               NaN NaN NaN];
    
    % normalize func to mni space using deformation parameters from above
    matlabbatch{11}.spm.spatial.normalise.write.subj.def(1) = cfg_dep('Segment: Forward Deformations', substruct('.','val', '{}',{10}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','fordef', '()',{':'}));
    matlabbatch{11}.spm.spatial.normalise.write.subj.resample(1) = cfg_dep('Slice Timing: Slice Timing Corr. Images (Sess 1)', substruct('.','val', '{}',{8}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','files'));
    matlabbatch{11}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70
                                                           78 76 85];
    matlabbatch{11}.spm.spatial.normalise.write.woptions.vox = [2 2 2];
    matlabbatch{11}.spm.spatial.normalise.write.woptions.interp = 7;
    matlabbatch{11}.spm.spatial.normalise.write.woptions.prefix = 'w';
   
    % smooth func files with gaussian full-width half-maximum = (n)mm
    matlabbatch{12}.spm.spatial.smooth.data(1) = cfg_dep('Normalise: Write: Normalised Images (Subj 1)', substruct('.','val', '{}',{11}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','files'));
    matlabbatch{12}.spm.spatial.smooth.fwhm = [6 6 6]; % (n)
    matlabbatch{12}.spm.spatial.smooth.dtype = 0;
    matlabbatch{12}.spm.spatial.smooth.im = 0;
    matlabbatch{12}.spm.spatial.smooth.prefix = 's';
    
    % attempt subject and append log file accordingly
    try
        spm_jobman('run', matlabbatch);
        fprintf(log_fid, '%s completed successfully.\n', subid);
    catch ME
        fprintf(log_fid, '%s failed: %s\n', subid, ME.message);
    end
    
end

% end log file
fclose(log_fid); 
