% this algorithm localise and classify rupture events
% it takes the files saved with AFM1_contactpoint.m as input and 
% give as output arrays containing cytoskeleton-anchored and rupture events
% [distance from contact point; rupture force; calculated slope; dataID]
% for each rupture event

% 0_ INPUT
% here information about the experiment need to be entered
input_folder = 'D:\SHEFFIELD\WORK\AFM'; % where are data files?
% what is the working folder for Matlab?
working_folder = 'D:\SHEFFIELD\WORK\Matlab';
% threshold for ruputre event classification
threshold_csk = -0.311; % if slope lower then this -> csk [pN/nm]
threshold_tet = 0.308; % if slope lower than this but higher than threshold_csk -> tet [pN/nm]

% 1_ open folder and list files
data_folder = cd (input_folder);
D = dir('*.txt');	% make a file list (D) of the (.txt) data in data_folder
[~,index] = sortrows({D.date}.'); D = D(index); clear index     % order data by acquisition time
D_cell = struct2cell(D); D_cell_filename = D_cell(1,:)';	% create cell array of strings with file-names

% 2_ initialise counters
k = 1; q = 1;

% 3_ FOR cycle which opens one file at the time and perform post-processing steps
for i = 1:size(D_cell_filename,1)   
    
    % 3a_ open file
    cd (input_folder);
    myfilename = D_cell_filename{i};
    fileID = fopen(myfilename);
    C = textscan(fileID, '%f%f%f%f', 'CommentStyle', '#');	% raw files contain 4 columns
    mydata = cell2mat(C);	% save data of file(i) into matrix mydata
    fclose(fileID);
    cd (working_folder)
    
    % 3b_ save data from file into arrays
    height = mydata(:,1);	% cantilever height [nm]
    force = mydata(:,2)*1E3;	% vertical deflection [pN]
    series = mydata(:,3);       % time [s]
    segment = mydata(:,4);      % time for extend/retract [s]
    
    segment_start = zeros(4,1);
    jj = 1;
    for ii = 1:length(segment)-1
        if segment(ii)-segment(ii+1) > 0.1
            segment_start(jj,1) = (ii+1);	% index of [segment] change from extend to retract
            jj = jj+1;
        end
    end
    
    % extend (E) data
    force_E = force(1:segment_start(1)-1);
    height_E = height(1:segment_start(1)-1);
    series_E = series(1:segment_start(1)-1);
    segment_E = segment(1:segment_start(1)-1);
    % retract (R) data
    force_R = force(segment_start(1):end);
    height_R = height(segment_start(1):end);
    series_R = series(segment_start(1):end);
    segment_R = segment(segment_start(1):end);
    
    % 3c_ data smoothing    
    [xData, yData] = prepareCurveData(height_R, force_R);
    ft = fittype('smoothingspline');
    opts = fitoptions('Method', 'SmoothingSpline');
    opts.SmoothingParam = 0.001;
    [fitSPLINE, gofSPLINE] = fit(xData, yData, ft, opts);
    
    % 3d_ differenitate to find peaks
    find_peak = 0;
    peak_x = 0;
    der1 = differentiate(fitSPLINE, height_R);
    find_peak = find(der1>10^(-3)); % threshold
    
    % 3e_ localise peaks
    peak_x = height_R(find_peak);
    
    separate_peaks = 0;
    if length(find_peak) > 1
        % more than one value will be saved for each peak
        % discern between contribution of different peaks
        separate_peaks(1)=1;
        jj = 2;
        for j = 2:length(peak_x)
            if peak_x(j) - peak_x(j-1) > 10
                separate_peaks(jj) = j; % vector containing peak separation indeces
                jj = jj+1;
            end
        end
        separate_peaks(jj) = length(peak_x)+1;
        
        % due to smoothing and derivation the actual peak might not be exactly
        % were der peak is
        % search for LOCAL MINIMA
        pk = 0;
        vector = 0;
        limit1 = 0;
        limit2 = 0;
        search = 0;
        peak_index = 0;
        for j = 2:length(separate_peaks)
            pk = separate_peaks(j-1):separate_peaks(j)-1;
            vector = find_peak(pk);
            if vector(end) < 1019
                limit1 = vector(1)-5;
                limit2 = vector(end)+5;
                search = min(force_R(limit1:limit2));
                peak_index(j-1) = find(force_R == search); % vector containing indeces of local minima - peaks
            end
        end
        
        % 3f_ classify peaks
        angle_PRE = 0; % [pN/nm]
        for j = 1:length(peak_index)
            
            if peak_index(j) > 100
                % csk anchored or tether?
                h_pre = height_else((peak_index(j)-50):(peak_index(j))); % fit 50 nm pre-jump
                F_pre = force_else((peak_index(j)-50):(peak_index(j))); % [pN]
                
                ft = fittype('poly1');
                [fitPRE, gofPRE] = fit(h_pre,F_pre,ft);
                fitPRE_coeff = coeffvalues(fitPRE);
                angle_PRE = fitPRE_coeff(1); % [pN/nm]
                
                if angle_PRE < threshold_csk % csk anchored rupture
                    csk(k,1) = height_else(peak_index(j));  % [nm]
                    csk(k,2) = force_else(peak_index(j));   % [pN]
                    csk(k,3) = angle_PRE;                   % [pN/nm]
                    csk(k,4) = i;
                    k = k+1;
                    
                elseif angle_PRE > threshold_csk && angle_PRE < threshold_tet % membrane tether extraction
                    tet(q,1) = height_else(peak_index(j));  % [nm]
                    tet(q,2) = force_else(peak_index(j));   % [pN]
                    tet(q,3) = angle_PRE;                   % [pN/nm]
                    tet(q,4) = i;
                    q = q+1;
                    
                    
                end
            end
        end
        
        
    end
end



