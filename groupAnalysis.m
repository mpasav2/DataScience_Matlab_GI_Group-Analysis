%% Combine data
clear; clc;
load('allSubjects.mat', 'params')
params.step_new = {'normal','max'}; % 'max' convention, instead of 'long'

%% Select variables to analyze
% Extract only the variables of interest and reorganize w.r.t. conditions

musind = 1:4; % Gmed, Gmed, Adl, Adl
muslist = params.musname(musind,:); % muscles

varlist = {'HipAngle','HipAngle','HipMoment','HipMoment'}; % mocap variable
dofind = [1,2,1,2]; % index for the DoF of interest, for the corresponding variable
varnames = {'HEFang','HABDang','HEFmom','HABDmom'}; % name for the DoF of interest, for the corresponding variable

% Define baseline period (first 100 frames)
baseline_period = 1:150;

for sub=1:length(params.sublist)
    subnum = params.sublist{sub};
    load('allSubjects.mat', subnum)
    eval(['subData = ' params.sublist{sub} ';']) % subject data struct
    subData(strcmp({subData.Exo},'base')) = []; % remove baseline trials
    clear(params.sublist{sub}) % clear for memory

    switch subData(1).Leg % depending on the stepping leg
        case 'right'
            StepLeg = 'R'; StandLeg = 'L';
        case 'left'
            StepLeg = 'L'; StandLeg = 'R';
    end
    for ee=1:length(params.exo)
        for ss = 1:length(params.step_new)
            Data(length(params.exo)*(ee-1) + ss).Exo = params.exo{ee};
            Data(length(params.exo)*(ee-1) + ss).Step = params.step_new{ss};
            trial_ind = [];
            trial_ind = find(strcmp({subData.Exo},params.exo{ee}) & strcmp({subData.Step},params.step_new{ss}));
            emg_step = []; emg_stand = []; mot_step = []; mot_stand = [];
            for tt=1:length(trial_ind)
                for mm = 1:length(muslist)
                    eval(['emg_step(mm,tt,:) = subData(trial_ind(tt)).' StepLeg 'EMGsmooth(musind(mm),:);'])
                    eval(['emg_stand(mm,tt,:) = subData(trial_ind(tt)).' StandLeg 'EMGsmooth(musind(mm),:);'])
                    if tt==length(trial_ind)
                        eval(['Data(length(params.exo)*(ee-1) + ss).StepLeg.' muslist{mm} ' = squeeze(emg_step(mm,:,:));'])
                        eval(['Data(length(params.exo)*(ee-1) + ss).StandLeg.' muslist{mm} ' = squeeze(emg_stand(mm,:,:));'])
                    end
                end
                
                for vv=1:length(varlist)
                    % Baseline correction
                    eval(['mot_step(vv,tt,:) = subData(trial_ind(tt)).' StepLeg varlist{vv} '(dofind(vv),:) - mean(subData(trial_ind(tt)).' StepLeg varlist{vv} '(dofind(vv),baseline_period), 2);'])
                    eval(['mot_stand(vv,tt,:) = subData(trial_ind(tt)).' StandLeg varlist{vv} '(dofind(vv),:) - mean(subData(trial_ind(tt)).' StandLeg varlist{vv} '(dofind(vv),baseline_period), 2);'])
                    if tt==length(trial_ind)
                        eval(['Data(length(params.exo)*(ee-1) + ss).StepLeg.' varnames{vv} ' = squeeze(mot_step(vv,:,:));'])
                        eval(['Data(length(params.exo)*(ee-1) + ss).StandLeg.' varnames{vv} ' = squeeze(mot_stand(vv,:,:));'])
                    end
                end
            end
        end
    end
    eval([params.sublist{sub}, 're = Data;'])
    clear Data subData
end
clearvars -except -regexp params ^C0 ^S0

%% Plot
%close all;

% Color scheme
Colors = [0, 84/255, 147/255; ...    % noexo normal
        83/255, 27/255, 147/255; ...    % noexo long
        255/255, 147/255, 0; ...    % exo normal
        148/255, 17/255, 0];       % exo long

timevector = (1:500)/100 - 2.5; % with onset being the zero; can modify
time_offset = 3; % offset for plotting


%% Sagittal plane
subData = S02re;
figure; % 
for cc=1:size(subData,2)
    if cc<3 % noexo conditions
        time = timevector;
    else
        time = timevector + timevector(end) + time_offset;
    end
    % Standing leg
    subplot(4,2,1)  % Hip EF angle
    var = subData(cc).StandLeg.HEFang;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 8.5])
        xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        xticklabels({'','','','','',''})
        title('Standing Leg')
        ylabel('HEF Angle')
    end

    subplot(4,2,3)  % Hip EF moment
    var = subData(cc).StandLeg.HEFmom;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 8.5])
        xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        xticklabels({'','','','','',''})
        ylabel('HEF Moment')
    end    
    
    subplot(4,2,5)  % EMG Gmax
    var = subData(cc).StandLeg.Gmax;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 8.5])
        xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        xticklabels({'','','','','',''})
        ylabel('EMG Gmax (%)')
    end    

    subplot(4,2,7)  % EMG RF
    var = subData(cc).StandLeg.RF;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 8.5])
        xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        xticklabels({'','','','','',''})
        ylabel('EMG RF (%)')
    end  


    % Stepping leg
    subplot(4,2,2)  % Hip EF angle
    var = subData(cc).StepLeg.HEFang;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 8.5])
        xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        xticklabels({'','','','','',''})
        title('Stepping Leg')
    end

    subplot(4,2,4)  % Hip EF moment
    var = -subData(cc).StepLeg.HEFmom;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 8.5])
        xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        xticklabels({'','','','','',''})
    end
    subplot(4,2,6)  % Hip EF muscles
    var = subData(cc).StepLeg.Gmax;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 8.5])
        xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        xticklabels({'','','','','',''})
    end   

    subplot(4,2,8)  % EMG RF
    var = subData(cc).StepLeg.RF;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 8.5])
        xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        xticklabels({'','','','','',''})
    end  
end


% Frontal plane
figure; % 
for cc=1:size(subData,2)
    if cc<3 % noexo conditions
        time = timevector;
    else
        time = timevector + timevector(end) + time_offset;
    end
    % Standing leg
    subplot(4,2,1)  % Hip ABD angle
    var = subData(cc).StandLeg.HABDang;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 8.5])
        xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        xticklabels({'','','','','',''})
        title('Standing Leg')
        ylabel('HABD Angle')
    end

    subplot(4,2,3)  % Hip ABD moment
    var = subData(cc).StandLeg.HABDmom;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 8.5])
        xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        xticklabels({'','','','','',''})
        ylabel('HABD Moment')
    end    
    
    subplot(4,2,5)  % EMG Gmed
    var = subData(cc).StandLeg.Gmed;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 8.5])
        xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        xticklabels({'','','','','',''})
        ylabel('EMG Gmed (%)')
    end    

    subplot(4,2,7)  % EMG Adl
    var = subData(cc).StandLeg.Adl;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 8.5])
        xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        xticklabels({'','','','','',''})
        ylabel('EMG Adl (%)')
    end  


    % Stepping leg
    subplot(4,2,2)  % Hip ABD angle
    var = subData(cc).StepLeg.HABDang;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 8.5])
        xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        xticklabels({'','','','','',''})
        title('Stepping Leg')
    end

    subplot(4,2,4)  % Hip ABD moment
    var = subData(cc).StepLeg.HABDmom;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 8.5])
        xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        xticklabels({'','','','','',''})
    end
    subplot(4,2,6)  % Hip ABD muscles
    var = subData(cc).StepLeg.Gmed;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 8.5])
        xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        xticklabels({'','','','','',''})
    end   

    subplot(4,2,8)  % EMG Adl
    var = subData(cc).StepLeg.Adl;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 8.5])
        xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        xticklabels({'','','','','',''})
    end  
end

%% Data extraction

%% Sagittal plane
subData = S02re;
figure; % 
for cc=1:size(subData,2)
    %if cc<3 % noexo conditions
        time = timevector;
    %else
        %time = timevector + timevector(end) + time_offset;
    %end
    % Standing leg
    subplot(4,2,1)  % Hip EF angle
    var = subData(cc).StandLeg.HEFang;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 3])
        %xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        %xticklabels({'','','','','',''})
        title('Standing Leg')
        ylabel('HEF Angle')
    end

    subplot(4,2,3)  % Hip EF moment
    var = subData(cc).StandLeg.HEFmom;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 3])
        %xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        %xticklabels({'','','','','',''})
        ylabel('HEF Moment')
    end    
    
    subplot(4,2,5)  % EMG Gmax
    var = subData(cc).StandLeg.Gmax;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 3])
        %xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        %xticklabels({'','','','','',''})
        ylabel('EMG Gmax (%)')
    end    

    subplot(4,2,7)  % EMG RF
    var = subData(cc).StandLeg.RF;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 3])
        %xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        %xticklabels({'','','','','',''})
        ylabel('EMG RF (%)')
    end  


    % Stepping leg
    subplot(4,2,2)  % Hip EF angle
    var = subData(cc).StepLeg.HEFang;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 3])
        %xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        %xticklabels({'','','','','',''})
        title('Stepping Leg')
    end

    subplot(4,2,4)  % Hip EF moment
    var = -subData(cc).StepLeg.HEFmom;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 3])
        %xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        %xticklabels({'','','','','',''})
    end
    subplot(4,2,6)  % Hip EF muscles
    var = subData(cc).StepLeg.Gmax;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 3])
        %xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        %xticklabels({'','','','','',''})
    end   

    subplot(4,2,8)  % EMG RF
    var = subData(cc).StepLeg.RF;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 3])
        %xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        %xticklabels({'','','','','',''})
    end  
end



%% Frontal plane
figure; % 
for cc=1:size(subData,2)
    if cc<3 % noexo conditions
        time = timevector;
    else
        time = timevector + timevector(end) + time_offset;
    end
    % Standing leg
    subplot(4,2,1)  % Hip ABD angle
    var = subData(cc).StandLeg.HABDang;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 8.5])
        xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        xticklabels({'','','','','',''})
        title('Standing Leg')
        ylabel('HABD Angle')
    end

    subplot(4,2,3)  % Hip ABD moment
    var = subData(cc).StandLeg.HABDmom;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 8.5])
        xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        xticklabels({'','','','','',''})
        ylabel('HABD Moment')
    end    
    
    subplot(4,2,5)  % EMG Gmed
    var = subData(cc).StandLeg.Gmed;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 8.5])
        xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        xticklabels({'','','','','',''})
        ylabel('EMG Gmed (%)')
    end    

    subplot(4,2,7)  % EMG Adl
    var = subData(cc).StandLeg.Adl;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 8.5])
        xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        xticklabels({'','','','','',''})
        ylabel('EMG Adl (%)')
    end  


    % Stepping leg
    subplot(4,2,2)  % Hip ABD angle
    var = subData(cc).StepLeg.HABDang;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 8.5])
        xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        xticklabels({'','','','','',''})
        title('Stepping Leg')
    end

    subplot(4,2,4)  % Hip ABD moment
    var = subData(cc).StepLeg.HABDmom;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 8.5])
        xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        xticklabels({'','','','','',''})
    end
    subplot(4,2,6)  % Hip ABD muscles
    var = subData(cc).StepLeg.Gmed;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 8.5])
        xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        xticklabels({'','','','','',''})
    end   

    subplot(4,2,8)  % EMG Adl
    var = subData(cc).StepLeg.Adl;
    fill([time, fliplr(time)], ...  
        [mean(var,1)+std(var,0,1), fliplr(mean(var,1)-std(var,0,1))],Colors(cc,:),'EdgeColor','none')
    hold on
    plot(time,mean(var,1),'Color',Colors(cc,:),'LineWidth',1.75)
    if cc==4
        alpha(0.3); box off; xlim([-3 8.5])
        xticks([-2.5 -1 0 2.5 3 4.5 5.5 8])
        xticklabels({'','','','','',''})
    end  
end
