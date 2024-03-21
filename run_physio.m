% loop physio_preproc across subjects

subjects = [id];
base_path = '/path/to/bids/';
outdir = '/path/to/derivatives/';
runmap = {'run-1', 'run-2', 'run-3', 'run-4'};

if ~exist(outdir, 'dir')
    mkdir(outdir);
end

for i = 1:length(subjects)
    subject = subjects(i);
    for j = 1:length(runmap)
        rundir = runmap{j};

        % find tsv files
        subject_path_pattern = fullfile(base_path, sprintf('sub-%d', subject), 'ses-pilot/func', rundir, sprintf('*task-smell*%s*physio.tsv', rundir));
        physiolog_files = dir(subject_path_pattern);

        for l = 1:length(physiolog_files)
            physiolog_file = physiolog_files(l);
            physiolog_path = fullfile(physiolog_file.folder, physiolog_file.name);
          
            bids_folder_path = fullfile(outdir, sprintf('sub-%d', subject), 'ses-pilot', 'func', rundir);
            if ~exist(bids_folder_path, 'dir')
                mkdir(bids_folder_path);
            end
            
            % output names
            output_mat_name = sprintf('sub-%d_ses-pilot_task-X_%s_physio_preprocessed.mat', subject, rundir);
            output_png_name = sprintf('sub-%d_ses-pilot_task-X_%s_physio_preprocessed.png', subject, rundir);

            output_mat_path = fullfile(bids_folder_path, output_mat_name);
            output_png_path = fullfile(bids_folder_path, output_png_name);

            % use physio_preproc.m
            physio_preproc(physiolog_path, output_mat_path, output_png_path);
        end
    end
end
