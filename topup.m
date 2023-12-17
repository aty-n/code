%% runs topup for blipup blipdown acquisitions
% parts adapted from spmup code
% 17.12.2023 // atyn 

bids_dir = '/Volumes/SSD/data/cpm_add/bids';
sub_dirs = dir(fullfile(bids_dir, 'sub-*'));
sub_dirs = sub_dirs([sub_dirs.isdir]);

for i = 1:length(sub_dirs)
    subject_dir = fullfile(sub_dirs(i).folder, sub_dirs(i).name);
    func_dir = fullfile(subject_dir, 'func');
    fmap_dir = fullfile(subject_dir, 'fmap');

    bold_file = fullfile(func_dir, [sub_dirs(i).name, '_task-rest_bold.nii']);
    ap_epi_file = fullfile(fmap_dir, [sub_dirs(i).name, '_dir-AP_epi.nii']);
    pa_epi_file = fullfile(fmap_dir, [sub_dirs(i).name, '_dir-PA_epi.nii']);

    copyfile(bold_file, fmap_dir);
    system(['/Users/atyn/fsl/bin/fslroi ', bold_file, ' ', ap_epi_file, ' 0 1']);
    system(['gunzip ', ap_epi_file '.gz']);
    delete(fullfile(fmap_dir, [sub_dirs(i).name, '_task-rest_bold.nii']));

    volbup = ap_epi_file;
    volbdown = pa_epi_file;

    [fieldmap_dir, ~, ~] = fileparts(volbup);

    clear matlabbatch
    matlabbatch{1}.spm.tools.spatial.topup.data.volbup{1}   = volbup;
    matlabbatch{1}.spm.tools.spatial.topup.data.volbdown{1} = volbdown;
    matlabbatch{1}.spm.tools.spatial.topup.fwhm             = [8 4 2 1 0.1];
    matlabbatch{1}.spm.tools.spatial.topup.reg              = [0 10 100];
    matlabbatch{1}.spm.tools.spatial.topup.rinterp          = [7]; % 7th-degree spline
    matlabbatch{1}.spm.tools.spatial.topup.rt               = 1;
    matlabbatch{1}.spm.tools.spatial.topup.prefix           = 'vdm5';
    matlabbatch{1}.spm.tools.spatial.topup.outdir{1}        = fieldmap_dir;

    fprintf('running SPM topup on fmap for %s\n', sub_dirs(i).name);
    spm_jobman('run', matlabbatch);
    clear matlabbatch;
end   