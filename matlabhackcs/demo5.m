clc;
clear;
close all;

fc=154000;
fm=fc/10;
fs=100*fc;

t=0:1/fs:4/fm;

xc=cos(2*pi*fc*t);
xm=cos(2*pi*fm*t);

figure(1)
subplot(2,1,1),plot(t,xc),title('Carrier Signal')
subplot(2,1,2),plot(t,xm),title('Message Signal')

% DSB-SC Modulation
z1=xm.*xc;

L=length(z1);
f=linspace(-fs/2,fs/2,L);
Z1=fftshift(fft(z1)/L);

figure(2)
subplot(2,1,1),plot(t,z1)
title('DSB-SC Signal')

subplot(2,1,2),plot(f,abs(Z1))
title('DSB-SC Spectrum')
axis([-200000 200000 0 0.3])

% Demodulation
S1=fftshift(fft(z1.*xc)/L);

Hlp=1./sqrt(1+(f/fc).^200);

figure(3)
plot(f,abs(S1))
hold on
plot(f,Hlp,'g')
title('LPF Response')
axis([-200000 200000 0 2])

E1=Hlp.*S1;
e1=ifft(ifftshift(E1))*L;

figure(4)
subplot(2,1,1),plot(f,abs(E1))
title('Recovered Signal Spectrum')
axis([-200000 200000 0 0.3])

subplot(2,1,2),plot(t,2*e1)
title('Recovered Signal')