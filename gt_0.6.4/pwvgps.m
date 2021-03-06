function pwvgps(td,time,rcvs,dirs,outdir,tunit,toff,cbmsg)
%-------------------------------------------------------------------------------
% [system] : GpsTools
% [module] : generate gps pwv
% [func]   : generate gps pwv
% [argin]  : td,time = time (mjd-gpst)
%            rcvs    = stations list
%            dirs    = input directories
%                dirs.trop = ztd estimations
%                dirs.met  = meteorological data (GPV)
%           (outdir) = output directory
%           (tunit)  = estimation time unit(hr) (default:24)
%           (toff)   = time offset (sec)
%           (cbmsg)  = progress message callback
% [argout] : none
% [note]   : output file
%            pwvgps_{rcvs}.mat : tropospheric parameter data
%                time  = time vector (mjd-utc)
%                data  = tropospheric parameters
%                    data(n,1)=time(n) pressure (hPa)
%                    data(n,2)=time(n) temperature (degC)
%                    data(n,3)=time(n) ZHD (m)
%                    data(n,4)=time(n) ZWD (m)
%                    data(n,5)=time(n) PWV (m)
% [version]: $Revision: 20 $ $Date: 2009-05-01 04:15:33 +0900 (金, 01 5 2009) $
%            Copyright(c) 2004-2008 by T.Takasu, all rights reserved
% [history]: 05/11/20  0.1  new
%            08/12/13  0.2  supprt progress message callback
%                           improve interpolation performance 
%-------------------------------------------------------------------------------
if nargin<5, outdir=''; end
if nargin<6, tunit=24; end
if nargin<7, toff=0; end
if nargin<8, cbmsg=''; end
pos=readpos(td,time(1),rcvs,'','approx');
for n=1:length(rcvs)
    gpos(n,:)=eceftogeod(pos(1,:,n)');
    gpos(n,3)=geodh(gpos(n,:));
end
tu=tunit*3600;
for n=floor(time(1)/tu):floor(time(end)/tu)
    i=find(n*tu<=time&time<(n+1)*tu);
    if pwvgpsunit(td,time(i),rcvs,dirs,outdir,tunit,toff,gpos,cbmsg), return; end
end
if ~isempty(cbmsg), outmsg(cbmsg,'done'); return; end

% generate gps pwv for a time unit ---------------------------------------------
function abort=pwvgpsunit(td,time,rcvs,dirs,outdir,tunit,toff,gpos,cbmsg)
ztd=repmat(nan,length(time),length(rcvs));
for m=1:length(rcvs)
    [t,xs]=readest(td,time+toff,'zpd',rcvs{m},dirs.trop,'fb',tunit);
    if ~isempty(t)
        [tt,i,j]=intersect(time+toff,t);
        ztd(i,m)=xs(j,1);
    end
end
trop=repmat(nan,[length(time),5,length(rcvs)]);
for n=1:length(time)
    ep=mjdtocal(td,time(n));
    msg=sprintf('%04d/%02d/%02d %02d:%02d',ep(1:5));
    if outmsg(cbmsg,['generating pwv: ',msg]), abort=1; return; end
    for m=1:length(rcvs)
        [pmsl,temp]=readmet(td,time(n),gpos(m,:),dirs,'mso');
        trop(n,:,m)=ztdtopwv(gpos(m,:),ztd(n,m),pmsl,temp);
    end
end
tu=tunit*3600;
ep=mjdtocal(td,floor(time(1)/tu)*tu);
time=td+time(:)/86400;
for m=1:length(rcvs)
    data=trop(:,:,m);
    file=sprintf('pwvgps_%s_%04d%02d%02d%02d.mat',rcvs{m},ep(1:4));
    path=gfilepath(outdir,file,ep(1:3),rcvs{m},1);
    if outmsg(cbmsg,['saving: ',file]), abort=1; return; end
    save(path,'time','data');
end
abort=0;

% ztd to pwv -------------------------------------------------------------------
function pwv=ztdtopwv(gpos,ztd,pmsl,temp)
Rv=461;      % J/kg/K
k3=3.754E5;  % k3 (K^2/hPa)
kd=23.7146;  % k2-k1*mv/md(k1=77.6,k2=71.98,mv=18.0152,md=28.9644)

p=pmsl*(1-0.0065*gpos(3)/(temp-0.0065*gpos(3)+273.15))^5.257;
zhd=0.0022768*p/(1-0.00266*cos(2*gpos(1)*pi/180)-2.8E-7*gpos(3));
zwd=ztd-zhd;
tm=70.2+0.72*(temp+273.15);
pwv=zwd*1E5/(Rv*(kd+k3/tm));
pwv=[p,temp,zhd,zwd,pwv];

% read met parameters ----------------------------------------------------------
function [pmsl,temp]=readmet(td,time,gpos,dirs,gpvsrc)
persistent tdd t1 t2 pm1 pm2 tm1 tm2 gpp1 gpp2 gpt1 gpt2
if isempty(tdd)|isempty(t1)|td~=tdd|time<t1|t2<=time
    t1=floor(time/3600)*3600;
    if t1==t2
        pm1=pm2; gpp1=gpp2; tm1=tm2; gpt1=gpt2;
    else
        ts1=floor(t1/3600/6)*6; ft1=rem(t1/3600,6);
        [pm1,gpp1]=readgpv(td,ts1*3600,'pmsl',dirs.met,gpvsrc,0,ft1);
        [tm1,gpt1]=readgpv(td,ts1*3600,'temp',dirs.met,gpvsrc,0,ft1);
    end
    t2=t1+3600; ts2=floor(t2/3600/6)*6; ft2=rem(t2/3600,6);
    [pm2,gpp2]=readgpv(td,ts2*3600,'pmsl',dirs.met,gpvsrc,0,ft2);
    [tm2,gpt2]=readgpv(td,ts2*3600,'temp',dirs.met,gpvsrc,0,ft2);
    tdd=td;
end
pn1=nan; tn1=nan; pn2=nan; tn2=nan;
if ~isempty(gpp1)&~isempty(gpt1)
    [x1,y1]=gmt('lltogrid',gpos(2),gpos(1),gpp1);
    [x2,y2]=gmt('lltogrid',gpos(2),gpos(1),gpt1);
    pn1=interpmet(double(pm1),x1,y1);
    tn1=interpmet(double(tm1),x2,y2);
end
if ~isempty(gpp2)&~isempty(gpt2)
    [x1,y1]=gmt('lltogrid',gpos(2),gpos(1),gpp2);
    [x2,y2]=gmt('lltogrid',gpos(2),gpos(1),gpt2);
    pn2=interpmet(double(pm2),x1,y1);
    tn2=interpmet(double(tm2),x2,y2);
end
a=(time-t1)/(t2-t1);
if ~isnan(pn1)&~isnan(pn2)
    pmsl=pn1*(1-a)+pn2*a;
    temp=tn1*(1-a)+tn2*a;
elseif a==0&~isnan(pn1)
    pmsl=pn1;
    temp=tn1;
else
    pmsl=nan;
    temp=nan;
end

% interpolate meteorological parameters ----------------------------------------
function v=interpmet(met,x,y)
if y<1|size(met,1)<=y|x<1|size(met,2)<=x, v=nan; return; end
i=floor(y); j=floor(x); a=y-i; b=x-j;
v=met(i,j)*(1-a)*(1-b)+met(i+1,j)*a*(1-b)+met(i,j+1)*(1-a)*b+met(i+1,j+1)*a*b;

% output message ---------------------------------------------------------------
function abort=outmsg(cbmsg,msg)
if isempty(cbmsg)
    disp(msg); abort=0;
else
    abort=feval(cbmsg{:},msg);
    if abort, feval(cbmsg{:},'aborted'); end
end
