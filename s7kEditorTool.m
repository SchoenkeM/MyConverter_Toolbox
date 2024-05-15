function s7kEditorTool(InputDir,varargin)
% This function s7kEditorTool is designed to manipulate s7K files
% Revesion Version 1.8 (beta to split Frequency inside a file)
%
%
%Discription
%__________________________________________________________________________
% s7kEditorTool(InputDir) opens single '*s7k' file if "InputDir" is a 
%                         single file directory or reads all '*.s7k' files 
%                         from a folder if "InputDir" is a path directory.                                                  
%__________________________________________________________________________
% s7kEditorTool(_____,'-r') scans file quickly and returns the number and
%                           type of packets stored in the file. 
%                           No output if this option is enabled.
%__________________________________________________________________________
% s7kEditorTool(_____,'-wDir', "Directory") Saves the output unter the
%                                           specified "Directory"
%__________________________________________________________________________
% s7kEditorTool(_____,'-u',x); Reads the fist x packages form the file(s),
%                              whereby x must be an interger
%__________________________________________________________________________
% s7kEditorTool(_____,'-fixPos',{'Lat' 'Long' 'HightDatum'}) 
%                      Adds a position package containing a fixed position 
%                      before each package. Reference System set to WGS84  
%                      and Number of Satellites are set to 4.
%
%                      Lat and Long: Geographical coodinates in
%                                    decimaldegree specefied as strings.
%                      'HightDatum': Height relative to datum,specefied  
%                                    as strings.                                           
%__________________________________________________________________________                                 
% s7kEditorTool(_____,'-SN2WC',x) converts snippet to watercolumn Data, 
%                                 whereby x is the compressionfactor as 
%                                 integer with a valid value range between 
%                                 2 and 15. 
%__________________________________________________________________________                                                     
% s7kEditorTool(_____,'-fixSS',x) replace all recoreded sidescan BS values
%                                 with a fix number x.The input type of x,
%                                 whereby x has to be a uint8, uint16 or 
%                                 uint32 float value,depending on the Sonar 
%                                 settings during logging opperation     
%__________________________________________________________________________
% s7kEditorTool(_____,'-A2BS') Performes Footprint correction. Function 
%                              substract the footprint in record 7058 
%                              from the corresponding BS values in 7058.
%__________________________________________________________________________  
% s7kEditorTool(_____,'-splitFreq'); Splitting the file into individual files
%                                  based on all frequency contained in the
%                                  recored 7000.
%

%% 
%
% A s7k file contains a dynamic number of data packages, depending on the 
% recording time.
%
% One data packages is composed of:
% Data Frame Record (DRF) + Record Type Header (RTH) 
% + Data Record (DR) + Optional Record (OR)
% -> packet = DRF + FTH + RD (+ OR) + ckecksum (from DRF)
% the DRF and is alwas fix and determines the correspoding RTH.
% The corresponing is also fix. The Record data and Optinal data have a 
% dynamic bitszie, which depends on the sonar setting and the "flag fields"
% embetted in the RTH. 
%
% This function will read out all information and data stored in the s7k 
% file. If the function finds unknown (or unreadable) data parts, it will
% give feedback. If no warings appear the data is recognized completely and 
% there are no more information stored in the 27k file than displayed.
%
% >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
% Copyright (C) 2020 Mischa 
%
% This function is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
%
%Revision 1.1  2020/01/23 
%Initial revision
%
%email: mischa.schoenke@io-warnemuende.de
%
%% PATCH NOTES
%
% Revision 1.1 (by Mischa Schönke, 28.01.2020)
% - Option to import all files from a specific location implemented
% - elaped time counter implemented
% - processing loop over all import file, if option selected implemented
% - Discription added
% - Discription bug fix "s7kEditorTool" instead of "writes7k"
%
% Revision 1.2 (by Mischa Schönke, 06.02.2020)
% - Bug fix: SkipBytes= DRF.Size-"64"; instead of "68" to read file 
% - Bug fix: function snippet2watercolumn data reimplemented;
% - Fixed an error that caused the programm to crash if single beams within
% ....a ping are empty 
%
% Revision 1.3 (by Mischa Schönke, 06.02.2020)
% - function renamed from s7kEditorTool into s7kEditorTool
% - Unexpected out of Memory Bug from Version 1.2 try to fix with adding
%   a pause of 5 seconds, allowing the memory to refresh after each loop
% - adding a try - catch command, to display the last action if unexperced
%   error occures
% 
% Revision 1.4 (by Mischa Schönke, 13.02.2020)
% - typing error correction s7kEditorTool into s7kEditorTool
% - added s7kEditorTool(InputFile,'-fixPos',{'Lat' 'Long' 'HightDatum'}) to
%   write Position data to file
% - error fix, which wrote DRF header even if no RTH is available 
% - removed if case if Record ID is empty in case end of file is reached
%
% Revision 1.5 (by Mischa Schönke, 14.02.2020)
% - Bug fix of missing create 1003 function
% - moved the function create 1003 at the beginning of the while loop
% - serveral typing error removed
% - improved formating of text outpur for user feedback
% - moved "try - catch -command" to enclose the while loop
% - implemented Feedback for missing 7200 record
%
% Revision 1.6 (by Mischa Schönke, 24.09.2020)
% - Implement footprint correction for Norbit s7k calibrated backscatter
%   data by the command s7kEditorTool(InputFile,'-A2BS'). Footpint is 
%   already contined within the recoreded data.
%
% Revision 1.7 (by Mischa Schönke, 02.12.2020
% - Implement the option to split a multifreuquency file into multiple 
%   files each containing a single frequency. Splitting of the file is 
%   based on the frequency contained in the recored 7000. A suffix is added 
%   to the new files, which corresponds to the frequency of the file. Makes
%   the file readable for mbsystem to perform mb backangle correction.
%
%
%
%%_________________________________________________________________________
%% Optional imput Handler 
fprintf('\n\n______________________________________________________________\n');
fprintf('Start s7k Editor Tool (Version 1.8) \n\n');


if isfile(InputDir)
   
elseif isfolder(InputDir)
    
elseif isempty(InputDir)   
    return; 
end

% error('Unable to open file Directory.\nUnable to find Directory of input file: %s\n',filepath);
global para

para.InputDir=InputDir;
para.filepathInput=[]; 
para.filepathOutput=[];
para.FileList=[];
para.FullOutputFile=[]; 


para.rFilePartly=[]; 
para.readOnly=0;
para.fixSideScanValue=[]; 
para.CompressionFactor=[];  
para.fixPositionValue=[];
para.InputFileCounter=[];
para.FootprintCorr=[];
para.splitFq=[]; 
para.FilePosition=[];



%%
ninput=nargin; 
if ninput>0
    cargin=1;   
    while (cargin<=ninput)  
        if strcmp(varargin{cargin},'-r')
            para.readOnly=1;
        end      

        if strcmp(varargin{cargin},'-wDir')
            cargin=cargin+1;
            para.filepathOutput=varargin{cargin};
        end  

        if strcmp(varargin{cargin},'-u')
            cargin=cargin+1;
            para.rFilePartly=varargin{cargin};   
        end    

        if strcmp(varargin{cargin},'-SN2WC')
            cargin=cargin+1;
            para.CompressionFactor=varargin{cargin};         
        end     

        if strcmp(varargin{cargin},'-fixSS')
            cargin=cargin+1;
            para.fixSideScanValue=varargin{cargin};
        end  

        if strcmp(varargin{cargin},'-fixPos')
            cargin=cargin+1;
            para.fixPositionValue=varargin{cargin};
        end 

         if strcmp(varargin{cargin},'-A2BS')
            para.FootprintCorr=1;
         end 

         if strcmp(varargin{cargin},'-splitFreq')
            para.splitFq=1;
         end 

    cargin=cargin+1;
    end
end
    
%%  Checking and Open Input File

    if isempty(filepathInput)==1 
        [filepath,filename,ext] = fileparts(InputFile);
        fprintf('\t-> %-40s: %s\n','Input file directory', filepath);
        
            if isfolder(filepath)==0
                error('Unable to open file Directory.\nUnable to find Directory of input file: %s\n',filepath);
            elseif isempty(filepathOutput)==1      
                filepathOutput=filepath;
            end
            
        Names= InputFile;
        RfileID = fopen(InputFile,'r','l');
        fprintf('\t-> %-40s: %s\n\n','Selected input file(s)',[filename ext]); 
        
            if RfileID < 0        
                error('Unable to open data file.\nInput File: %s, can not be found or opened \n',[filename ext]);
            end  
      
    elseif isempty(filepathInput)==0

        fprintf('\t-> %-40s: %s\n','Input directory',filepathInput);  
        
            if isfolder(filepathInput)==0
                error('Unable to open file Directory.\nUnable to find Directory of input file: %s\n',filepathInput);
            elseif isempty(filepathOutput)==1
                filepathOutput=filepathInput;
            end

        [FileList]=ImportAllFilesFromDir(filepathInput);
        [~,Names]=cellfun(@fileparts,cellstr(FileList),'UniformOutput',0);
        fprintf('\t-> %-40s:\n','Selected input file(s)'); 
        
        for k=1:size(FileList,1)
            fprintf('%s.s7k\n', Names{k,1}); 
            RfileID = fopen(FileList(k,:),'r','l');
            
            if RfileID < 0        
                error('Unable to open data file.\nInput File: %s.s7k, can not be found or opened \n',Names{k,1});
            else
                fclose(RfileID);
            end  
            fprintf('                                            ');
        end
        InputFileCounter=size(FileList,1);
        fprintf('\n');
    end
%% Constructing and checking Output File Directory, Name and File id
         
  
  if  splitFq==1
      fprintf('\n\t-> Sequentially scanning of s7k packets to identify storing location of frequencies... '); 
       n=size(FileList,1);
       unique_Freq=cell(n,1);
       
           if isempty(filepathInput)==1
                 RfileID = fopen(InputFile,'r','l');
                  NrSonarSettings = ScanS7kFile(RfileID,rFilePartly);  
                 Freq_list = ScanS7k4Frequency(RfileID,rFilePartly,NrSonarSettings);
                 unique_Freq{1,1}=unique(Freq_list./1000);
           elseif isempty(filepathInput)==0

                 
               for i=1:n      
                     RfileID = fopen(FileList(n,:),'r','l');
                     NrSonarSettings = ScanS7kFile(RfileID,rFilePartly);  
                     Freq = ScanS7k4Frequency(RfileID,rFilePartly,NrSonarSettings);
                     unique_Freq{i,1}=unique(Freq./1000);   
               end
           end
          
         fprintf('done\n\n')  
  end
        
    if readOnly==0   
        if isfolder(filepathOutput)==0 % check if output path is valid
            error('Unable to open output file.\nUnable to find Directory of output file: %s\n',filepathOutput);
        else
            fprintf('\t-> %-40s: %s\n','Output file directory',filepathOutput);  
        end  
        
        if isempty(FileList)==1 && splitFq==0
            [OutputFileName]= GenerateFilename(filepathOutput,filename);  
            FullOutputFile=cellstr(fullfile(filepathOutput,[OutputFileName ext]));
            
            WfileID = fopen(fullfile(filepathOutput,[OutputFileName ext]),'w');   
            if WfileID < 0  % check if output data name is valid    
                error('Unable to open output file.\nOutput file: %s, can not be created or opened \n',[OutputFileName ext]);
            else
                fprintf('\t-> %-40s: %s\n\n','Automatically generated output file',[OutputFileName ext]);  
            end
            
        elseif isempty(FileList)==0 && splitFq==0
            fprintf('\t-> %-40s:','Automatically generated output file(s)');
            OutputFileName=cell(size(FileList,1),1);
            FullOutputFile=cell(size(FileList,1),1);
            for k=1:size(FileList,1)
                OutputFileName{k,1}= GenerateFilename(filepathOutput,Names{k,1}); 
                fprintf('\t%41s.s7k\n',OutputFileName{k,1}); 
                FullOutputFile{k,1}=fullfile(filepathOutput,[OutputFileName{k,1} '.s7k']);
                
                WfileID = fopen(fullfile(filepathOutput,[OutputFileName{k,1} '.s7k']),'w'); 
                if WfileID < 0  % check if output data name is valid    
                    error('Unable to open output file.\nOutput file: %s, can not be created or opened \n',[OutputFileName{k,1} '.s7k']);
                else
                    fclose(WfileID);
                end
            end
            fprintf('\n');
            
        elseif splitFq==1
            fprintf('\t-> %-40s:','Automatically generated output file(s)\n');
            if isempty(FileList)==1
                M=1;
            else
                M=size(FileList,1);
            end
            
            for k=1:M
                N=length(unique_Freq{k,1});
                for j=1:N
                    if ischar(Names)
                        Names=cellstr(Names);
                    end
                [~,tempNames,~] = fileparts(Names{k,1});
                fq=unique_Freq{k,1}; fq=fq(j);
                tempNames= [tempNames '_' num2str(fq) 'kHz'];
                OutputFileName{k,j}= GenerateFilename(filepathOutput,tempNames); 
                fprintf('\t%41s.s7k\n',OutputFileName{k,j}); 
                FullOutputFile{k,j}=fullfile(filepathOutput,[OutputFileName{k,j} '.s7k']);
                
                WfileID = fopen([FullOutputFile{k,j} '.s7k'],'w'); 
                    if WfileID < 0  % check if output data name is valid    
                        error('Unable to open output file.\nOutput file: %s, can not be created or opened \n',[OutputFileName{k,j} '.s7k']);
                    else
                        fclose(WfileID);
                    end
                    
                end
            end
            
            fprintf('\n');
        end
    else 
        WfileID=[];
        fprintf('\t-> Attention: Option -r is enabled. No s7k data output will be created\n\n'); 
    end
    
%% Scan File checks Input File for Record identifiers
   for k=1:InputFileCounter
       
       OutPutFiles=OutputFileName
       tic
      
                if isempty(FileList)==0
                    InputFile=FileList(k,:);
                    RfileID = fopen(InputFile,'r','l');
                    if readOnly==0 && splitFq==0
                        WfileID = fopen(FullOutputFile{k,1},'w');
                        frewind(WfileID)                       
                    end 
                    fprintf('\n\n\t_________________________________________________________\n');
                    fprintf('\tFile %d/%d is now been processed: %s.s7k\n', k,InputFileCounter, Names{k,1});    
                end

            %% Quick scans input file
                ScanS7kFile(RfileID,rFilePartly);  % quick scans total s7k file. Shows all record included in Input data file

        if readOnly==0 
            %% Create Waitbar 
                [WaitbarTicks]= GetWaitbarTicks(InputFile); WaitbarStep=1;
                h=waitbar(0,'Sequentially reading of s7k packets in process... ');

            %% Start Loop to decode Input File
                fprintf('\n\t-> Sequentially reading and writing of s7k packets in process... '); 
                frewind(RfileID) % set RfileID to beginning of file
                LoopAktive=1;  PacketCounter=0; Sr=[];  R7200=1;
                
                try
                
                    while  ~feof(RfileID) && LoopAktive==1

                    RTH=[]; RD=[];  % Clears Variables for each run
                    %% DRF SECTION
                    DRF = ReadDataRecordFrame_v01(RfileID); 
                                      
                    if isempty(DRF)==0 && isempty(fixPositionValue)==0 ...
                          && isempty(WfileID)==0 && mod(PacketCounter,3)==0   
                      
                        % Create 1003 DRF
                          PosDRF=DRF;
                          PosDRF.Size=105;
                          PosDRF.RecordTypeIdentifier=1003;
                        % Create 1003 RTH  
                          RTH1003= CreatePosition_v01(fixPositionValue);  
                        % Write 1003 DRF and RTH to output file  
                          WriteDataRecordFrame_v01(WfileID,PosDRF); 
                          WritePosition_v01(WfileID,RTH1003);
                          fwrite(WfileID,0,'uint32');    
                    end
                    
                   %% RD and OD, reads record data and optinal data
                        RecordTypeIdentifier= max([DRF.RecordTypeIdentifier 0]);
                        switch  RecordTypeIdentifier
                           case 1003  
                                       RTH = ReadPosition_v01(RfileID);
                                       if splitFq==0
                                           WriteDataRecordFrame_v01(WfileID,DRF);
                                           WritePosition_v01(WfileID,RTH);
                                       elseif splitFq==1
                                           
                                              WfileID = fopen(FullOutputFile{k,1},'w');
                                              frewind(WfileID)  
                                           
                                           
                                       end
                           case 1012
                                       RTH = ReadRollPitchHeave_v01(RfileID); 
                                       
                                       WriteDataRecordFrame_v01(WfileID,DRF);
                                       WriteRollPitchHeave_v01(WfileID,RTH); 

                           case 1013
                                       RTH = ReadHeading_v01(RfileID);
                                       
                                       WriteDataRecordFrame_v01(WfileID,DRF);
                                       WriteHeading_v01(WfileID,RTH);

                           case 1015
                                       RTH = ReadNavigation_v01(RfileID); 
                                       
                                       WriteDataRecordFrame_v01(WfileID,DRF);
                                       WriteNavigation_v01(WfileID,RTH);

                           case 1016     
                                      [RTH,RD] = ReadAttitude_v01(RfileID);
                                      
                                      WriteDataRecordFrame_v01(WfileID,DRF);
                                      WriteAttitude_v01(WfileID,RTH,RD);

                           case 1017
                                       RTH = ReadPanTilt_v01(RfileID);
                                       WriteDataRecordFrame_v01(WfileID,DRF);
                                       WritePanTilt_v01(WfileID,RTH);

                           case 7000          
                                      [RTH,Sr] = ReadSonarSettings_v01(RfileID); % Sr for Sampling Rate
                                      
                                      WriteDataRecordFrame_v01(WfileID,DRF);
                                      WriteSonarSettings_v01(WfileID,RTH); 

                           case 7004
                                      [RTH,RD] = ReadBeamGeometry_v01(RfileID); 
                                      
                                      WriteDataRecordFrame_v01(WfileID,DRF);
                                      WritesBeamGeometry_v01(WfileID,RTH,RD); 

                           case 7007
                                      [RTH,RD] = ReadSideScanData_v01(RfileID);
                                      
                                      WriteDataRecordFrame_v01(WfileID,DRF);
                                      WriteSideScanData_v01(WfileID,RTH,RD,fixSideScanValue);

                           case 7027 
                                      [RTH,RD] = ReadRawBathymetry_v01(RfileID);
                                      
                                      WriteDataRecordFrame_v01(WfileID,DRF);
                                      WriteRawBathymetry_v01(WfileID,RTH,RD);

                           case 7028
                                      [RTH,RD] = ReadSnippetData_v01(RfileID);
                                      
                                      WriteDataRecordFrame_v01(WfileID,DRF);
                                      WriteSnippetData_v01(WfileID,RTH,RD)

                           case 7042
                                      [RTH,RD] = ReadCompressedWatercolomnData_v01(RfileID);  
                                      
                                      WriteDataRecordFrame_v01(WfileID,DRF);
                                      WriteCompressedWatercolomnData_v01(WfileID,RTH,RD);

                           case 7058    
                                      [RTH,RD] = ReadCalibratedSnippetData_v01(RfileID);   
%                                       frintf(RD(1).Footprint)
                                      WriteDataRecordFrame_v01(WfileID,DRF);
                                      if FootprintCorr==1
                                         WriteCalibratedSnippetDataFootprintCorr_v01(WfileID,RTH,RD) 
                                      else
                                         WriteCalibratedSnippetData_v01(WfileID,RTH,RD) 
                                      end

                           case 7200   % NOT IMPLEMENTED 
                                      if R7200==1
                                          fprintf(' WARNING \n\n')
                                          fprintf('\t-> %s\n','Record Identifier 7200 has not been implemented yet. Packets and including content is skipped.');
                                          fprintf('\t-> %s\n','Record 7200 contains only textual header information analogous to the textual header of segy file.');
                                          fprintf('\t-> %s\n\n','The lack of this record is irrelevant for data processing.');
                                          fprintf('\t-> Continue sequentially reading...');
                                          R7200=0;    
                                      end
%                                        [RTH,RD] = Reads7kFileHeader_v01(RfileID);   
%                                         WriteCalibratedSnippetData_v01(WfileID,RTH,RD) 
                                      RTH = []; SkipBytes= DRF.Size-64; % -64 Total size of record minus the Bytes of the DRF 
                                      fseek(RfileID,SkipBytes,'cof');   

                           case 7610   
                                       RTH = ReadSoundVelocity(RfileID);  
                                       
                                       WriteDataRecordFrame_v01(WfileID,DRF);
                                       WriteSoundVelocity_v01(WfileID,RTH);
                           case 0 
                                       % an flag that marks the end of the
                                       % file
                                       WaitbarStep=WaitbarStep-1;
                           otherwise    
                                 fprintf(' WARNING \n')
                                 fprintf('\t-> %s"%d"%s\n','Record Identifier',RecordTypeIdentifier,'has not been implemented yet. Including content will be skipped.');
                                 fprintf('\t-> Continue sequentially reading...');
                                 pause
                                 RTH = []; SkipBytes= DRF.Size-64; % -64 Total size of record minus the Bytes of the DRF 
                                 fseek(RfileID,SkipBytes,'cof');   
                        end % end of the switch case


                        if isempty(RTH)==0 % Checksum read and write
                              DRF.Checksum = fread(RfileID,1,'uint32');  
                              if isempty(WfileID)==0; fwrite(WfileID,DRF.Checksum,'uint32'); end
                        end     

             %% END of packet frame
             %% _______________________________________________________________________
                        % Snippet 2 Compressed Watercolumn Data
                        if isempty(CompressionFactor)==0 && isempty(WfileID)==0 && RecordTypeIdentifier==7028 && isempty(Sr)==0   
                             WriteSnippet2CompresstWCData_v01(WfileID,DRF,RTH,RD,Sr,CompressionFactor);   
                             fwrite(WfileID,DRF.Checksum,'uint32');
                        end   
                        
                        PacketCounter=PacketCounter+1;
                        if PacketCounter==rFilePartly
                            LoopAktive=0;
                        end

                        %% Waitbar Section
                        if ftell(RfileID)>=WaitbarTicks(WaitbarStep) 
                           waitbar(WaitbarStep/100); WaitbarStep=WaitbarStep+1; 
                        end
                    end % close While loop
                     
                %%_____________________________________________________________________
                %% closes read and write ID pointer in Input and Output file 
                    try
                        fclose(RfileID);
                    catch
                        fprintf('\tUnable to close input File ID: %s.s7k\n', Names{k,1});
                    end

                    try
                        fclose(WfileID);
                    catch 
                        if readOnly==0  
                            fprintf('\tUnable to close output File ID: %s.s7k\n', FullOutputFile{k,1});
                        end
                    end
                    delete(h)
  
                catch % in case something in while loop breaks
                    % This section is called in case of unexpected error
                    fprintf('\n\n||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||\n');
                    fprintf('\t-> PROCESSING FAILED \n');
                    fprintf('\t-> Unexprected Error when opperating File : %s.s7k\n', filename);
                    fprintf('\t-> Last called valid s7k Record Identifier: %d\n\n', RecordTypeIdentifier);

                    userview = memory;
                    fnames=fieldnames(userview);
                    fprintf('\tView Memory Stats\n');
                    fprintf('\t_________________________________________________________\n');
                    faktorBytes2GB=1/(1024*1024*1024);
                    for i=1:3
                        fprintf('\t%25s:\t%6.2f GB\n',fnames{i},userview.(fnames{i}).*faktorBytes2GB);
                    end

                    CurrentWS=whos;
                      tempVar = cellstr({CurrentWS.name}.');
                    tempBytesMB = cell2mat({CurrentWS.bytes}.')./(1024*1024);
                    tempBytesGB = cell2mat({CurrentWS.bytes}.')*faktorBytes2GB;
                      fprintf('\n%25s\t\t%10s\t%14s\n\n','Variable Names',' Size MB',' Size GB');

                    for i=1:length(tempVar)
                      fprintf('%25s\t\t%10.2f\t%14.2f \n', tempVar{i},tempBytesMB(i),tempBytesGB(i));  
                    end
                     
                    fprintf(' |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| \n\n'); 
                    fclose('all');
                    quit cancel
                end
                                        
        end % end of read only
                           
        elapsedTime = toc;    
        s = duration(0,0,elapsedTime);
        
        if readOnly==1 
            fprintf('\t-> file scanning successfull\n');
            fprintf('\t-> file is readable for QPS\n');
        else
            fprintf('processing successfull\n');
        end
        
        fprintf('\t-> elapsed time %s\n', datestr(s,'HH:MM:SS'))
        fprintf('\t_________________________________________________________\n\n');
        pause(5) % gives tghe programm time to free memory. In case of 
                 % multiple file opperation leaving out pause can cause
                 % unexpected crash of menory
      
   end
end % close main function 

function [FileList]=ImportAllFilesFromDir(InputDir)

currentPath=pwd;
ext='*.s7k'; % default
cd(InputDir); fileList = dir(ext);
name = {fileList.name}.'; folder = {fileList.folder}.';
FileList=cell2mat(fullfile(folder,name));
cd(currentPath);

end

function  [NewName]= GenerateFilename(filepathOutput,OldFilename)
        counter=1; 
        OutputFileName=sprintf('%s_%03d',OldFilename,counter);
        OutputFile=fullfile(filepathOutput,[OutputFileName '.s7k']);
       
        while isfile(OutputFile)==1
            counter=counter+1;
            OutputFileName=sprintf([OldFilename '_%03d'],counter);
            OutputFile=fullfile(filepathOutput,[OutputFileName '.s7k']);
        end 
        NewName=OutputFileName;
end

function  [WaitbarTicks]= GetWaitbarTicks(InputFile)

        s=dir(InputFile); FileSize=s.bytes;
        WaitbarTicks=linspace(1,FileSize,100); 
        WaitbarTicks(end)=FileSize;
end

function [SonarSettings]=ScanS7kFile(id,rFilePartly)
   
   Positioning=0; RollPitchHeave=0; Heading=0; Navigation=0; PanTilt=0;  
   Attitude=0; SideScanData=0; RawBathymetry=0; SnippetData=0;
   CompressedWatercolomnData=0; CalibratedSnippetData=0;SoundVelocity=0; 
   SonarSettings=0; BeamGeometry=0; CurrentByte=0;
   UnknownRecordTypeIdentifier=[]; PacketCounter=1;Active=1;
     
   frewind(id) % set id to beginning of file
   while  ~feof(id)  && Active==1     
       fseek(id,8,'cof');
       RecordSize= fread(id,1,'uint32'); 
       fseek(id,20,'cof'); 
       RecordTypeIdentifier= fread(id,1,'uint32');  
       if isempty(RecordTypeIdentifier)==0     
           switch  RecordTypeIdentifier
               case 1003  
                    Positioning=Positioning+1;
               case 1012
                    RollPitchHeave=RollPitchHeave+1;
               case 1013
                    Heading= Heading+1;
               case 1015
                    Navigation=Navigation+1;
               case 1016     
                     Attitude=Attitude+1;
               case 1017
                     PanTilt=PanTilt+1;
               case 7000            
                    SonarSettings=SonarSettings+1;
               case 7004  
                    BeamGeometry=BeamGeometry+1;
               case 7007 
                    SideScanData=SideScanData+1; 
               case 7027     
                    RawBathymetry=RawBathymetry+1; 
               case 7028
                    SnippetData=SnippetData+1;                  
               case 7042  
                    CompressedWatercolomnData=CompressedWatercolomnData+1;  
               case 7058     
                    CalibratedSnippetData=CalibratedSnippetData+1;
               case 7610   
                    SoundVelocity=SoundVelocity+1;                         
               otherwise 
                    UnknownRecordTypeIdentifier=[UnknownRecordTypeIdentifier;...
                        RecordTypeIdentifier]; %#ok<AGROW>
           end % end of the switch case for (Record Identifier)
           
           if isempty(rFilePartly)==0 || length(UnknownRecordTypeIdentifier)>30
                 if rFilePartly==PacketCounter || length(UnknownRecordTypeIdentifier)>30
                      Active=0; PacketCounter=PacketCounter-1; 
                 end
           end
           
           
           
           PacketCounter= PacketCounter+1;
             CurrentByte= CurrentByte+RecordSize;
               SkipBytes= RecordSize-36;
             fseek(id,SkipBytes,'cof');  
       end % end of If case for isempty(DRF)
   end
   
   if nargout == 0
    CurrentByteInMb=floor(CurrentByte/(1024^2));
    fprintf('\t_________________________________________________________\n');
    fprintf('\tQuickview of Inputfile \n');
    fprintf('\t%35s: %6d MB (%d Bytes)\n','Scanned Bytes (by this function)',CurrentByteInMb,CurrentByte);
    if isempty(rFilePartly)==1
        fprintf('\t%35s: %6d packets\n\n','Number of s7k Packets identified',PacketCounter);
    else
        fprintf('\t%35s: %6d packets (manually limitted) \n\n','Number of s7k Packets identified',PacketCounter);
    end
    fprintf('\t%35s: %6d packets\n','Positioning',Positioning);
    fprintf('\t%35s: %6d packets\n','Roll/ Pitch /Heave',RollPitchHeave);
    fprintf('\t%35s: %6d packets\n','Heading',Heading);
    fprintf('\t%35s: %6d packets\n','Navigation',Navigation);
    fprintf('\t%35s: %6d packets\n','Attitude',Attitude);
    fprintf('\t%35s: %6d packets\n','Pan/ Tilt',PanTilt);
    fprintf('\t%35s: %6d packets\n','Sonar Settings',SonarSettings);
    fprintf('\t%35s: %6d packets\n','BeamGeometry',BeamGeometry);
    fprintf('\t%35s: %6d packets\n','Sidescan Data',SideScanData);
    fprintf('\t%35s: %6d packets\n','RawBathymetry',RawBathymetry);
    fprintf('\t%35s: %6d packets\n','Snippet Data',SnippetData);
    fprintf('\t%35s: %6d packets\n','Compressed Watercolomn Data',CompressedWatercolomnData);
    fprintf('\t%35s: %6d packets\n','Calibrated Snippet Data',CalibratedSnippetData);
    fprintf('\t%35s: %6d packets\n','Sound Velocity',SoundVelocity);
    
    if isempty( UnknownRecordTypeIdentifier)==1 && isempty(rFilePartly)==1
        fprintf('\n\tConentent of .s7k Input File has been rendered correctly and completely\n'); 
    elseif isempty( UnknownRecordTypeIdentifier)==1 && isempty(rFilePartly)==0
        fprintf('\n\tConentent of .s7k Input File for the first "%d" Packages \n',rFilePartly); 
        fprintf('\thas been rendered correctly and completely\n');  
    else
        
        if UnknownRecordTypeIdentifier==7200
          fprintf('\n\t-> %-10s: %s\n','WARNING','Record Identifier 7200 has not been implemented yet. Including content is skipped.');
          fprintf('\t%-15s%s\n','','Record 7200 contains only textual header information analogous to the textual header of segy file.');
          fprintf('\t%-15s%s\n\n','','The lack of this record is irrelevant for data processing.');
          
        else
        fprintf('\n');
        fprintf('\tUnknown (or not implemented) Record Type Identifier: %4d\n', UnknownRecordTypeIdentifier); 
        fprintf('\tPackets and including content will be skipped and not written to the Output File\n');
        end
    end
    fprintf('\t_________________________________________________________\n');
    
   end
end

function [UsedFrequencys]=ScanS7k4Frequency(id,rFilePartly,NrSonarSettings)
    
   UsedFrequencys= zeros(NrSonarSettings,1);
   i=1;  PacketCounter=1; Active=1; CurrentByte=0;
   
   frewind(id) % set id to beginning of file
   while  ~feof(id)  && Active==1     
       fseek(id,8,'cof');
       RecordSize= fread(id,1,'uint32'); 
       fseek(id,20,'cof'); 
%      position = ftell(id);     
%     fseek(id, position-4, 'bof');
       RecordTypeIdentifier= fread(id,1,'uint32');  
       
        if isempty(rFilePartly)==0 
               if rFilePartly==PacketCounter
                   Active=0; PacketCounter=PacketCounter-1; 
               end
        end
        
        if isempty(RecordTypeIdentifier)==0 &&  RecordTypeIdentifier==7000   
            fseek(id,28,'cof'); % skip rest of DRF   
            fseek(id,14,'cof'); % start of RTH7000
            UsedFrequencys(i,1) = fread(id,1,'float32'); % read frequency
            i=i+1;
            fseek(id,142,'cof'); % skip rest of RTH7000    
       
        else
           PacketCounter = PacketCounter+1;
             CurrentByte = CurrentByte+RecordSize;
               SkipBytes = RecordSize-36;
           fseek(id,SkipBytes,'cof');  

       end % end of If case for isempty(DRF)
   end
end


function [y]=bi2de(x)
    a=length(x); b=ones(1,a).*2; c=0:a-1; x1=double(x)';
    y=sum((b.^c).*x1);   
end

function [DRF]=ReadDataRecordFrame_v01(id)

DRF.ProtocolVersion                      =fread(id,1,'uint16'); % uint16
DRF.Offset                               =fread(id,1,'uint16'); % uint16
DRF.SyncPattern                          =fread(id,1,'uint32'); % uint32 
DRF.Size                                 =fread(id,1,'uint32'); % uint32 
DRF.OptionalDataOffset                   =fread(id,1,'uint32'); % uint32 
DRF.OptionalDataIdentifier               =fread(id,1,'uint32'); % uint32 
DRF.yy                                   =fread(id,1,'uint16'); % uint16 2
DRF.doy                                  =fread(id,1,'uint16'); % uint16 Day of Year 2
DRF.ss                                   =fread(id,1,'float');  % f32 4
DRF.HH                                   =fread(id,1,'uint8');  % uint8 1
DRF.MM                                   =fread(id,1,'uint8');  % uint8 1
DRF.Reserved                             =fread(id,1,'uint16'); % uint16 fseek(fd,2,0);
DRF.RecordTypeIdentifier                 =fread(id,1,'uint32'); % uint32 

DRF.DeviceIdentifier                     =fread(id,1,'uint32'); % uint32 
DRF.SystemEnumeration                    =fread(id,1,'uint32'); % uint32 
DRF.Reserved2                            =fread(id,1,'uint32'); % uint32 fseek(fd,2,0);
% Flag BIT FIELD
DRF.Flag.ValidChecksum                   =fread(id,1,'*ubit1');  % uint16
DRF.Flag.Reserved                        =fread(id,14,'*ubit1'); % uint16
DRF.Flag.RecordedData                    =fread(id,1,'*ubit1');  % uint16 if 0: LiveData if:1 RecorededData

DRF.Reserved3                            =fread(id,1,'uint32'); % uint32 fseek(fd,2,0);
DRF.Reserved4                            =fread(id,1,'uint16'); % uint32 fseek(fd,2,0);
DRF.TotalRecordInFragmentedDataRecordSet =fread(id,1,'uint32'); % uint32 
DRF.FragmentNumber                       =fread(id,1,'uint32'); % uint32 

% Checksum                               =fread(id,1,'uint32'); % uint32 
end
function WriteDataRecordFrame_v01(id,DRF)

if isempty(id)==0
fwrite(id,DRF.ProtocolVersion,'uint16');                       % uint16
fwrite(id,DRF.Offset ,'uint16');                               % uint16
fwrite(id,DRF.SyncPattern ,'uint32');                          % uint32 
fwrite(id,DRF.Size ,'uint32');                                 % uint32 
fwrite(id,DRF.OptionalDataOffset,'uint32');                    % uint32 
fwrite(id,DRF.OptionalDataIdentifier,'uint32');                % uint32 
fwrite(id,DRF.yy,'uint16');                                    % uint16 
fwrite(id,DRF.doy,'uint16');                                   % uint16 
fwrite(id,DRF.ss,'float');                                     % f32 
fwrite(id,DRF.HH ,'uint8');                                    % uint8 
fwrite(id,DRF.MM,'uint8');                                     % uint8 
fwrite(id,DRF.Reserved,'uint16');                              % uint16
fwrite(id,DRF.RecordTypeIdentifier ,'uint32');                 % uint32 
fwrite(id,DRF.DeviceIdentifier,'uint32');                      % uint32 
fwrite(id,DRF.SystemEnumeration,'uint32');                     % uint32 
fwrite(id,DRF.Reserved2,'uint32');                             % uint32
fwrite(id,DRF.Flag.ValidChecksum ,'*ubit1');     
fwrite(id,DRF.Flag.Reserved,'*ubit1'); 
fwrite(id,DRF.Flag.RecordedData  ,'*ubit1'); 
% uint16
fwrite(id,DRF.Reserved3,'uint32');                             % uint32 
fwrite(id,DRF.Reserved4,'uint16');                             % uint16 
fwrite(id,DRF.TotalRecordInFragmentedDataRecordSet,'uint32');  % uint32 
fwrite(id,DRF.FragmentNumber,'uint32');                        % uint32 

%%______________________________________________________________________
% DataSection                            =0;                   % Dynamit
% switch case

%%______________________________________________________________________
% markes end of recored data frame
% End status request returns the bytes size of stored DRF + DATA +OD 
% Checksum                             =fwrite(id,1,'uint32'); % uint32 
end

end

function RTH1003 = ReadPosition_v01(id)
    RTH1003.DatumIdentifier 	            =fread(id,1,'uint32');		% (0)
    RTH1003.Latency			                =fread(id,1,'float32');		% (4)
     
	RTH1003.LatitudeOrNorthing			    =fread(id,1,'float64');	    % (8)
	RTH1003.LongitudeOrEasting			    =fread(id,1,'float64');		% (16)
	RTH1003.HeightRelativeToDatumOrHeight	=fread(id,1,'float64');		% (24)	
	
    RTH1003.PositionType                    =fread(id,1,'uint8');      % (32)
       % if 0 >> 'GeographicalCoordinates';
       % if 1 >> 'GridCoordinates'
    
	RTH1003.UTMZone	                        =fread(id,1,'uint8');       % (33)
    
	RTH1003.QualityFlag		                =fread(id,1,'uint8');       % (34)
       % if 0 >> 'NavigationData';
       % if 1 >> 'DeadReckoning';
 
    RTH1003.GetPositioningMethod            =fread(id,1,'uint8');       % (35)			
% if		0	= 'GPS';
% 			1	= 'DGPS';	
% 			2	= 'StartOfInertialPositioningSystemFromGPS'	;
% 			3	= 'StartOfInertialPositioningSystemFromDGPS';			
% 			4	= 'StartOfInertialPositioningSystemFromBottomCorrelation';		
% 			5	= 'StartOfInertialPositioningFromBottomObject';			
% 			6	= 'StartOfInertialPositioningFromInertialPositioning';			
% 			7	= 'StartOfInertialPositioningFromOptionalData';			
% 			8	= 'StopOfInertialPositioningSystemToGPS';  	
% 			9	= 'StopOfInertialPositioningSystemToDGPS';	
%         	10	= 'StopOfInertialPositioningSystemToBottomCorrelation';
% 			12	= 'StartOfInertialPositioningToInertialPositioning';			
% 			13	= 'StartOfInertialPositioningToOptionalData';
% 			14	= 'UserDefined';		     
%           15	= 'RTK Fix';	 
%           16	= 'RTK Float';	

    RTH1003.NumberofSatellites              =fread(id,1,'uint8');       % (36)

end
function WritePosition_v01(id,RTH1003)
% Contains 37 Bytes
if isempty(id)==0
    fwrite(id,RTH1003.DatumIdentifier,'uint32');		         % (0)
    fwrite(id,RTH1003.Latency,'float32');		                 % (4)
     
	fwrite(id,RTH1003.LatitudeOrNorthing,'float64');	         % (8)
	fwrite(id,RTH1003.LongitudeOrEasting,'float64');		     % (16)
	fwrite(id,RTH1003.HeightRelativeToDatumOrHeight,'float64');	 % (24)	
	
    fwrite(id,RTH1003.PositionType,'uint8');                     % (32)
       % if 0 >> 'GeographicalCoordinates';
       % if 1 >> 'GridCoordinates'
    
	fwrite(id,RTH1003.UTMZone,'uint8');                          % (33)
    
	fwrite(id,RTH1003.QualityFlag,'uint8');                      % (34)
       % if 0 >> 'NavigationData';
       % if 1 >> 'DeadReckoning';
 
    fwrite(id,RTH1003.GetPositioningMethod,'uint8');             % (35)			
        % if		0	= 'GPS';
        % 			1	= 'DGPS';	
        % 			2	= 'StartOfInertialPositioningSystemFromGPS'	;
        % 			3	= 'StartOfInertialPositioningSystemFromDGPS';			
        % 			4	= 'StartOfInertialPositioningSystemFromBottomCorrelation';		
        % 			5	= 'StartOfInertialPositioningFromBottomObject';			
        % 			6	= 'StartOfInertialPositioningFromInertialPositioning';			
        % 			7	= 'StartOfInertialPositioningFromOptionalData';			
        % 			8	= 'StopOfInertialPositioningSystemToGPS';  	
        % 			9	= 'StopOfInertialPositioningSystemToDGPS';	
        %         	10	= 'StopOfInertialPositioningSystemToBottomCorrelation';
        % 			12	= 'StartOfInertialPositioningToInertialPositioning';			
        % 			13	= 'StartOfInertialPositioningToOptionalData';
        % 			14	= 'UserDefined';		     
        %           15	= 'RTK Fix';	 
        %           16	= 'RTK Float';	

    fwrite(id,RTH1003.NumberofSatellites,'uint8');                % (36)
end
end
function RTH1003 = CreatePosition_v01(fixPositionValue)

    RTH1003.DatumIdentifier 	            =0;		% (0)
    RTH1003.Latency			                =0;		% (4)
     
    Lat= str2num(fixPositionValue{1,1}); 
    Long= str2num(fixPositionValue{1,2});
    heightRelativeToDatumOrHeight= str2num(fixPositionValue{1,3});
    
    LatInRadians = deg2rad(Lat);
    LongInRadians = deg2rad(Long);
    
	RTH1003.LatitudeOrNorthing			    =LatInRadians;	    % (8)
	RTH1003.LongitudeOrEasting			    =LongInRadians;		% (16)
	RTH1003.HeightRelativeToDatumOrHeight	=heightRelativeToDatumOrHeight;		% (24)	
	
    RTH1003.PositionType                    =0;      % (32)
       % if 0 >> 'GeographicalCoordinates';
       % if 1 >> 'GridCoordinates'
    
	RTH1003.UTMZone	                        =0;       % (33)
    
	RTH1003.QualityFlag		                =0;       % (34)
       % if 0 >> 'NavigationData';
       % if 1 >> 'DeadReckoning';
 
    RTH1003.GetPositioningMethod            =0;       % (35)			
% if		0	= 'GPS';
% 			1	= 'DGPS';	
% 			2	= 'StartOfInertialPositioningSystemFromGPS'	;
% 			3	= 'StartOfInertialPositioningSystemFromDGPS';			
% 			4	= 'StartOfInertialPositioningSystemFromBottomCorrelation';		
% 			5	= 'StartOfInertialPositioningFromBottomObject';			
% 			6	= 'StartOfInertialPositioningFromInertialPositioning';			
% 			7	= 'StartOfInertialPositioningFromOptionalData';			
% 			8	= 'StopOfInertialPositioningSystemToGPS';  	
% 			9	= 'StopOfInertialPositioningSystemToDGPS';	
%         	10	= 'StopOfInertialPositioningSystemToBottomCorrelation';
% 			12	= 'StartOfInertialPositioningToInertialPositioning';			
% 			13	= 'StartOfInertialPositioningToOptionalData';
% 			14	= 'UserDefined';		     
%           15	= 'RTK Fix';	 
%           16	= 'RTK Float';	

    RTH1003.NumberofSatellites              =4;       % (36)

end

function RTH1012=ReadRollPitchHeave_v01(id)
% Contains 12 Bytes
	RTH1012.Roll	=fread(id,1,'float32');		% (0)
	RTH1012.Pitch	=fread(id,1,'float32');		% (4)
	RTH1012.Heave	=fread(id,1,'float32');		% (8)	 
end
function WriteRollPitchHeave_v01(id,RTH1012)
% Contains 12 Bytes
if isempty(id)==0
    fwrite(id,RTH1012.Roll,'float32');		% (0)
	fwrite(id,RTH1012.Pitch,'float32');		% (4)
	fwrite(id,RTH1012.Heave,'float32');		% (8)	
end  
end

function RTH1013=ReadHeading_v01(id)
    RTH1013.Heading	=fread(id,1,'float32');		% (0)
end
function WriteHeading_v01(id,RTH1013)
if isempty(id)==0
   fwrite(id,RTH1013.Heading,'float32');		% (0)
end
end

function RTH1015=ReadNavigation_v01(id)
	RTH1015.VerticalReference               = fread(id,1,'uint8');  % (0)		
%  if   1 = 'Ellipsoid';
% 	    2 = 'Geoid';
%       3 = 'ChartDatum';

	RTH1015.Latitude	                    =fread(id,1,'float64'); % (1)
	RTH1015.Longitude	                    =fread(id,1,'float64'); % (9)

	RTH1015.HorizontalPositionAccuracy	    =fread(id,1,'float32');	% (17)
	RTH1015.VesselHeight					=fread(id,1,'float32');	% (21)
	RTH1015.HeightAccuracy				    =fread(id,1,'float32');	% (25)
	RTH1015.SpeedOverGround				    =fread(id,1,'float32');	% (29)
	RTH1015.CourseOverGround				=fread(id,1,'float32');	% (33)
	RTH1015.Heading						    =fread(id,1,'float32');	% (37)  
end
function WriteNavigation_v01(id,RTH1015)

if isempty(id)==0
% Contains 41 Bytes
	fwrite(id,RTH1015.VerticalReference,'uint8');                % (0)		
%  if VerticalReference  1 = 'Ellipsoid';
% 	                     2 = 'Geoid';
%                        3 = 'ChartDatum';

	fwrite(id,RTH1015.Latitude,'float64');                      % (1)
	fwrite(id,RTH1015.Longitude,'float64');                     % (9)

	fwrite(id,RTH1015.HorizontalPositionAccuracy,'float32');	% (17)
	fwrite(id,RTH1015.VesselHeight,'float32');              	% (21)
	fwrite(id,RTH1015.HeightAccuracy,'float32');                % (25)
	fwrite(id,RTH1015.SpeedOverGround,'float32');               % (29)
	fwrite(id,RTH1015.CourseOverGround,'float32');              % (33)
	fwrite(id,RTH1015.Heading,'float32');                       % (37)
end
   
end

function [RTH1016,RD1016]=ReadAttitude_v01(id)
% Contains 158 Bytes
% auto range method  identifier unknown
% auto range filtering Method identifier unknown
    RTH1016.NumberOfAttidudeDataSets = fread(id,1,'uint8');  % (0)
    for i=1:RTH1016.NumberOfAttidudeDataSets
         RD1016.dTFromRecordTimestamp= fread(id,1,'uint16');
         RD1016.Roll                 = fread(id,1,'float32');
         RD1016.Pitch                = fread(id,1,'float32');	
         RD1016.Heave                = fread(id,1,'float32');
         RD1016.Heading              = fread(id,1,'float32');
    end
end
function WriteAttitude_v01(id,RTH1016,RD1016)
% Contains 158 Bytes
% auto range method  identifier unknown
% auto range filtering Method identifier unknown

if isempty(id)==0
    fwrite(id,RTH1016.NumberOfAttidudeDataSets,'uint8');  
    for i=1:RTH1016.NumberOfAttidudeDataSets
         fwrite(id,RD1016.dTFromRecordTimestamp,'uint16');
         fwrite(id,RD1016.Roll,'float32');
         fwrite(id,RD1016.Pitch,'float32');	
         fwrite(id,RD1016.Heave,'float32');
         fwrite(id,RD1016.Heading,'float32');
    end
end
end

function [RTH1017]=ReadPanTilt_v01(id)
% Contains 8 Bytes
	RTH1017.Pan	    =fread(id,1,'float32');		% (0)
	RTH1017.Tilt	=fread(id,1,'float32');		% (4)
end
function WritePanTilt_v01(id,RTH1017)
% Contains 8 Bytes
if isempty(id)==0
	fwrite(id,RTH1017.Pan,'float32');		% (0)
	fwrite(id,RTH1017.Pan,'float32');		% (4)
end
end

function [RTH7000,SamplingRate]=ReadSonarSettings_v01(id)
% Contains 158 Bytes
% auto range method  identifier unknown
% auto range filtering Method identifier unknown

    RTH7000.SonarId=fread(id,1,'uint64');            % (0)
    RTH7000.PingNumber=fread(id,1,'uint32');         % (8)
    RTH7000.MultiPingsequence=fread(id,1,'uint16');  % (12)

    chunk = fread(id,4,'float32');
    RTH7000.Frequency         =chunk(1); % (14)
    RTH7000.SampleRate        =chunk(2); % (18)
    RTH7000.ReceiverBandwidth =chunk(3); % (22)
    RTH7000.TxPulsWidth       =chunk(4); % (26)
    
    RTH7000.TxPulsTypeIdentifier     = fread(id,1,'uint32');     % (30)
    RTH7000.TxPulsEnvelopeIdentifier = fread(id,1,'uint32');     % (34)
    RTH7000.TxPulsEnvelopeParameter  = fread(id,1,'float32');    % (38)
    RTH7000.TxPulsreserved           = fread(id,1,'uint32');     % (42)

    chunk = fread(id,5,'float32');
    RTH7000.MaxPingRate     =chunk(1); % (46)
    RTH7000.PingPeriod      =chunk(2); % (50)
    RTH7000.RangeSelection  =chunk(3); % (54)
    RTH7000.PowerSelection  =chunk(4); % (58)
    RTH7000.GainSelection   =chunk(5); % (62)

    % Control Flag
        RTH7000.ControlFlags.ReservedForAutoRangeMathod                 = fread(id,4,'*ubit1'); % (0) 
        RTH7000.ControlFlags.ReservedForAutoBottomDetectionFilterMethod = fread(id,4,'*ubit1'); % (4) 
        RTH7000.ControlFlags.BottomDetectionRangeFilterEnabled          = fread(id,1,'*ubit1'); % (8) 
        RTH7000.ControlFlags.BottomDetectionDepthFilterEnabled          = fread(id,1,'*ubit1'); % (9) 
        RTH7000.ControlFlags.ReceiverGainMethodAutoGain                 = fread(id,1,'*ubit1'); % (10)
        RTH7000.ControlFlags.ReceiverGainMethodFixedGain                = fread(id,1,'*ubit1'); % (11)
        RTH7000.ControlFlags.ReceiverGainMethodReserved                 = fread(id,1,'*ubit1'); % (12)
        RTH7000.ControlFlags.Reserved                                   = fread(id,2,'*ubit1'); % (13)
        RTH7000.ControlFlags.SystemActive                               = fread(id,1,'*ubit1'); % (15)
        RTH7000.ControlFlags.ReservedForBottomDetection                 = fread(id,6,'*ubit1'); % (16)
        RTH7000.ControlFlags.AdabtiveGate                               = fread(id,1,'*ubit1'); % (22)
        RTH7000.ControlFlags.AdabtiveGateDepthFilter                    = fread(id,1,'*ubit1'); % (23)  
        RTH7000.ControlFlags.TriggerOut                                 = fread(id,1,'*ubit1'); % (24)
        RTH7000.ControlFlags.TriggerInEdge                              = fread(id,1,'*ubit1'); % (25)
        RTH7000.ControlFlags.PPSEdge                                    = fread(id,1,'*ubit1'); % (26)
        RTH7000.ControlFlags.TimeStampState                             = fread(id,2,'*ubit1'); % (27)
        RTH7000.ControlFlags.Reserved1                                  = fread(id,2,'*ubit1'); % (29)  
        RTH7000.ControlFlags.Modus                                      = fread(id,1,'*ubit1'); % (31)
    
    RTH7000.ProjectorIdentifier =fread(id,1,'uint32');  % (70)
    
    chunk = fread(id,5,'float32');
    RTH7000.ProjectorBeamSteeringAnlgeVertical   =chunk(1); % (74)
    RTH7000.ProjectorBeamSteeringAnlgeHorizontal =chunk(2); % (78)
    RTH7000.ProjectorBeam3dBBeamWidthVertical    =chunk(3); % (82)
    RTH7000.ProjectorBeam3dBBeamWidthHorizontal  =chunk(4); % (86)
    RTH7000.ProjectorBeamFocalPoint              =chunk(5); % (90)
    
    RTH7000.ProjectorBeamWeightingWindowType      =fread(id,1,'uint32');  % (94)
    RTH7000.ProjectorBeamWeightingWindowParameter =fread(id,1,'float32'); % (98) 
    RTH7000.TransmitFlags                         =fread(id,1,'uint32');  % (102)
    RTH7000.HydrophoneIdentifier                  =fread(id,1,'uint32');  % (106)
    RTH7000.ReceiveBeamWeightingWindow            =fread(id,1,'uint32');  % (110)   
    RTH7000.ReceiveBeamWeightingParameter         =fread(id,1,'float32'); % (114)   
   
    % Receive Flags Bit field                                                  % (118)
    RTH7000.ReceiveFlags.RollCompensationIndicator                  = fread(id,1,'*ubit1'); % (0) 
    RTH7000.ReceiveFlags.Reserved2                                  = fread(id,1,'*ubit1'); % (1) 
    RTH7000.ReceiveFlags.HeaveCompensationIndicator                 = fread(id,1,'*ubit1'); % (2) 
    RTH7000.ReceiveFlags.Reserved3                                  = fread(id,1,'*ubit1'); % (3) 
    RTH7000.ReceiveFlags.DynamicFocusingMethod                      = fread(id,4,'*ubit1'); % (4)
    RTH7000.ReceiveFlags.DopplerCompensationMethod                  = fread(id,4,'*ubit1'); % (8)
    RTH7000.ReceiveFlags.MatchFilteringMethod                       = fread(id,4,'*ubit1'); % (12)
    RTH7000.ReceiveFlags.TVGMethod                                  = fread(id,4,'*ubit1'); % (16);
    RTH7000.ReceiveFlags.MultiPingMode                              = fread(id,4,'*ubit1'); % (20)
    RTH7000.ReceiveFlags.ReceiverGainMethodReserved                 = fread(id,8,'*ubit1'); % (24)
    
    chunk = fread(id,8,'float32');
    RTH7000.ReceiveBeamWidth                   =chunk(1); % (122)
    RTH7000.BottomDetectionFilterInfoMinRange  =chunk(2); % (126)
    RTH7000.BottomDetectionFilterInfoMaxRange  =chunk(3); % (130)
    RTH7000.BottomDetectionFilterInfoMinDepth  =chunk(4); % (134)
    RTH7000.BottomDetectionFilterInfoMaxDepth  =chunk(5); % (138)
    RTH7000.Absorption                         =chunk(6); % (142)
    RTH7000.SoundVelocity                      =chunk(7); % (146)
    RTH7000.Spreading                          =chunk(8); % (150)
    
    RTH7000.Reserved4                           =fread(id,1,'uint16'); % (154)
    
    SamplingRate=RTH7000.SampleRate;
    
end
function WriteSonarSettings_v01(id,RTH7000)
% Contains 158 Bytes
% auto range method  identifier unknown
% auto range filtering Method identifier unknown
if isempty(id)==0
    fwrite(id,RTH7000.SonarId,'uint64');            % (0)
    fwrite(id,RTH7000.PingNumber,'uint32');         % (8)
    fwrite(id,RTH7000.MultiPingsequence,'uint16');  % (12)

    fwrite(id,RTH7000.Frequency,'float32');         % (14)
    fwrite(id,RTH7000.SampleRate,'float32');        % (18)
    fwrite(id,RTH7000.ReceiverBandwidth,'float32'); % (22)
    fwrite(id,RTH7000.TxPulsWidth,'float32');       % (26)
    
    fwrite(id,RTH7000.TxPulsTypeIdentifier,'uint32');        % (30)
    fwrite(id,RTH7000.TxPulsEnvelopeIdentifier,'uint32');    % (34)
    fwrite(id,RTH7000.TxPulsEnvelopeParameter,'float32');    % (38)
    fwrite(id,RTH7000.TxPulsreserved,'uint32');              % (42)

    fwrite(id,RTH7000.MaxPingRate,'float32');    % (46)
    fwrite(id,RTH7000.PingPeriod,'float32');     % (50)
    fwrite(id,RTH7000.RangeSelection,'float32'); % (54)
    fwrite(id,RTH7000.PowerSelection,'float32'); % (58)
    fwrite(id,RTH7000.GainSelection,'float32'); % (62)

    % Control Flag 4 Bytes = 32 Bits
        fwrite(id,RTH7000.ControlFlags.ReservedForAutoRangeMathod,'*ubit1');                 % (0) 
        fwrite(id,RTH7000.ControlFlags.ReservedForAutoBottomDetectionFilterMethod,'*ubit1'); % (4) 
        fwrite(id,RTH7000.ControlFlags.BottomDetectionRangeFilterEnabled ,'*ubit1');         % (8) 
        fwrite(id,RTH7000.ControlFlags.BottomDetectionDepthFilterEnabled,'*ubit1');          % (9) 
        fwrite(id,RTH7000.ControlFlags.ReceiverGainMethodAutoGain,'*ubit1');                 % (10)
        fwrite(id,RTH7000.ControlFlags.ReceiverGainMethodFixedGain,'*ubit1');                % (11)
        fwrite(id,RTH7000.ControlFlags.ReceiverGainMethodReserved,'*ubit1');                 % (12)
        fwrite(id,RTH7000.ControlFlags.Reserved,'*ubit1');                                   % (13)
        fwrite(id,RTH7000.ControlFlags.SystemActive,'*ubit1');                               % (15)
        fwrite(id,RTH7000.ControlFlags.ReservedForBottomDetection,'*ubit1');                 % (16)
        fwrite(id,RTH7000.ControlFlags.AdabtiveGate,'*ubit1');                               % (22)
        fwrite(id,RTH7000.ControlFlags.AdabtiveGateDepthFilter,'*ubit1');                    % (23)  
        fwrite(id,RTH7000.ControlFlags.TriggerOut,'*ubit1');                                 % (24)
        fwrite(id,RTH7000.ControlFlags.TriggerInEdge,'*ubit1');                              % (25)
        fwrite(id,RTH7000.ControlFlags.PPSEdge,'*ubit1');                                    % (26)
        fwrite(id,RTH7000.ControlFlags.TimeStampState,'*ubit1');                             % (27)
        fwrite(id,RTH7000.ControlFlags.Reserved1,'*ubit1');                                  % (29)  
        fwrite(id,RTH7000.ControlFlags.Modus,'*ubit1');                                      % (31)
    
    fwrite(id,RTH7000.ProjectorIdentifier,'uint32');                   % (70)
    fwrite(id,RTH7000.ProjectorBeamSteeringAnlgeVertical,'float32');   % (74)
    fwrite(id,RTH7000.ProjectorBeamSteeringAnlgeHorizontal,'float32'); % (78)
    fwrite(id,RTH7000.ProjectorBeam3dBBeamWidthVertical,'float32');    % (82)
    fwrite(id,RTH7000.ProjectorBeam3dBBeamWidthHorizontal,'float32');  % (86)
    fwrite(id,RTH7000.ProjectorBeamFocalPoint ,'float32');             % (90)
    
    fwrite(id,RTH7000.ProjectorBeamWeightingWindowType,'uint32');       % (94)
    fwrite(id,RTH7000.ProjectorBeamWeightingWindowParameter,'float32'); % (98) 
    fwrite(id,RTH7000.TransmitFlags,'uint32');                          % (102)
    fwrite(id,RTH7000.HydrophoneIdentifier,'uint32');                   % (106)
    fwrite(id, RTH7000.ReceiveBeamWeightingWindow,'uint32');            % (110)   
    fwrite(id,RTH7000.ReceiveBeamWeightingParameter,'float32');         % (114)   
   
    % Receive Flags Bit field                                                   % (118)
    fwrite(id,RTH7000.ReceiveFlags.RollCompensationIndicator,'*ubit1');  % (0) 
    fwrite(id,RTH7000.ReceiveFlags.Reserved2,'*ubit1');                  % (1) 
    fwrite(id,RTH7000.ReceiveFlags.HeaveCompensationIndicator,'*ubit1'); % (2) 
    fwrite(id,RTH7000.ReceiveFlags.Reserved3,'*ubit1');                  % (3) 
    fwrite(id,RTH7000.ReceiveFlags.DynamicFocusingMethod,'*ubit1');      % (4)
    fwrite(id,RTH7000.ReceiveFlags.DopplerCompensationMethod,'*ubit1');  % (8)
    fwrite(id,RTH7000.ReceiveFlags.MatchFilteringMethod,'*ubit1');       % (12)
    fwrite(id,RTH7000.ReceiveFlags.TVGMethod,'*ubit1');                  % (16);
    fwrite(id,RTH7000.ReceiveFlags.MultiPingMode,'*ubit1');              % (20)
    fwrite(id,RTH7000.ReceiveFlags.ReceiverGainMethodReserved,'*ubit1'); % (24)
    
    fwrite(id,RTH7000.ReceiveBeamWidth,'float32'); % (122)
    fwrite(id,RTH7000.BottomDetectionFilterInfoMinRange,'float32'); % (126)
    fwrite(id,RTH7000.BottomDetectionFilterInfoMaxRange,'float32'); % (130)
    fwrite(id,RTH7000.BottomDetectionFilterInfoMinDepth,'float32'); % (134)
    fwrite(id,RTH7000.BottomDetectionFilterInfoMaxDepth,'float32'); % (138)
    fwrite(id,RTH7000.Absorption,'float32'); % (142)
    fwrite(id,RTH7000.SoundVelocity,'float32'); % (146)
    fwrite(id,RTH7000.Spreading,'float32'); % (150)
   
    fwrite(id,RTH7000.Reserved4,'uint16'); % (154)
    
end 
end

function [RTH7004,RD7004]=ReadBeamGeometry_v01(id)
% RTH	
 	RTH7004.SonarId	=fread(id,1,'uint64');		% (0)
	RTH7004.N       =fread(id,1,'uint32');		% (8)
	
% RD	
    for i=1:RTH7004.N   % loops over all Beams
        RD7004(i).BeamVerticalDirectionAngleN = fread(id,1,'float32');	%#ok<AGROW> (f32)   
        RD7004(i).eamHorizontalDirectionAngleN= fread(id,1,'float32');  %#ok<AGROW> (f32)
        RD7004(i).neg3dBBeamWidthYN           = fread(id,1,'float32');  %#ok<AGROW> (f32)
        RD7004(i).neg3dBBeamWidthXN           = fread(id,1,'float32');  %#ok<AGROW> (f32)
    end  
end
function [RTH7004,RD7004]=WritesBeamGeometry_v01(id,RTH7004,RD7004)
if isempty(id)==0
% RTH	
 	fwrite(id,RTH7004.SonarId,'uint64'); % (0)
	fwrite(id,RTH7004.N,'uint32');		 % (8)	
% RD	
    for i=1:RTH7004.N   % loops over all Beams
        fwrite(id,RD7004(i).BeamVerticalDirectionAngleN,'float32');	% (4)(f32 x N)   
        fwrite(id,RD7004(i).eamHorizontalDirectionAngleN,'float32');% (4)(f32 x N)
        fwrite(id,RD7004(i).neg3dBBeamWidthYN,'float32');           % (4)(f32 x N)
        fwrite(id,RD7004(i).neg3dBBeamWidthXN,'float32');           % (4)(f32 x N)
    end    
end
end

function [RTH7007,RD7007]=ReadSideScanData_v01(id)
% This record is produced by the 7k Center. It contains the non-calibrated
... side-scan type data. This record is typically not available in a 
... forward-looking sonar configuration. The 7k Center updates this data
... for each ping. The
%% ________________________________________________________________________
% RTH	
	RTH7007.SonarId			        =fread(id,1,'uint64');		% (0)
	RTH7007.PingNumber		        =fread(id,1,'uint32');		% (8)
	RTH7007.MultiPingSequence	    =fread(id,1,'uint16');		% (12)
	RTH7007.BeamPosition		    =fread(id,1,'float32');	    % (14)	
	RTH7007.Reserved			    =fread(id,32,'*ubit1');		% (18)  BIT FIELD
	RTH7007.SamplesPerSide		    =fread(id,1,'uint32');		% (22)  S (port/starboard)
	RTH7007.Reserved1			    =fread(id,8,'float32'); 	% (26)	f32*8 
	RTH7007.NumberOfBeamsPerSide    =fread(id,1,'uint16');		% (58)  N
	RTH7007.CurrentBeamNumber	    =fread(id,1,'uint16');		% (60)  0:N-1
	RTH7007.NumberOfBytesPerSample	=fread(id,1,'uint8');		% (62)  W
	RTH7007.DataTypes			    =fread(id,1,'uint8');		% (63)	BIT FIELD

%% ________________________________________________________________________    
% RD	Start at Byte 64
    switch RTH7007.NumberOfBytesPerSample
        case 1
            RD7007.PortBeam       = fread(id,(RTH7007.SamplesPerSide), 'uint8'); %(0)
            RD7007.StarboardBeams = fread(id,(RTH7007.SamplesPerSide), 'uint8'); %(W*S)
        case 2
            RD7007.PortBeam       = fread(id,(RTH7007.SamplesPerSide), 'uint16'); %(0)
            RD7007.StarboardBeams = fread(id,(RTH7007.SamplesPerSide), 'uint16'); %(W*S)
        case 4
            RD7007.PortBeam       = fread(id,(RTH7007.SamplesPerSide), 'uint32'); %(0)
            RD7007.StarboardBeams = fread(id,(RTH7007.SamplesPerSide), 'uint32'); %(W*S)
    end
    
end
function WriteSideScanData_v01(id,RTH7007,RD7007,fixSideScanValue)
% This record is produced by the 7k Center. It contains the non-calibrated
% side-scan type data. This record is typically not available in a 
% forward-looking sonar configuration. The 7k Center updates this data
% for each ping.

if isempty(id)==0
%% ________________________________________________________________________
% RTH	
	fwrite(id,RTH7007.SonarId,'uint64');		        % (0)
	fwrite(id,RTH7007.PingNumber,'uint32');		        % (8)
	fwrite(id,RTH7007.MultiPingSequence,'uint16');		% (12)
	fwrite(id,RTH7007.BeamPosition,'float32');	        % (14)	
	fwrite(id,RTH7007.Reserved,'*ubit1');	            % (18)  BIT FIELD
	fwrite(id,RTH7007.SamplesPerSide,'uint32');		    % (22)  S (port/starboard)
	fwrite(id,RTH7007.Reserved1,'float32'); 	        % (26)	f32*8 
	fwrite(id,RTH7007.NumberOfBeamsPerSide ,'uint16');	% (58)  N
	fwrite(id,RTH7007.CurrentBeamNumber,'uint16');		% (60)  0:N-1
	fwrite(id,RTH7007.NumberOfBytesPerSample,'uint8');  % (62)  W
	fwrite(id,RTH7007.DataTypes,'uint8');		        % (63)	BIT FIELD

%% ________________________________________________________________________    
% RD	Start at Byte 64
    if isempty(fixSideScanValue)==1
        switch RTH7007.NumberOfBytesPerSample
            case 1 % unit8 -> 1*8
                 fwrite(id,RD7007.PortBeam,'uint8');       %(0)
                 fwrite(id,RD7007.StarboardBeams,'uint8'); %(W*S)
            case 2 % unit16 -> 2*8
                 fwrite(id,RD7007.PortBeam,'uint16');       %(0)
                 fwrite(id,RD7007.StarboardBeams,'uint16'); %(W*S)
            case 4 % unit32 -> 4*8
                 fwrite(id,RD7007.PortBeam,'uint32');       %(0)
                 fwrite(id,RD7007.StarboardBeams,'uint32'); %(W*S)
        end
    else
        
        if RTH7007.NumberOfBytesPerSample==1
            if fixSideScanValue>255
                 error('Error caused by -fixSS input option.\nThe selected value "%d" to manipulate SideScan data is out of bounds.\nSidescan Record is predifiend as 8 bit integer (value range 0 to 255)\n',fixSideScanValue);
            end
        elseif RTH7007.NumberOfBytesPerSample==2    
            if fixSideScanValue>65535
                 error('Error caused by -fixSS input option.\nThe selected value "%d" to manipulate SideScan data is out of bounds.\nSidescan Record is predifiend as 16 bit integer (value range 0 to 65535)\n',fixSideScanValue);
            end    
        elseif RTH7007.NumberOfBytesPerSample==3
            if fixSideScanValue>65535
                 error('Error caused by -fixSS input option.\nThe selected value "%d" to manipulate SideScan data is out of bounds.\nSidescan Record is predifiend as 32 bit integer (value range 0 to 4294967295)\n',fixSideScanValue);
            end   
        end
        
        RD7007.PortBeam=ones(size(RD7007.PortBeam)).*fixSideScanValue;
        RD7007.PortBeam=ones(size(RD7007.StarboardBeams)).*fixSideScanValue;
        
        switch RTH7007.NumberOfBytesPerSample
            case 1 % unit8 -> 1*8
                 fwrite(id,RD7007.PortBeam,'uint8');       %(0)
                 fwrite(id,RD7007.StarboardBeams,'uint8'); %(W*S)
            case 2 % unit16 -> 2*8
                 fwrite(id,RD7007.PortBeam,'uint16');       %(0)
                 fwrite(id,RD7007.StarboardBeams,'uint16'); %(W*S)
            case 4 % unit32 -> 4*8
                 fwrite(id,RD7007.PortBeam,'uint32');       %(0)
                 fwrite(id,RD7007.StarboardBeams,'uint32'); %(W*S)
       end
        
   end
end   
end

function [RTF7027,RD7027]=ReadRawBathymetry_v01(id)
% Contains  Bytes
% Quality Control in RD is still unclear

% RTH Header contains 99 Bytes
	RTF7027.SonarId                   =fread(id,1,'uint64');	  % (0)
	RTF7027.PingNumber                =fread(id,1,'uint32');	  % (8)
	RTF7027.MultiPingSequence         =fread(id,1,'uint16');      % (12)
    RTF7027.NrOfDetectionPoints       =fread(id,1,'uint32');	  % (14)
    RTF7027.DataFieldSize             =fread(id,1,'uint32');      % (18)
	RTF7027.DetectionAlgorithm        =fread(id,1,'uint8');       % (22)
 
    % Flag BIT Field                                              
    RTF7027.Flags.UncertaintyMethod          = fread(id,4,'*ubit1');     % (0)
    RTF7027.Flags.MultiDetectionEnable       = fread(id,1,'*ubit1');     % (4)
    RTF7027.Flags.Reserved1                  = fread(id,1,'*ubit1');     % (5)
    RTF7027.Flags.SnippetsDetectionPointFlag = fread(id,1,'*ubit1');     % (6)
    RTF7027.Flags.ReservedForFutureUse       = fread(id,25,'*ubit1');    % (7) 
    
	RTF7027.SamplingRate           =fread(id,1,'float32');		  % (27)
	RTF7027.TxAngle			       =fread(id,1,'float32');		  % (31)
    RTF7027.AppliedRoll	           =fread(id,1,'float32');		  % (35)
 	RTF7027.Reserved2			   =fread(id,15,'uint32');		  % (39) 15*4

% RD 100:end-4
% Read Data Traces total length 20 bytes
    for i = 1: RTF7027.NrOfDetectionPoints
        RD7027(i).BeamDescriptor                        = fread(id,1,'uint16');	    %#ok<AGROW> % (100)
        RD7027(i).DetectionPoint                        = fread(id,1,'float32');    %#ok<AGROW>
        RD7027(i).RxAngle                               = fread(id,1,'float32');    %#ok<AGROW> 
        RD7027(i).Flags.MagnitudeBasedDetection         = fread(id,1,'*ubit1'); %#ok<AGROW>
        RD7027(i).Flags.PhaseBasedDetection             = fread(id,1,'*ubit1'); %#ok<AGROW>
        RD7027(i).Flags.QualtiyType                     = fread(id,7,'*ubit1'); %#ok<AGROW>
        RD7027(i).Flags.DetectionPriorityWithinSameBeam = fread(id,4,'*ubit1'); %#ok<AGROW>
        RD7027(i).Flags.Reserved                        = fread(id,1,'*ubit1'); %#ok<AGROW>
        RD7027(i).Flags.SnippetDetectionPointFlag       = fread(id,1,'*ubit1'); %#ok<AGROW>
        RD7027(i).Flags.Reserved2                       = fread(id,17,'*ubit1');%#ok<AGROW>
    
        RD7027(i).Quality.QualityNotAvailableOrUsed          = fread(id,1,'*ubit1');  %#ok<AGROW>
        RD7027(i).Quality.BrightnesOrColinearityFilterPassed = fread(id,1,'*ubit1');  %#ok<AGROW>
        RD7027(i).Quality.Reserved                           = fread(id,30,'*ubit1'); %#ok<AGROW> 
       
        RD7027(i).Uncertainty          = fread(id,1,'float32');  %#ok<AGROW>   
        RD7027(i).SignalStrength       = fread(id,1,'float32');  %#ok<AGROW>
    end
    
end
function WriteRawBathymetry_v01(id,RTF7027,RD7027)
% Contains  Bytes
% Quality Control in RD is still unclear
if isempty(id)==0
% RTH Header contains 99 Bytes
	fwrite(id,RTF7027.SonarId,'uint64');	             % (0)
	fwrite(id,RTF7027.PingNumber,'uint32');	             % (8)
	fwrite(id,RTF7027.MultiPingSequence,'uint16');       % (12)
    fwrite(id,RTF7027.NrOfDetectionPoints ,'uint32');	 % (14)
    fwrite(id,RTF7027.DataFieldSize,'uint32');           % (18)
	fwrite(id,RTF7027.DetectionAlgorithm,'uint8');       % (22)
 
    % Flag BIT Field                                              
    fwrite(id,RTF7027.Flags.UncertaintyMethod,'*ubit1');          % (0)
    fwrite(id,RTF7027.Flags.MultiDetectionEnable,'*ubit1');       % (4)
    fwrite(id,RTF7027.Flags.Reserved1,'*ubit1');                  % (5)
    fwrite(id,RTF7027.Flags.SnippetsDetectionPointFlag,'*ubit1'); % (6)
    fwrite(id,RTF7027.Flags.ReservedForFutureUse,'*ubit1');       % (7) 
    
	fwrite(id,RTF7027.SamplingRate,'float32');    % (27)
	fwrite(id,RTF7027.TxAngle,'float32');		  % (31)
    fwrite(id,RTF7027.AppliedRoll,'float32');     % (35)
 	fwrite(id,RTF7027.Reserved2,'uint32');		  % (39) 15*4

% RD 100:end-4
% Read Data Traces total length 20 bytes
    for i = 1: RTF7027.NrOfDetectionPoints
        fwrite(id,RD7027(i).BeamDescriptor,'uint16');	    % (100)
        fwrite(id,RD7027(i).DetectionPoint,'float32');    
        fwrite(id,RD7027(i).RxAngle,'float32');     
        fwrite(id,RD7027(i).Flags.MagnitudeBasedDetection,'*ubit1');  
        fwrite(id,RD7027(i).Flags.PhaseBasedDetection ,'*ubit1'); 
        fwrite(id,RD7027(i).Flags.QualtiyType,'*ubit1'); 
        fwrite(id,RD7027(i).Flags.DetectionPriorityWithinSameBeam,'*ubit1'); 
        fwrite(id,RD7027(i).Flags.Reserved,'*ubit1'); 
        fwrite(id,RD7027(i).Flags.SnippetDetectionPointFlag,'*ubit1'); 
        fwrite(id,RD7027(i).Flags.Reserved2,'*ubit1');
    
        fwrite(id,RD7027(i).Quality.QualityNotAvailableOrUsed ,'*ubit1'); 
        fwrite(id,RD7027(i).Quality.BrightnesOrColinearityFilterPassed,'*ubit1');
        fwrite(id,RD7027(i).Quality.Reserved,'*ubit1');   
       
        fwrite(id,RD7027(i).Uncertainty,'float32');     
        fwrite(id,RD7027(i).SignalStrength,'float32');
    end
end

end

function [RTH7028,RD7028]=ReadSnippetData_v01(id)
% Reads raw Snippet data from s7k
%% ________________________________________________________________________             
% RTH Header 
	RTH7028.SonarId		     	   =fread(id,1,'uint64');		% (0)
	RTH7028.PingNumber		       =fread(id,1,'uint32');		% (8)
	RTH7028.MultiPingSequence	   =fread(id,1,'uint16');		% (12)
    RTH7028.NumberOfDetectionPoint =fread(id,1,'uint16');		% (14)
    
    RTH7028.ErrorFlag              = fread(id,1,'uint8');       % (16) 
    
    RTH7028.ControlFlag.AutomaticSnippetWindowIsUsed  =fread(id,1,'*ubit1'); 
    RTH7028.ControlFlag.QualityFilterEnabled          =fread(id,1,'*ubit1'); 
    RTH7028.ControlFlag.MinimumWindowSizeIsRequired   =fread(id,1,'*ubit1'); 
    RTH7028.ControlFlag.MaximumWindowSizeIsRequired   =fread(id,1,'*ubit1'); 
    RTH7028.ControlFlag.Reserved                      =fread(id,4,'*ubit1');    % here !!! BIT FIELD !!!
   
    % Read Data Traces total length 20 bytes !!! NO BIT FIELD !!! % 7*4 uint32       
    RTH7028.Reserved			   = fread(id,7,'uint32');		% (18) 
                                                                   %   .
%% ________________________________________________________________________             
% RD Record data                                          
    for i=1:RTH7028.NumberOfDetectionPoint       
        RD7028(i).BeamDescriptor  =fread(id,1,'uint16');	%#ok<AGROW>  (0)
        RD7028(i).SnippetStart    =fread(id,1,'uint32');	%#ok<AGROW>  (2)
        RD7028(i).DetectionSample =fread(id,1,'uint32');	%#ok<AGROW>  (4)
        RD7028(i).SnippetEnd      =fread(id,1,'uint32');	%#ok<AGROW>  (10:14)  
    end
    % End-StartSnippet +1. "+1" because entry starts at 0       
    for i=1:RTH7028.NumberOfDetectionPoint  
        NumberOFSamplesInSnippet=RD7028(i).SnippetEnd-...
            RD7028(i).SnippetStart+1;
        RD7028(i).Snippet=fread(id,NumberOFSamplesInSnippet, 'uint16');
    end   
end
function WriteSnippetData_v01(id,RTH7028,RD7028)
% Reads raw Snippet data from s7k

%% ________________________________________________________________________             
% RTH Header 
if isempty(id)==0
	fwrite(id,RTH7028.SonarId,'uint64');	            % (0)
	fwrite(id,RTH7028.PingNumber,'uint32');	        	% (8)
	fwrite(id,RTH7028.MultiPingSequence,'uint16');		% (12)
    fwrite(id,RTH7028.NumberOfDetectionPoint,'uint16'); % (14)
    
    fwrite(id,RTH7028.ErrorFlag ,'uint8');             % (16) % here !!! BIT FIELD !!!
    
    fwrite(id,RTH7028.ControlFlag.AutomaticSnippetWindowIsUsed,'*ubit1'); 
    fwrite(id,RTH7028.ControlFlag.QualityFilterEnabled,'*ubit1'); 
    fwrite(id,RTH7028.ControlFlag.MinimumWindowSizeIsRequired,'*ubit1'); 
    fwrite(id,RTH7028.ControlFlag.MaximumWindowSizeIsRequired,'*ubit1'); 
    fwrite(id,RTH7028.ControlFlag.Reserved,'*ubit1');    % here !!! BIT FIELD !!!
   
    % Read Data Traces total length 20 bytes !!! NO BIT FIELD !!! % 7*4 uint32       
    fwrite(id,RTH7028.Reserved,'uint32');		% (18) 
                                                                   %   .
%% ________________________________________________________________________             
% RD Record data                                          
    for i=1:RTH7028.NumberOfDetectionPoint       
        fwrite(id,RD7028(i).BeamDescriptor,'uint16');	% (0)
        fwrite(id,RD7028(i).SnippetStart,'uint32');   	% (2)
        fwrite(id,RD7028(i).DetectionSample,'uint32');	% (4)
        fwrite(id,RD7028(i).SnippetEnd,'uint32');	    % (10:14)  
    end
    % End-StartSnippet +1. "+1" because entry starts at 0       
    for i=1:RTH7028.NumberOfDetectionPoint  
        fwrite(id,RD7028(i).Snippet,'uint16');
    end
end
end

function [RTH7042,RD7042]=ReadCompressedWatercolomnData_v01(id)
% Description: This record is produced by the 7k sonar source series. 
...It contains compressed water column data. The 7k sonar source updates 
...this record on every ping. This record is available by subscription
...only. For details about requesting and subscribing to records, see 
...section 10.62 7500 – Remote Control together with section 11 7k Remote 
...Control Definitions.

%%_________________________________________________________________________
% RTH	
	RTH7042.SonarId			    =fread(id,1,'uint64');		% (0)
	RTH7042.PingNumber		    =fread(id,1,'uint32');		% (8)
	RTH7042.MultiPingSequence	=fread(id,1,'uint16');		% (12)
	RTH7042.NumberOfBeam		=fread(id,1,'uint16');		% (14)	
	RTH7042.NrOfSamples 	    =fread(id,1,'uint32');		% (16)
  	RTH7042.CompressedSamples 	=fread(id,1,'uint32');		% (20)
    
    % BIT FIELD 24-27                                       % 'uint32'  (24)         
    RTH7042.Flags.UseMaximumBottomDetectionPoint   = fread(id,1,'*ubit1');   % (0)
    RTH7042.Flags.IncludeIntensityDataOnly         = fread(id,1,'*ubit1');   % (1)
    RTH7042.Flags.ConvertMagTodB                   = fread(id,1,'*ubit1');   % (2)
    RTH7042.Flags.Reserved1                        = fread(id,1,'*ubit1');   % (3) 
    RTH7042.Flags.DownsamplingDivisor              = fread(id,4,'*ubit1');   % (4-7) has to be taken bi2dec. 2-16 is possible 
    RTH7042.Flags.DownsamplingType                 = fread(id,4,'*ubit1');   % (8-11) has to be taken bi2dec
    RTH7042.Flags.BitType32                        = fread(id,1,'*ubit1');   % (12)
    RTH7042.Flags.CompressionFactorAvailable       = fread(id,1,'*ubit1');   % (13)
    RTH7042.Flags.SegmentNumbersAvailable          = fread(id,1,'*ubit1');   % (14)
    RTH7042.Flags.FirstSampleContainsRxDelayValue  = fread(id,1,'*ubit1');   % (15)                                                     % (15-31);
    RTH7042.Flags.reserved2                        = fread(id,16,'*ubit1');   %(16)
    
	RTH7042.FirstSampleIncludedForEachBeam		   = fread(id,1,'uint32');    % (28)
	RTH7042.SampleRate			                   = fread(id,1,'float32');   % (32)	
    RTH7042.CompressionFactor                      = fread(id,1,'float32');	  % (36)
    RTH7042.Reserved	                           = fread(id,1,'uint32');    % (40)

    % wenn man + 16 bit rechnet kommt bei BeamNumberForThisData 1101
    % rauswas eigentlich bei NumberOfSamples auskommen sollte
%%_________________________________________________________________________
% Each “Sample�? may be one of the following, depending on the Flags bits:
% if Flag bit 2 is set  -> only 8 bit data
% if Flag bit 12 is set -> only 32 bit data
% else 16 bit data
% if Flag 1 is set 1    -> only intensity data
%     A) 16 bit Mag & 16bit Phase (32 bits total)
%     B) 16 bit Mag (16 bits total, no phase)
%     C) 8 bit Mag & 8 bit Phase (16 bits total)
%     D) 8 bit Mag (8 bits total, no phase) 
%     E) 32 bit Mag & 8 bit Phase(40 bits total) 
%     F) 32 bit Mag(32 bits total, no phase)

SampleFormatIdentifier= [RTH7042.Flags.IncludeIntensityDataOnly;...
                         RTH7042.Flags.ConvertMagTodB;...
                         RTH7042.Flags.BitType32];                                         
SampleFormatIdentifier= bi2de(SampleFormatIdentifier);
           
  for i=1:RTH7042.NumberOfBeam
    RD7042(i).BeamNumberForThisData                   =fread(id,1,'uint16');   %#ok<AGROW> % (44)
    if RTH7042.Flags.SegmentNumbersAvailable==1
        RD7042(i).SegementNumber                      =fread(id,1,'uint8');    %#ok<AGROW> % (46)
    end
    RD7042(i).NumberOfSamples                         =fread(id,1,'uint32');   %#ok<AGROW> % (47)
    switch SampleFormatIdentifier
        case 0  % A) 16 bit Mag & 16bit Phase (32 bits total)
            RD7042(i).Magnitude= fread(id,RD7042(i).NumberOfSamples ,'uint16'); %#ok<AGROW>  % (47)
            RD7042(i).Phase    = fread(id,RD7042(i).NumberOfSamples ,'uint16'); %#ok<AGROW>  % (47)
        case 1  % B) 16 bit Mag (16 bits total, no phase)
            RD7042(i).Magnitude= fread(id,RD7042(i).NumberOfSamples ,'uint16'); %#ok<AGROW>  % (47)       
        case 2  % C) 8 bit Mag & 8 bit Phase (16 bits total)
            RD7042(i).Magnitude= fread(id,RD7042(i).NumberOfSamples ,'uint8');  %#ok<AGROW> % (47)
            RD7042(i).Phase    = fread(id,RD7042(i).NumberOfSamples ,'uint8');  %#ok<AGROW> % (47)      
        case 3  % D) 8 bit Mag (8 bits total, no phase)
            RD7042(i).Magnitude= fread(id,RD7042(i).NumberOfSamples ,'uint8');  %#ok<AGROW> % (47)         
        case 4  % E) 32 bit Mag & 8 bit Phase(40 bits total)
            RD7042(i).Magnitude= fread(id,RD7042(i).NumberOfSamples ,'uint32'); %#ok<AGROW> % (47)
            RD7042(i).Phase    = fread(id,RD7042(i).NumberOfSamples ,'uint8');  %#ok<AGROW> % (47)  
        case 5  % F) 32 bit Mag(32 bits total, no phase)
            RD7042(i).Magnitude= fread(id,RD7042(i).NumberOfSamples ,'uint32'); %#ok<AGROW> % (47)
    end  
  end

end
function WriteCompressedWatercolomnData_v01(id,RTH7042,RD7042)
% Description: This record is produced by the 7k sonar source series. 
...It contains compressed water column data. The 7k sonar source updates 
...this record on every ping. This record is available by subscription
...only. For details about requesting and subscribing to records, see 
...section 10.62 7500 – Remote Control together with section 11 7k Remote 
...Control Definitions.
if isempty(id)==0
%%_________________________________________________________________________
% RTH	
	fwrite(id,RTH7042.SonarId,'uint64');		    % (0)
	fwrite(id,RTH7042.PingNumber,'uint32');		    % (8)
	fwrite(id,RTH7042.MultiPingSequence,'uint16');  % (12)
	fwrite(id,RTH7042.NumberOfBeam,'uint16');		% (14)	
	fwrite(id,RTH7042.NrOfSamples,'uint32');		% (16)
  	fwrite(id,RTH7042.CompressedSamples,'uint32');	% (20)
    
    % BIT FIELD 24-27                                       % 'uint32'  (24)         
    fwrite(id,RTH7042.Flags.UseMaximumBottomDetectionPoint,'*ubit1');   % (0)
    fwrite(id,RTH7042.Flags.IncludeIntensityDataOnly,'*ubit1');   % (1)
    fwrite(id,RTH7042.Flags.ConvertMagTodB,'*ubit1');   % (2)
    fwrite(id,RTH7042.Flags.Reserved1,'*ubit1');   % (3) 
    fwrite(id,RTH7042.Flags.DownsamplingDivisor,'*ubit1');   % (4-7)
    fwrite(id,RTH7042.Flags.DownsamplingType,'*ubit1');   % (8-11)
    fwrite(id,RTH7042.Flags.BitType32,'*ubit1');   % (12)
    fwrite(id,RTH7042.Flags.CompressionFactorAvailable,'*ubit1');   % (13)
    fwrite(id,RTH7042.Flags.SegmentNumbersAvailable,'*ubit1');   % (14)
    fwrite(id,RTH7042.Flags.FirstSampleContainsRxDelayValue,'*ubit1');   % (15)                                                     % (15-31);
    fwrite(id,RTH7042.Flags.reserved2,'*ubit1');   %(16)
    
	fwrite(id,RTH7042.FirstSampleIncludedForEachBeam,'uint32');    % (28)
	fwrite(id,RTH7042.SampleRate,'float32');   % (32)	
    fwrite(id,RTH7042.CompressionFactor,'float32');	  % (36)
    fwrite(id,RTH7042.Reserved,'uint32');    % (40)

%%_________________________________________________________________________
% Each “Sample�? may be one of the following, depending on the Flags bits:
% if Flag bit 2 is set  -> only 8 bit data
% if Flag bit 12 is set -> only 32 bit data
% else 16 bit data
% if Flag 1 is set 1    -> only intensity data
%     A) 16 bit Mag & 16bit Phase (32 bits total)
%     B) 16 bit Mag (16 bits total, no phase)
%     C) 8 bit Mag & 8 bit Phase (16 bits total)
%     D) 8 bit Mag (8 bits total, no phase) 
%     E) 32 bit Mag & 8 bit Phase(40 bits total) 
%     F) 32 bit Mag(32 bits total, no phase)

SampleFormatIdentifier= [RTH7042.Flags.IncludeIntensityDataOnly;...
                         RTH7042.Flags.ConvertMagTodB;...
                         RTH7042.Flags.BitType32];                                         
SampleFormatIdentifier= bi2de(SampleFormatIdentifier);
           
  for i=1:RTH7042.NumberOfBeam
      
    fwrite(id,RD7042(i).BeamNumberForThisData,'uint16');  % (44)
    if RTH7042.Flags.SegmentNumbersAvailable==1
        fwrite(id,RD7042(i).SegementNumber,'uint8');      % (46) || not existent
    end
    fwrite(id,RD7042(i).NumberOfSamples,'uint32');        % (47) || (46)

    switch SampleFormatIdentifier
        case 0  % A) 16 bit Mag & 16bit Phase (32 bits total)
            fwrite(id,RD7042(i).Magnitude,'uint16');      
            fwrite(id,RD7042(i).Phase ,'uint16');         
        case 1  % B) 16 bit Mag (16 bits total, no phase)
            fwrite(id,RD7042(i).Magnitude ,'uint16');        
        case 2  % C) 8 bit Mag & 8 bit Phase (16 bits total)
            fwrite(id,RD7042(i).Magnitude ,'uint8');      
            fwrite(id,RD7042(i).Phase ,'uint8');          
        case 3  % D) 8 bit Mag (8 bits total, no phase)
            fwrite(id,RD7042(i).Magnitude ,'uint8');      
        case 4  % E) 32 bit Mag & 8 bit Phase(40 bits total)
            fwrite(id,RD7042(i).Magnitude ,'uint32');     
            fwrite(id,RD7042(i).Phase ,'uint8');         
        case 5  % F) 32 bit Mag(32 bits total, no phase)
            fwrite(id,RD7042(i).Magnitude ,'uint32');     
    end
  end
end
end

function [RTH7058,RD7058]=ReadCalibratedSnippetData_v01(id)
% Reads Calibrated Backscatter data from data

%% ________________________________________________________________________             
% RTH Header 

	RTH7058.SonarId		     	   =fread(id,1,'uint64');		% (0)
	RTH7058.PingNumber		       =fread(id,1,'uint32');		% (8)
	RTH7058.MultiPingSequence	   =fread(id,1,'uint16');		% (12)
    RTH7058.NumberOfBeamsInRecord  =fread(id,1,'uint16');		% (14)
  
    RTH7058.ErrorFlag              = fread(id,1,'uint8');      % (16)   % here !!! BIT FIELD !!!
    
    RTH7058.ControlFlag.BrightnessIsRequiredToPass               =fread(id,1,'*ubit1'); 
    RTH7058.ControlFlag.ColinearityIsRequiredToPass              =fread(id,1,'*ubit1'); 
    RTH7058.ControlFlag.BottomDetectionResultsAreUsedForSnippet  =fread(id,1,'*ubit1'); 
    RTH7058.ControlFlag.SnippetDisplayMinRequirementsAreUsed     =fread(id,1,'*ubit1'); 
    RTH7058.ControlFlag.MinimumWindowSizeIsRequired              =fread(id,1,'*ubit1');
    RTH7058.ControlFlag.MaximumWindowSizeIsRequired              =fread(id,1,'*ubit1');
    RTH7058.ControlFlag.FootprintAreasAreIncluded                =fread(id,1,'*ubit1');
    RTH7058.ControlFlag.GenericCompensationNotPerUnit            =fread(id,1,'*ubit1');
    RTH7058.ControlFlag.SingleAbsorptionValueUsedForTheWholePing =fread(id,1,'*ubit1');
    RTH7058.ControlFlag.Reserved                                 =fread(id,23,'*ubit1');   
    
    RTH7058.Absorption             = fread(id,1,'float32');		% (8)
    RTH7058.Reserved			   = fread(id,6,'uint32');		% (18) -> 7*4 uint32  !!! NO BIT FIELD !!!       
                                                                   %   .
%% ________________________________________________________________________             
% RD Record data   
    % Read Beam Discriptor
    for i=1:RTH7058.NumberOfBeamsInRecord       
        RD7058(i).BeamDescriptor        =fread(id,1,'uint16');	%#ok<AGROW> % (0)
        RD7058(i).BeginSampleDescriptor =fread(id,1,'uint32');	%#ok<AGROW> % (2)
        RD7058(i).BottomDetectionSample =fread(id,1,'uint32');	%#ok<AGROW> % (4)
        RD7058(i).EndSampleDescriptor   =fread(id,1,'uint32');	%#ok<AGROW> % (10:14)  
    end
    
    % Read BS      
    for i=1:RTH7058.NumberOfBeamsInRecord 
        NumberOFSamplesInBeam=RD7058(i).EndSampleDescriptor-...
            RD7058(i).BeginSampleDescriptor+1;
        RD7058(i).BSSeries=fread(id, NumberOFSamplesInBeam,'float32');
    end
    
    % Read Footprint   
    for i=1:RTH7058.NumberOfBeamsInRecord 
        NumberOFSamplesInBeam=RD7058(i).EndSampleDescriptor-...
            RD7058(i).BeginSampleDescriptor+1;
        RD7058(i).Footprint=fread(id, NumberOFSamplesInBeam,'float32');
    end
end
function WriteCalibratedSnippetData_v01(id,RTH7058,RD7058)
% Reads Calibrated Backscatter data from data
if isempty(id)==0
%% ________________________________________________________________________             
% RTH Header 
	fwrite(id,RTH7058.SonarId,'uint64');		        % (0)
	fwrite(id,RTH7058.PingNumber,'uint32');	         	% (8)
    fwrite(id,RTH7058.MultiPingSequence,'uint16');		% (12)
    fwrite(id,RTH7058.NumberOfBeamsInRecord,'uint16');	% (14)
  
    fwrite(id,RTH7058.ErrorFlag,'uint8');               % (16)   !!! NO BIT FIELD !!!
    
    fwrite(id,RTH7058.ControlFlag.BrightnessIsRequiredToPass,'*ubit1'); 
    fwrite(id,RTH7058.ControlFlag.ColinearityIsRequiredToPass ,'*ubit1'); 
    fwrite(id,RTH7058.ControlFlag.BottomDetectionResultsAreUsedForSnippet,'*ubit1'); 
    fwrite(id,RTH7058.ControlFlag.SnippetDisplayMinRequirementsAreUsed,'*ubit1'); 
    fwrite(id,RTH7058.ControlFlag.MinimumWindowSizeIsRequired,'*ubit1');
    fwrite(id,RTH7058.ControlFlag.MaximumWindowSizeIsRequired,'*ubit1');
    fwrite(id,RTH7058.ControlFlag.FootprintAreasAreIncluded,'*ubit1');
    fwrite(id,RTH7058.ControlFlag.GenericCompensationNotPerUnit,'*ubit1');
    fwrite(id,RTH7058.ControlFlag.SingleAbsorptionValueUsedForTheWholePing,'*ubit1');
    fwrite(id,RTH7058.ControlFlag.Reserved,'*ubit1');   
    
    fwrite(id,RTH7058.Absorption,'float32');    % (8)
    fwrite(id,RTH7058.Reserved,'uint32');		% (18) -> 7*4 uint32       
                                                             
%% ________________________________________________________________________             
% RD Record data   
    for i=1:RTH7058.NumberOfBeamsInRecord       
        fwrite(id,RD7058(i).BeamDescriptor,'uint16');	% (0)
        fwrite(id,RD7058(i).BeginSampleDescriptor,'uint32');	% (2)
        fwrite(id,RD7058(i).BottomDetectionSample,'uint32');	% (4)
        fwrite(id,RD7058(i).EndSampleDescriptor,'uint32');	% (10:14)  
    end
    
    % Write BS series      
    for i=1:RTH7058.NumberOfBeamsInRecord 
        fwrite(id,RD7058(i).BSSeries,'float32');
    end
    
    % Write Footprint series  
    for i=1:RTH7058.NumberOfBeamsInRecord 
        fwrite(id,RD7058(i).Footprint,'float32');
    end
    
    
    
    
end
end
function WriteCalibratedSnippetDataFootprintCorr_v01(id,RTH7058,RD7058)
% Reads Calibrated Backscatter data from data
if isempty(id)==0
%% ________________________________________________________________________             
% RTH Header 
	fwrite(id,RTH7058.SonarId,'uint64');		        % (0)
	fwrite(id,RTH7058.PingNumber,'uint32');	         	% (8)
    fwrite(id,RTH7058.MultiPingSequence,'uint16');		% (12)
    fwrite(id,RTH7058.NumberOfBeamsInRecord,'uint16');	% (14)
  
    fwrite(id,RTH7058.ErrorFlag,'uint8');               % (16)   !!! NO BIT FIELD !!!
    
    fwrite(id,RTH7058.ControlFlag.BrightnessIsRequiredToPass,'*ubit1'); 
    fwrite(id,RTH7058.ControlFlag.ColinearityIsRequiredToPass ,'*ubit1'); 
    fwrite(id,RTH7058.ControlFlag.BottomDetectionResultsAreUsedForSnippet,'*ubit1'); 
    fwrite(id,RTH7058.ControlFlag.SnippetDisplayMinRequirementsAreUsed,'*ubit1'); 
    fwrite(id,RTH7058.ControlFlag.MinimumWindowSizeIsRequired,'*ubit1');
    fwrite(id,RTH7058.ControlFlag.MaximumWindowSizeIsRequired,'*ubit1');
    fwrite(id,RTH7058.ControlFlag.FootprintAreasAreIncluded,'*ubit1');
    fwrite(id,RTH7058.ControlFlag.GenericCompensationNotPerUnit,'*ubit1');
    fwrite(id,RTH7058.ControlFlag.SingleAbsorptionValueUsedForTheWholePing,'*ubit1');
    fwrite(id,RTH7058.ControlFlag.Reserved,'*ubit1');   
    
    fwrite(id,RTH7058.Absorption,'float32');    % (8)
    fwrite(id,RTH7058.Reserved,'uint32');		% (18) -> 7*4 uint32       
                                                             
%% ________________________________________________________________________             
% RD Record data   
    for i=1:RTH7058.NumberOfBeamsInRecord       
        fwrite(id,RD7058(i).BeamDescriptor,'uint16');	% (0)
        fwrite(id,RD7058(i).BeginSampleDescriptor,'uint32');	% (2)
        fwrite(id,RD7058(i).BottomDetectionSample,'uint32');	% (4)
        fwrite(id,RD7058(i).EndSampleDescriptor,'uint32');	% (10:14)  
    end
    
    % Write BS series      
    for i=1:RTH7058.NumberOfBeamsInRecord 
        fwrite(id,(RD7058(i).BSSeries - 10*log10(RD7058(i).Footprint)),'float32');
    end
    
    % Write Footprint series  
    for i=1:RTH7058.NumberOfBeamsInRecord 
        fwrite(id,RD7058(i).Footprint,'float32');
    end
    
    
    
    
    
end
end

function WriteSnippet2CompresstWCData_v01(id,DRF,RTH,RD,SamplingRate,Compressionfactor)
% Description: This record is created by this function and was never
... messured. The function take the samples by the snippet data and creates 
... a watercolumn Record frame out of it.

% Compressionfactor uses for non Calibrated Data. Is virtual
% 
%%
%
% DRF.Size=XY;
% DRF.RecordTypeIdentifier=XY;
% Magnitude    = {RD.Snippet}.';
% SnippetStart = cell2mat({RD.SnippetStart}.');
% Magnitude = cell2mat(Magnitude');  

%%_________________________________________________________________________
%% conversion Snippet2Watercolumn matrix (outdated not in use)
% bufferend=10; % in [%] added to the end of an trace
% maxTraceLength=max(SnippetEnd) + round(max(SnippetEnd).*(bufferend/100));

%%_________________________________________________________________________
%% Computing Size of Data Frame Record
    % byte size of DRF (including Checksum) -> FIX Byte size
    RecoredDataSize=68; 

    % byte size of RTH
    RecoredDataSize=RecoredDataSize+44; % FIX Byte size

    % byte size of RD -> Dynamic Byte size
    if 2<Compressionfactor || Compressionfactor>15
           error('Error invalid Compression Factor in "SN2WC".\n The allowed Compression Factor range is 2,..,15')
    end
    SnippetEnd           = cell2mat({RD.SnippetEnd}.');
    maxWaterColumnLength = max(SnippetEnd);
    maxWaterColumnLength = 2*(ceil(maxWaterColumnLength/2));
    DownsamplingType     = [1;0;0;0];
    CompressionfactorInBinary=ConvertCompressionfactor(Compressionfactor);
    NumberOFSamples      = maxWaterColumnLength./2;
    UINT16               = 2; % for the Beam number and the recoreded data 
    UINT32               = 4; % for the Number of samples
    % 2 Bytes for Beam Number (B) (0:511)
    % 4 Bytes for Sample Number (N)
    % 2 Bytes for each sample from 0:N-1
    RecoredDataSize     = RecoredDataSize+ RTH.NumberOfDetectionPoint*UINT16 + ...
                                            RTH.NumberOfDetectionPoint*UINT32+ ...
                                            NumberOFSamples*UINT16*RTH.NumberOfDetectionPoint;

%%_________________________________________________________________________
%% Create new DRF for 7048 from 7024
    DRF7042.ProtocolVersion                      =DRF.ProtocolVersion;                      % uint16
    DRF7042.Offset                               =DRF.Offset;                               % uint16
    DRF7042.SyncPattern                          =DRF.SyncPattern;                          % uint32 
    DRF7042.Size                                 =RecoredDataSize;                          % uint32 
    DRF7042.OptionalDataOffset                   =DRF.OptionalDataOffset;                   % uint32 
    DRF7042.OptionalDataIdentifier               =DRF.OptionalDataIdentifier;               % uint32 
    DRF7042.yy                                   =DRF.yy;                                   % uint16 2
    DRF7042.doy                                  =DRF.doy;                                  % uint16 Day of Year 2
    DRF7042.ss                                   =DRF.ss;                                   % f32 4
    DRF7042.HH                                   =DRF.HH;                                   % uint8 1
    DRF7042.MM                                   =DRF.MM;                                   % uint8 1
    DRF7042.Reserved                             =DRF.Reserved;                             % uint16 fseek(fd,2,0);
    DRF7042.RecordTypeIdentifier                 =7042;                                     % uint32 for Watercolumn data
    DRF7042.DeviceIdentifier                     =DRF.DeviceIdentifier;                     % uint32 
    DRF7042.SystemEnumeration                    =DRF.SystemEnumeration;                    % uint32 
    DRF7042.Reserved2                            =DRF.Reserved2;                            % uint32 fseek(fd,2,0);
    DRF7042.Flag.ValidChecksum                   =DRF.Flag.ValidChecksum;                   % uint1*
    DRF7042.Flag.Reserved                        =DRF.Flag.Reserved;                        % uint14*
    DRF7042.Flag.RecordedData                    =DRF.Flag.RecordedData;                    % uint1* if 0: LiveData if:1 RecorededData
    DRF7042.Reserved3                            =DRF.Reserved3;                            % uint32 fseek(fd,2,0);
    DRF7042.Reserved4                            =DRF.Reserved4;                            % uint32 fseek(fd,2,0);
    DRF7042.TotalRecordInFragmentedDataRecordSet =DRF.TotalRecordInFragmentedDataRecordSet; % uint32 
    DRF7042.FragmentNumber                       =DRF.FragmentNumber;                       % uint32 

%%_________________________________________________________________________
%% Create RTH from 7024	 
    RTH7042.SonarId                                    = RTH.SonarId;
    RTH7042.PingNumber                                 = RTH.PingNumber;
    RTH7042.MultiPingSequence                          = RTH.MultiPingSequence;
    RTH7042.NumberOfBeam                               = RTH.NumberOfDetectionPoint;
    RTH7042.NrOfSamples                                = NumberOFSamples;
    RTH7042.CompressedSamples                          = NumberOFSamples;

    % BIT FIELD
    RTH7042.Flags.UseMaximumBottomDetectionPoint       = 0;
    RTH7042.Flags.IncludeIntensityDataOnly             = 1;
    RTH7042.Flags.ConvertMagTodB                       = 0;
    RTH7042.Flags.Reserved1                            = 0;
    RTH7042.Flags.DownsamplingDivisor                  = CompressionfactorInBinary;
    RTH7042.Flags.DownsamplingType                     = DownsamplingType;
    RTH7042.Flags.BitType32                            = 0;
    RTH7042.Flags.CompressionFactorAvailable           = 0;
    RTH7042.Flags.SegmentNumbersAvailable              = 0;
    RTH7042.Flags.FirstSampleContainsRxDelayValue      = 0;
    RTH7042.Flags.reserved2                            = zeros(16,1);

    RTH7042.FirstSampleIncludedForEachBeam             = 0;
    RTH7042.SampleRate                                 = SamplingRate./Compressionfactor;
    RTH7042.CompressionFactor                          = 0;
    RTH7042.Reserved                                   = 0;         
    


%%_________________________________________________________________________
%% Create DR from 7024	
WaterColounMatrix=zeros(maxWaterColumnLength,RTH.NumberOfDetectionPoint);
for i=1:RTH.NumberOfDetectionPoint     
    if RD(i).SnippetStart>0 && RD(i).DetectionSample>1
          WaterColounMatrix(RD(i).SnippetStart:RD(i).SnippetEnd,i)=RD(i).Snippet; 
    end
end
Magnitude= WaterColounMatrix(1:Compressionfactor:end,:);
%%_________________________________________________________________________
%% Create RD
  for i=1:RTH7042.NumberOfBeam
      RD7042(i).BeamNumberForThisData = i-1; %#ok<AGROW>
      RD7042(i).NumberOfSamples       = NumberOFSamples; %#ok<AGROW>
      RD7042(i).Magnitude             = Magnitude(:,i); %#ok<AGROW>
  end 
%%_________________________________________________________________________
%% Write DRF and RTH	 
    WriteDataRecordFrame_v01(id,DRF7042);  
    WriteCompressedWatercolomnData_v01(id,RTH7042,RD7042);
   
end

function CompressionfactorInBinary=ConvertCompressionfactor(Compressionfactor)
 CompressionfactorInBinary=str2num(fliplr(dec2bin(Compressionfactor,4))'); %#ok<ST2NM>
end

function [RTH7610,RD7610]=ReadSoundVelocity(id)
RTH7610.SoundVelocity=fread(id,1,'float32');
RD7610=[];
end

function WriteSoundVelocity_v01(id,RTH7610)
if isempty(id)==0
    fwrite(id,RTH7610.SoundVelocity,'float32');
end
end

function Verbose(txt,varin,varunit)
% Function that provides feedback to the user
%     txt of type 'char' 
%   varin of type integer, char, float
% varunit of type integer, char, float 
%         


LineStart   = '\n\t'; % specifies the starting column of the line
strSize     = 80;     % valid String length
PlaceHolder = '.';

  
%% ________________________________________________________________________
% Create taper for text alignment
    strTaper ='';
    for j = 1: strSize 
        strTaper = [strTaper PlaceHolder];   %#ok<AGROW>
    end
%% ________________________________________________________________________
% Check input Input variable 
%Get length of Input variable type "text"
    l_txt=length(txt);

% Check input for Input variable "varin"
    if isa(varin,'cell')
        varin=cell2mat(varin);
    end
    
    l_varin = 0; % predefine
    if isempty(varin)==0
        if isa(varin,'char') 
            l_varin= length(varin);
            varin = sprintf('%s   ',varin); 
        elseif isa(varin,'string') 
            fprintf([' \nWARNING: Input of type String for variable',...
                    ' "varin" is not supported by function Verbose\n']);
            return; 
        elseif isa(varin,'double') && mod(varin,round(varin))==0
            l_varin=length(num2str(varin));
            varin=sprintf('%d   ',varin);
        elseif isa(varin,'double')
            l_varin=length(num2str(round(varin)));
            varin=sprintf('%02.2f',varin);    
        else
            fprintf([' \nWARNING: Invalid input type for variable',...
            ' "varin" in function Verbose\n']);
           
        end
    else
         fprintf([' \nWARNING: No input for variable "varin"',...
          'in function Verbose\n']);
    
    end

% Check input for Input variable "varunit"
    if isa(varunit,'double') && isempty(varunit)==0
            if mod(varunit,round(varunit))==0
                varunit = sprintf('%d',varunit);
            else
                varunit= sprintf('%02.2f',varunit); 
            end
    elseif isa(varunit,'char')
            varunit = sprintf('%s',varunit); 
    else
%            fprintf([' \nWARNING: Invalid input type for variable',...
%            ' "varunit" in function Verbose\n']);
    end

%% ________________________________________________________________________
   n=l_txt + l_varin; 
   m=strSize-n;
   fprintf([LineStart '%s%-*.*s %s %s'],txt,m,m,strTaper,varin,varunit)
   

end




































