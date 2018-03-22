%%Extracting the Frames from video%%
clc
clear all
a=VideoReader('project_video.mp4');
v = VideoWriter('project_video_out.avi');
open(v);
for img=1:550;
    filename=strcat('frame',num2str(img),'.jpg');
    I= read(a,img);
IG=rgb2gray(I);
I_median=medfilt2(IG);

%I_median = imgaussfilt(IG,0.5);
%I_edge = edge(I_median,'canny',0.4);%

I_edge= edge(I_median,'sobel',0.08,'vertical');


 x = [210 550 717 1280];
 y = [720 446 446 720];
mask = poly2mask(x,y, 720, 1280);
I_edge= immultiply(I_edge,mask);
centerIndexRow = round(size(I_edge,1)/2);         %# Get the center index for the rows
centerIndexCol = round(size(I_edge,2)/2);         %# Get the center index for the column

%I_edge(1:centerIndexRow+70,:) = cast(0,class(I_edge)); 
%I_edge(:,1000:end) = cast(0,class(I_edge));
%figure, imshow(I_edge), hold on

[H,T,R] = hough(I_edge);
P = houghpeaks(H,15,'threshold',ceil(0.07*max(H(:))));
x = T(P(:,2)); y = R(P(:,1));
lines = houghlines(I_edge,T,R,P,'FillGap',25,'MinLength',0.8);
%figure, imshow(I_edge), hold on

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
 xy = [lines(k).point1; lines(k).point2];
 plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green'), hold on
   
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
line_y12 = [460 centerIndexRow*2];
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
if (x_vanish < (centerIndexCol-11 -thresh ))
    turn='Left Turn';
elseif (x_vanish > (centerIndexCol+11 + thresh))
    turn='Right Turn';
else (centerIndexCol -11 - thresh)<= x_vanish <= (centerIndexCol -11+ thresh)
    turn='Straight';
end
%Plotting the line%
figure(1)

imshow(I);

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
text(170, 75,turn,'horizontalAlignment', 'center', 'Color','red','FontSize',18);
frame = getframe(gca);
writeVideo(v,frame);

end

close(v)