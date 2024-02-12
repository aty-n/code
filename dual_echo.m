% combines dual-echo epi acquisitions as recommended by Halai et al. 2014. https://doi.org/10.1002/hbm.22463 
% atyn 09.01.2

baseDir = 'bidsdir';
subjects = dir(fullfile(baseDir, 'sub-*')); 

for subIdx = 1:length(subjects)
    if subjects(subIdx).isdir   
        subjectName = subjects(subIdx).name;
        funcDir = fullfile(baseDir, subjectName, 'ses-01', 'func');

        echo1 = fullfile(funcDir, [subjectName '_ses-01_task-name_acq-epi_bold_e1.nii']);
        echo2 = fullfile(funcDir, [subjectName '_ses-01_task-name_acq-epi_bold_e2.nii']);

        outputVolumes = cell(210, 1);

        if exist(echo1, 'file') && exist(echo2, 'file')
            outputVolumes = cell(210, 1);
            
        for vol = 1:210
            inputs = {[echo1, ',', num2str(vol)]; [echo2, ',', num2str(vol)]};
            outputVolumeName = fullfile(funcDir, [subjectName '_temp_volume_', num2str(vol), '.nii']);
            outputVolumes{vol} = outputVolumeName;

            matlabbatch{1}.spm.util.imcalc.input = inputs;
            matlabbatch{1}.spm.util.imcalc.output = outputVolumeName;
            matlabbatch{1}.spm.util.imcalc.expression = '(i1 + i2)/2';
            matlabbatch{1}.spm.util.imcalc.options.dmtx = 0;
            matlabbatch{1}.spm.util.imcalc.options.mask = 0;
            matlabbatch{1}.spm.util.imcalc.options.interp = 1;
            matlabbatch{1}.spm.util.imcalc.options.dtype = 4;

            spm('defaults', 'FMRI');
            spm_jobman('run', matlabbatch);
        end

        finalOutputFile = fullfile(funcDir, [subjectName '_ses-01_task-name_acq-epi_bold.nii']);
        spm_file_merge(outputVolumes, finalOutputFile);
        
        for vol = 1:AMOUNT
            delete(outputVolumes{vol});
        end
        end
    end
end
