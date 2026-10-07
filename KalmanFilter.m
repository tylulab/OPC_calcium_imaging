%Based on the Kalman Stack Filter of Fiji made by Christopher Philip Mauer%
%https://imagej.nih.gov/ij/plugins/kalman.html%
%Copyright (C) 2003 CHRISTOPHER PHILIP MAUER
%Permission to use, copy, modify, and distribute this software for any purpose without fee is hereby granted, provided that this entire notice is included in all copies of any software which is or includes a copy or modification of this software and in all copies of the supporting documentation for such software. Any for profit use of this software is expressly forbidden without first obtaining the explicit consent of the author.
%THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT ANY EXPRESS OR IMPLIED WARRANTY. IN PARTICULAR, THE AUTHOR DOES NOT MAKE ANY REPRESENTATION OR WARRANTY OF ANY KIND CONCERNING THE MERCHANTABILITY OF THIS SOFTWARE OR ITS FITNESS FOR ANY PARTICULAR PURPOSE. 

clear;

%Read a tiff stack%
[file,path] = uigetfile('*.tif;*.tiff');
TiffStack = file;
Info = imfinfo(TiffStack);
StackW = Info(1).Width;
StackH = Info(1).Height;
StackN = length(Info);
StackRead = zeros(StackW, StackH, StackN, 'uint8');
 
T = Tiff(TiffStack, 'r');

for i=1:StackN
    
   T.setDirectory(i);
   StackRead(:,:,i)=T.read();
   
end

T.close();

%Concatenate tiff stack%
StackCCn = StackN*2;
StackCC = zeros(StackW, StackH, StackCCn, 'uint8');
StackCC(:,:,1:StackN) = StackRead;
StackCC(:,:,StackN+1:StackCCn) = StackRead;

%Create a tiff stack to write%
[filepath, name, ext] = fileparts(file);
newfilename = strcat(name, '-kf.tif');
K = Tiff(newfilename, 'w');
tagstruct.ImageLength = size(StackCC, 1);
tagstruct.ImageWidth = size(StackCC, 2);
tagstruct.BitsPerSample = 8;
tagstruct.SamplesPerPixel = 1;
tagstruct.Compression = 1;
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky; 
tagstruct.Photometric = Tiff.Photometric.MinIsBlack;

%User-defined Kamlan filter value%
SensorNoiseEst=0.1;    %SensorNoice(R)%
FilterGain=0.8;  %Prediction Matrix(F)%

%Initialization%
PreviousImage=StackCC(:,:,StackCCn);
ErrorSeed=SensorNoiseEst;

%Assuming H = 1, i.e. ignore sensor reading represents the actual value%

tic

for i=1:StackCCn
    
    %Correction%
    KalmanGain=ErrorSeed/(ErrorSeed+SensorNoiseEst);
    NewEstimate=FilterGain*PreviousImage+(1-FilterGain)*StackCC(:,:,i)+KalmanGain*(StackCC(:,:,i)-PreviousImage);
    NewVarianceEstimate=ErrorSeed*(1-KalmanGain);    
    
    %Writing tiff stack on the second round%
    if i > StackN
        K.setTag(tagstruct);
        K.write(NewEstimate);
        K.writeDirectory();
    end
    
    %Update values%
    PreviousImage=NewEstimate;
    ErrorSeed=NewVarianceEstimate;

end
toc

K.close
