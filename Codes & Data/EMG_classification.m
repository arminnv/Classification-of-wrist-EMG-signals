fs = 200;
X = []; %Features Matrix

% Extracting features for each window
for i=1:size(data, 1)
    X = [X; extract_features(squeeze(data(i, :, :)), fs)];
end

%% Normalizing Features and Seperating Training and Test Data
% Normalizing features
X_normal = normalize(X, 1);
X_normal(:, any(isnan(X_normal),1)) = [];

% Train-test split indexes - 80% train, 20% test for each class
IDX_train = [1:int32(0.8*(start_index(2)-1)), start_index(2):start_index(2)+int32(0.8*(start_index(3)-start_index(2))),...
    start_index(3):start_index(3)+int32(0.8*(start_index(4)-start_index(3))),...
    start_index(4):start_index(4)+int32(0.8*(length(X_normal)-start_index(4)))];
IDX_test = 0:length(X_normal);
IDX_test(IDX_train) = [];

% Splitting train data
Y = y';

%% Applying KNN and RF Algorithms
% Reducing features
X_reduced = X_normal(:, 1:end);

% Splitting train and test data
X_train = X_reduced(IDX_train, :);
X_test = X_reduced(IDX_test, :);
Y_train = Y(IDX_train);
Y_test = Y(IDX_test);

% KNN classifier
Mdl_knn = fitcknn(X_train, Y_train, "NumNeighbors", 5);
% Random forest classifier
Mdl_rf = fitcensemble(X_train, Y_train,'Method','AdaBoostM2','NumLearningCycles',200,'Learners','tree');

Ypred_knn = predict(Mdl_knn, X_test);
Ypred_rf = predict(Mdl_rf, X_test);

% Test accuracy
fprintf("accuracy test knn: %d \n", (mean(Ypred_knn==Y_test)))
fprintf("accuracy train knn: %d \n", (mean(predict(Mdl_knn,X_train)==Y_train)))
fprintf("accuracy test random forest: %d \n", (mean(Ypred_rf==Y_test)))
fprintf("accuracy train random forest: %d \n", (mean(predict(Mdl_rf,X_train)==Y_train)))

% Confusion Matrix
figure
subplot(2, 1, 1)
confusionchart(Y_test, Ypred_knn)
title("KNN")
subplot(2, 1, 2)
confusionchart(Y_test, Ypred_rf)
title("Random Forest")
sgtitle("Confusion Matrix")
saveas(gcf, "Confusion Matrix.png")

function features = extract_features(X, fs)    
    n_channels = size(X, 1);
    L = size(X, 2); 
    features = [];
    
    for ch=1:n_channels
        signal = X(ch, :);

        % Mean absolute value
        mav = mean(abs(signal));

        % Zero-cross rate
        [n_cross,r] = zerocrossrate(signal,'Method','difference');

    
        % Variance of signal
        Var = var(signal);
    
        % Histogram counts using 10 bins
        [N, edges] = histcounts(signal, 10);
    
        % AR coefficients
        [a, e] = lpc(signal, 10);
    
        % Form Factor
        dif1 = diff(signal, 1); %Differentiate (order 1)
        dif2 = diff(signal, 2); %Differentiate (order 2)
        FF = (var(dif2)/var(dif1)) / (var(dif1)/var(signal));

        % Waveform Length
        wl = sum(abs(dif1));
        
        % RMS
        RMS = rms(signal);

        % Power Spectral Density
        [Pxx, f] = pwelch(signal, [], [], [], fs);
        
        % Frequency of highest peak
        f_peak = f(find(Pxx==max(Pxx)));

        % Average frequency
        f_avg = sum(Pxx.*f)/sum(Pxx);
        
        % Median frequency
        f_med = medfreq(Pxx, f);
        
        % Spectral energy of channel ch
        PSD = sum(Pxx);

        features = [features, mav, n_cross, wl, RMS, Var, N, a, FF, f_peak, f_avg, f_med, PSD];
    end
        
        % Correlation between channels
        A = corrcoef(X');
        R = reshape(tril(A, -1), 1, []);
        R(R==0) = [];
        features = [features, R];
end
