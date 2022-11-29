function [tgc_filter] = tgc_simple(tgc_nsamples, tgc_dacdelay, tgc_dacslope, T)
%TGC_SIMPLE Create a simple filter increase the gain in the rear part of the signal 
% INPUT:
% tgc_nsamples      The number of sample, needs to be matched with the
%                   signal which will be filtered
% tgc_dacdelay      The starting point which the signal amplitude will be 
%                   multiplied. In microsecond unit.
% tgc_dacslope      The multiplication rate, in amplitude/microsecond unit.
% 
% OUTPUT:
% tgc_filter        The TGC filter

tgc_dacdelay_samplenum     = (tgc_dacdelay * 1e-6) / T;
tgc_dacslope_ratepersample = tgc_dacslope * T / 1e-6;
tgc_dacslope_x = tgc_dacslope_ratepersample * (1:tgc_nsamples-tgc_dacdelay_samplenum);

tgc_filter = ones(1, tgc_nsamples);
tgc_filter(tgc_dacdelay_samplenum+1:end) = tgc_filter(tgc_dacdelay_samplenum+1:end)+tgc_dacslope_x;

end

