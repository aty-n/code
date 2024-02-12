%% runs conn for resting state acqs with epi fieldmaps preprocessed by topup
% 17.12.2023 // atyn

%% variables
analysisname = 'mnifield_shen368_n140';
projname = 'cpm_add';
projdir = ['/Volumes/SSD/data/' projname];
bidsdir = [projdir '/bids'];
boldname = 'task-rest_bold.nii';
anatname = 'T1w.nii';
fmapname = 'dir-AP_epi.nii';
TR = 2.0;

%% env
subjectFolders = dir(fullfile(bidsdir, 'sub-*'));
NSUBJECTS = length(subjectFolders);
FUNCTIONAL_FILE = cell(NSUBJECTS, 1);
STRUCTURAL_FILE = cell(NSUBJECTS, 1);
FMAP_FILE = cell(NSUBJECTS, 1);
numSessionsPerSubject = zeros(NSUBJECTS, 1);

%% sub setup
for subID = 1:NSUBJECTS
    subjectFolderName = subjectFolders(subID).name;
    funcFiles = dir(fullfile(bidsdir, subjectFolderName, 'func', sprintf(['%s_', boldname], subjectFolderName)));
    numSessionsPerSubject(subID) = length(funcFiles);
    
    % func
    for sesID = 1:numSessionsPerSubject(subID)
        functionalFileName = sprintf(['%s_', boldname], subjectFolderName);
        functionalPath = fullfile(bidsdir, subjectFolderName, 'func', functionalFileName);
        FUNCTIONAL_FILE{subID}{sesID} = functionalPath;
    end

    % anat
    for sesID = 1:numSessionsPerSubject(subID)
        structuralFileName = sprintf(['%s_', anatname], subjectFolderName);
        structuralPath = fullfile(bidsdir, subjectFolderName, 'anat', structuralFileName);
        STRUCTURAL_FILE{subID} = structuralPath;
    end

    % fmap
    for sesID = 1:numSessionsPerSubject(subID)
        fmapFileName = sprintf(['%s_', fmapname], subjectFolderName);
        fmapPath = fullfile(bidsdir, subjectFolderName, 'fmap', ['vdm5_pos_' fmapFileName]);
        FMAP_FILE{subID} = {fmapPath};
    end
end

disp(['nsubjects: ', num2str(NSUBJECTS)]);
for subID = 1:NSUBJECTS
    disp(['sub-', num2str(subID), ': ', num2str(numSessionsPerSubject(subID)), ' ses']);
end
disp(['TR: ', num2str(TR)]);

%% batch
clear batch;
batch.filename = fullfile(['/Users/atyn/Desktop/data/mr/ing/cpm_add/analysis/' analysisname, '.mat']);         
batch.Setup.isnew = 1;
batch.Setup.nsubjects = NSUBJECTS;
batch.Setup.RT = TR;                                        
batch.Setup.functionals = FUNCTIONAL_FILE;
batch.Setup.structurals = STRUCTURAL_FILE; 
batch.Setup.secondarydatasets{1} = struct('functionals_type', 2 , 'functionals_label', 'unsmoothed');
batch.Setup.secondarydatasets{2} = struct('functionals_type', 4 , 'functionals_label', 'fmap', 'functionals_explicit', {FMAP_FILE});
 
%% rois
batch.Setup.rois.files{1} = '/Users/atyn/spm12/toolbox/conn/rois/Shen.nii';
batch.Setup.rois.multiplelabels = 1;
%batch.Setup.rois.files{2}='/Users/atyn/spm12/toolbox/conn/rois/atlas.nii';
%batch.Setup.rois.files{3}='/Users/atyn/spm12/toolbox/conn/rois/networks.nii';

%% conditions
batch.Setup.conditions.names = {'rest'};

%% preproc
batch.Setup.preprocessing.steps = 'default_mnifield';
batch.Setup.preprocessing.sliceorder = 'BIDS';
batch.Setup.done = 1;
batch.Setup.overwrite = 'Yes';

%% denoise
batch.Denoising.confounds.names = {'White Matter', 'CSF', 'Grey Matter'};
batch.Denoising.filter = [0.01, 0.1];                 
batch.Denoising.done = 1;
batch.Denoising.overwrite = 'Yes';

%% first-level
batch.Analysis.type = 1; % (1=roixroi, 2=seedxvox, 3=all)
batch.Analysis.measure = 1; % (1=correlation(bi), 2=correlation(semipart), 3=regression(bi), 4=regression(mv)
batch.Analysis.done = 1;
batch.Analysis.overwrite = 'Yes';

%% second-level
batch.Analysis.Results.done = 0;

%% save + run
save([analysisname, '.mat'], 'batch');
conn_batch(batch);
