function [dcCurrent, rate] = wipt_decoupling(nSubbands, channelAmplitude, k2, k4, txPower, noisePower, resistance, iterMax, rateMin)
% Function:
%   - characterizing the rate-energy region of MISO transmission based on the proposed WIPT architecture
%
% InputArg(s):
%   - nSubbands: number of subbands (subcarriers)
%   - channelAmplitude: amplitude of channel impulse response
%   - k2, k4: diode k-parameters
%   - txPower: average transmit power
%   - noisePower: average noise power
%   - resistance: antenna resistance
%   - iterMax: max number of iterations for sequential convex optimization
%   - rateMin: rate constraint
%
% OutputArg(s):
%   - dcCurrent: maximum achievable DC current
%   - rate: mutual information based on the designed waveform
%
% Comments:
%   - decouple the design of the spatial and frequency domain weights
%   - significantly reduce the computational complexity as vectors rather than matrices are to be optimized numerically
%   - the power is maximized but the rate can be higher than the constraint
%
% Author & Date: Yang (i@snowztail.com) - 11 Jun 19

% initialize (matched filters)
powerAmplitude = channelAmplitude;
infoAmplitude = channelAmplitude;
powerSplitRatio = 0.5;
infoSplitRatio = 1 - powerSplitRatio;
dcCurrent = 0;

% iterate until optimum
for iIter = 1: iterMax
    %% condition [known]
    % calculate the exponent of geometric mean based on existing solutions
    [~, ~, exponentOfTarget] = target_function_decoupling(nSubbands, powerAmplitude, infoAmplitude, channelAmplitude, k2, k4, powerSplitRatio, resistance);
    [~, ~, exponentOfMutualInfo] = mutual_information_decoupling(nSubbands, infoAmplitude, channelAmplitude, noisePower, infoSplitRatio);
    
    clearvars t0 powerAmplitude infoAmplitude powerSplitRatio infoSplitRatio
    %% optimization [unknown]
    cvx_begin gp
        cvx_solver sedumi
        
        variable t0
        variable powerAmplitude(nSubbands, 1) nonnegative
        variable infoAmplitude(nSubbands, 1) nonnegative
        variable powerSplitRatio nonnegative
        variable infoSplitRatio nonnegative

        % formulate the expression of monomials
        [~, monomialOfTarget, ~] = target_function_decoupling(nSubbands, powerAmplitude, infoAmplitude, channelAmplitude, k2, k4, powerSplitRatio, resistance);
        [~, monomialOfMutualInfo, ~] = mutual_information_decoupling(nSubbands, infoAmplitude, channelAmplitude, noisePower, infoSplitRatio);

        minimize (1 / t0)
        subject to
        0.5 * (norm(powerAmplitude, 'fro') ^ 2 + norm(infoAmplitude, 'fro') ^ 2) <= txPower;
        t0 * prod((monomialOfTarget ./ exponentOfTarget) .^ (-exponentOfTarget)) <= 1;
        2 ^ rateMin * prod(prod((monomialOfMutualInfo ./ exponentOfMutualInfo) .^ (-exponentOfMutualInfo))) <= 1;
        powerSplitRatio + infoSplitRatio <= 1;
    cvx_end
    
    % update achievable rate and power successively
    [targetFun, ~, ~] = target_function_decoupling(nSubbands, powerAmplitude, infoAmplitude, channelAmplitude, k2, k4, powerSplitRatio, resistance);
    [rate, ~, ~] = mutual_information_decoupling(nSubbands, infoAmplitude, channelAmplitude, noisePower, infoSplitRatio);
    %% stopping criteria
    doExit = (targetFun - dcCurrent) < eps;
    % update optimum DC current
    dcCurrent = targetFun;
    if doExit
        break;
    end
end

end

