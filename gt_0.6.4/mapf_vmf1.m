%-------------------------------------------------------------------------------
% [system] : GpsTools
% [module] : tropospheric mapping function - VMF1
% [func]   : calculate tropospheric mapping function by Vienna mapping function 1
% [argin]  : t    = date/time (mjd)
%            azel = azimath/elevation angle(rad) [az,el]
%            gpos = latitude/longitude/height(deg,m) [lat,lon,h]
%            ah   = hydrostatic coefficient a
%            aw   = wet coefficient a
% [argout] : mapfd = dry mapping function
%            mapfw = wet mapping function
% [note]   : reference :
%            J.Boehm et al., Troposphere mapping functions for GPS and very long
%            baseline interferometry from European Centre for Medium-Range
%            Weather Forecasts operational analysis data, J. Geoph. Res.,
%            Vol. 111, B02406, 2006
%            vmf1_ht.f (fortran source code) :
%            http://www.hg.tuwien.ac.at/~ecmwf1/
% [version]: $Revision: 2 $ $Date: 06/07/08 1:01 $
%            Copyright(c) 2004-2008 by T.Takasu, all rights reserved
% [history]: 08/12/06   0.1  new
%-------------------------------------------------------------------------------

% (mex function)

