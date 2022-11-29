function [sig_filter] = sigmoid_simple(sig_datasample, sig_halfpoint, sig_rate, T)
%SIGMOID_SIMPLE Create a simple sigmoid filter to surpressed initial
%contact signal
% INPUT:
% sig_datasample    The number of sample, needs to be matched with the
%                   signal which will be filtered
% sig_halfpoint     The point where sigmoid value is 0.5. In microsecond
%                   unit
% sig_rate          The sigmoid's rising rate
% 
% OUTPUT:
% tgc_filter        The Sigmoid filter

sig_dacdelay_samplenum = (sig_halfpoint * 1e-6) / T;
sig_dataaxis           = 1:sig_datasample;
sig_filter             = 1./(1 + exp(-sig_rate.*(sig_dataaxis-sig_dacdelay_samplenum)));
end

