% setup
projdir = '/path/to/project';
bidsdir = fullfile(projdir, 'derivatives');
tasks = {'task1', 'task2', 'task3'};
sessions = {'ses-01', 'ses-02', 'ses-BL', 'ses-FU'};
projects = {'Bidsproject1', 'Bidsproject2', 'Bidsproject3'};
subfolders = dir(fullfile(bidsdir, 'sub-*'));
csvname = fullfile(codedir, 'log_volumes.csv');
NSUBJECTS = length(subfolders);

% read ID list 
idListFile = 'docs/ID_list.xlsx';
idList = readtable(idListFile);

projrows = contains(idList.Path, 'sub-');
subIDs = regexp(idList.Path(projrows), 'sub-(\d+)', 'tokens', 'once');
subIDs = cellfun(@(x) x{1}, subIDs, 'UniformOutput', false);
projpersubject = idList.Project(projrows);

subjectToProjectMap = containers.Map(subIDs, projpersubject);

FUNC_FILE = cell(NSUBJECTS, 1);
ANAT_FILE = cell(NSUBJECTS, 1);

allData = cell(0, 6); 

for subID = 1:NSUBJECTS
    % retrieve the name of the current subject folder
    subjectFolderName = subfolders(subID).name;  
    
    currentProject = '';
    foundProject = false;
    
    for i = 1:height(idList)
        path = idList.Path{i};
        if contains(path, subjectFolderName)
            for pj = 1:length(projects)
                if contains(path, projects{pj})
                % define current project
                    currentProject = projects{pj};
                    foundProject = true;
                    break; 
                end
            end
        end
        if foundProject
            break;  
        end
    end

    if ~foundProject
        disp(['no project match found for subject: ' subjectFolderName]);
    else
    end

    actualSessions = {};

    for i = 1:length(sessions)
        sessionName = sessions{i};
        if isempty(sessionName)
            sessionPath = fullfile(bidsdir, subjectFolderName, 'func');
        else
            sessionPath = fullfile(bidsdir, subjectFolderName, sessionName, 'func');
        end
        if exist(sessionPath, 'dir')
        % list identified sessions
            actualSessions{end+1} = sessionName; 
        end
    end

    for sessIdx = 1:numel(actualSessions)
        sessionName = actualSessions{sessIdx};

        for taskIdx = 1:length(tasks)
            taskName = tasks{taskIdx};
            % search for func files according to task
            if isempty(sessionName)
                funcPattern = fullfile(bidsdir, subjectFolderName, 'func', 'run*', ['sub*' taskName '*IXI549*_bold.nii']); 
            else
                funcPattern = fullfile(bidsdir, subjectFolderName, sessionName, 'func', 'run*', ['sub*' taskName '*IXI549*_bold.nii']); 
            end
            funcFiles = dir(funcPattern);

            for fIdx = 1:length(funcFiles)
                funcFullPath = fullfile(funcFiles(fIdx).folder, funcFiles(fIdx).name);
                try
                % read number of volumes using MRIread
                    bolddata = MRIread(funcFullPath);
                    numVolumes = size(bolddata.vol, 4);
                catch
                    warning(['failed to read MRI data for: ' funcFullPath]); 
                    numVolumes = NaN;
                end

                fileinfo = dir(funcFullPath);
                filemb = fileinfo.bytes / (1024^2); % calculate file size in megabytes

            allData(end+1, :) = {subjectFolderName, currentProject, sessionName, taskName, numVolumes, filemb};
            end
        end
    end
end

% write variables to csv
datatable = cell2table(allData, 'VariableNames', {'SubjectID', 'Project', 'Session', 'Task', 'Volumes', 'filemb'});
writetable(datatable, csvname); 

disp(['data written to: ' csvname]); 

