% scales philips acquisition (Hz) fieldmap files to rads for use in spm12 vdm-calculation
% atyn 07.02.2024

bidspath = 'bidsdir';

subjectDirs = dir(fullfile(bidspath, 'sub-*'));

for i = 1:length(subjectDirs)
    subjectDir = fullfile(bidspath, subjectDirs(i).name);
    sessionDir = fullfile(subjectDir, 'ses-01', 'fmap');
    
    fieldMapFile = fullfile(sessionDir, sprintf('%s_ses-01_acq-epi_dir-AP_epi_fieldmaphz.nii', subjectDirs(i).name));
    
    if exist(fieldMapFile, 'file')

        V = spm_vol(fieldMapFile);
        vol = spm_read_vols(V);
        mn = min(vol(:));
        mx = max(vol(:));
        vol = -pi + (vol - mn) * 2 * pi / (mx - mn);
        V.dt(1) = 4; 
      
        varargout{1} = FieldMap('Write', V, vol, 'sc', V.dt(1), V.descrip);
    else
        fprintf('fmap does not exist for %s\n', subjectDirs(i).name);
    end
end
