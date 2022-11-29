function [postMean,postSD] = bayes_inference(mean1, sigma1, mean2, sigma2)
%BAYES_INFERENCE1 performing bayesian inference, source from 
%https://nl.mathworks.com/help/stats/bayesian-analysis-for-a-logistic-regression-model.html

postMean = sigma2^2*mean1/(sigma2^2+sigma1^2) + sigma1^2*mean2/(sigma2^2+sigma1^2);
postSD   = sqrt(sigma2^2*sigma1^2/(sigma2^2+sigma1^2));

end

