%%Extracting the Frames from video%%
clc
clear all
a=VideoReader('challenge_video.mp4');
v = VideoWriter('Challenge_video_output.avi');
open(v);
for img=1:475;
    filename=strcat('frame',num2str(img),'.jpg');
    x = [210 550 620 810 717 1280];
    y=[720 460 700 700 460 720];
mask = poly2mask(x,y, 720, 1280); 
    Image= read(a,img); 
    I=Image;
    %I= imgaussfilt3(Image,1);
   I= rgb2hsv(I);
% Define thresholds for channel 1 based on histogram settings
channel1Min = 0.09;
channel1Max = 0.15;
% Define thresholds for channel 2 based on histogram settings
channel2Min = 0.4;
channel2Max = 1;
% Define thresholds for channel 3 based on histogram settings
channel3Min = 0.1;
channel3Max = 1.000;
% Create mask based on chosen histogram thresholds
mask_yellow = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
  (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
  (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
BW = mask_yellow;
% Initialize output masked image based on input image.
I_yellow= I;
% Set background pixels where BW is false to zero.
I_yellow(repmat(~BW,[1 1 2])) = 0;
mask_white=(I(:,:,1) >= 0.05) & (I(:,:,1) <= 0.3) & ...%0.2
  (I(:,:,2) >= 0.01 ) & (I(:,:,2) <= 0.15) & ...
  (I(:,:,3) >=  0.8) & (I(:,:,3) <=1);
I_white=I;
I_white(repmat(~mask_white,[1 1 2]))=1;
IG=rgb2gray(I_yellow);
IG1=rgb2gray(I_white);
I_final= IG + IG1;
%I_final=medfilt2(I_final);
I_edge = edge(I_final,'canny',0.25);%0.2
I_edge=immultiply(I_edge,mask);
centerIndexRow = round(size(I_edge,1)/2);         %# Get the center index for the rows
centerIndexCol = round(size(I_edge,2)/2);         %# Get the center index for the column
[H,T,R] = hough(I_edge);
P = houghpeaks(H,15,'threshold',ceil(0.08*max(H(:))));
x = T(P(:,2)); y = R(P(:,1));
plot(x,y,'s','color','white');
lines = houghlines(I_edge,T,R,P,'FillGap',20,'MinLength',1);
i=1;
j=1;
%grouping the line into left and right%
for k = 1:length(lines)
   Line_P1=lines(k).point1;
   Line_P2=lines(k).point2;
   if Line_P1(1)< centerIndexCol && Line_P2(1) < centerIndexCol 
       left_line(i)= lines(k);
       i=i+1;
   end  
   if Line_P1(1)> centerIndexCol && Line_P2(1) > centerIndexCol 
       right_line(j)= lines(k);
       j=j+1;
   end
  xy = [lines(k).point1; lines(k).point2]
 %plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green')
   
end

%fitting polynomial for each line%
m=1;
for k=1:length(left_line)
    left_line_x(m)= left_line(k).point1(1);
    left_line_y(m)= left_line(k).point1(2);
    m=m+1;
    left_line_x(m)= left_line(k).point2(1);
    left_line_y(m)= left_line(k).point2(2);
    m=m+1;
end
n=1;
for k=1:length(right_line)
    right_line_x(n)= right_line(k).point1(1);
    right_line_y(n)= right_line(k).point1(2);
    n=n+1;
    right_line_x(n)= right_line(k).point2(1);
    right_line_y(n)= right_line(k).point2(2);
    n=n+1;
end
%Finding the points of line%
p1= polyfit(left_line_x,left_line_y,1);
left_line_slope= p1(1);
left_line_intercept = p1(2);
p2 = polyfit(right_line_x,right_line_y,1);
right_line_slope= p2(1);
right_line_intercept = p2(2);
line_y12 = [500 centerIndexRow*2];
left_line_x1= (line_y12(1)- left_line_intercept)/left_line_slope;
left_line_x2= (line_y12(2)- left_line_intercept)/left_line_slope;
left_line_x12=[left_line_x1 left_line_x2];
right_line_x1= abs((line_y12(1)- right_line_intercept)/right_line_slope);
right_line_x2= abs((line_y12(2)- right_line_intercept)/right_line_slope);
right_line_x12 = [right_line_x1 right_line_x2];
% Vanishing point%
x_vanish= (right_line_intercept - left_line_intercept)/(left_line_slope-right_line_slope);
y_vanish= right_line_slope* x_vanish + right_line_intercept;
thresh=4;
if (x_vanish < (centerIndexCol+10-thresh ))
    turn='Left Turn';
elseif (x_vanish > (centerIndexCol+20+thresh))
    turn='Right Turn';
else (centerIndexCol+20- thresh)<= x_vanish <= (centerIndexCol+20+ thresh)
    turn='Straight';
end
figure(1)
imshow(Image);
hold on
%% Plotting the spline
X_spline=[left_line_x12(2) left_line_x12(1) right_line_x12(1) right_line_x12(2)];
Y_spline= [line_y12(2) line_y12(1) line_y12(1) line_y12(2)];
fill3=fill(X_spline,Y_spline,'b')
fill3.FaceAlpha=0.2;
hold on
plot([left_line_x12(2) left_line_x12(1)],[line_y12(2) line_y12(1)],'y','LineWidth',5)
hold on
plot([right_line_x12(1) right_line_x12(2)],[line_y12(1) line_y12(2)],'y','LineWidth',5)
hold on

%plot(x_vanish,y_vanish, '.','Color','red', 'markersize', 10);
%text(180, 75,turn,'horizontalAlignment', 'center', 'Color','red','FontSize',19);
frame = getframe(gca);
writeVideo(v,frame);

end
close(v)
