function out=wavePeak(wName, bStart, bEnd, pStart, pEnd)
    data=getWave(wName, 'data');
    baseline=mean(data(x2pnt(wName, bStart):x2pnt(wName, bEnd)));
    peak=mean(data(x2pnt(wName, pStart):x2pnt(wName, pEnd)));
    out=peak-baseline;
    
    
    