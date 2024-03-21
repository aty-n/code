function physio_preproc(inputFile, outputMatPath, outputFigPath)
    % read .tsv assuming first column is respiratory data
    opts = detectImportOptions(inputFile, 'FileType', 'text');
    physiotsv = readtable(inputFile, opts);
    respiratorydata = physiotsv{:, 1}; 

    offsetSamples = 400 * 12;
    respiratorydata = respiratorydata((offsetSamples + 1):end);

    % one-dimensional filter, order of 40
    filteredresp = medfilt1(respiratorydata, 40);

    % downsample to 1hz
    samplingrate = 400; 
    downsamplingFactor = samplingrate / 1; 
    downsampledResp = downsample(filteredresp, downsamplingFactor);

    % z transformation
    standardizedResp = (downsampledResp - mean(downsampledResp)) / std(downsampledResp);

    % 4 iteration filter
    n_iter = 4;
    preprocessedData = enzo(standardizedResp, n_iter);

    % find peaks with a threshold of 0.75 and min. 2 sec separation
    [pks, locs] = findpeaks(preprocessedData, 'MinPeakHeight', 0.75, 'MinPeakDistance', 2);

    % initialized output as a structure
    preprocessedResp.data = preprocessedData;
    preprocessedResp.peaks = locs;

    % save preprocessed data with peaks information
    save(outputMatPath, 'preprocessedResp');

    timevector = (1:length(respiratorydata)) / samplingrate;
    timevectorDownsampled = linspace(1, length(respiratorydata) / samplingrate, length(preprocessedData));
    figure;
    
    % plot raw
    subplot(4,1,1);
    plot(timevector, respiratorydata);
    title('raw');
    xlabel('time');
    ylabel('amplitude');

    % plot filtered
    subplot(4,1,2);
    plot(linspace(1, length(respiratorydata) / samplingrate, length(filteredresp)), filteredresp);
    title('filtered');
    xlabel('time');
    ylabel('amplitude');

    % plot downsampled
    subplot(4,1,3);
    plot(timevectorDownsampled, downsampledResp);
    title('downsampled');
    xlabel('time');
    ylabel('amplitude');

    % plot preprocessed data
    subplot(4,1,4);
    plot(timevectorDownsampled, preprocessedData);
    title('preprocessed');
    xlabel('time');
    ylabel('amplitude');

    % save plots
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
    saveas(gcf, outputFigPath);
    close(gcf); 
end

% enzo function for amplitude adjustment
function y = enzo(y, n_iter)
    p = 2; 
    for i = 1:n_iter
        y = y ./ (abs(y).^(1/p));
    end
end

