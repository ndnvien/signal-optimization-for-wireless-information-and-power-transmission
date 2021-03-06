function [SolutionSuperposedWaveform, SolutionNoPowerWaveform] = initialize_algorithm(Transceiver, Channel)
% Function:
%   - initialize resource allocation with matched filers
%
% InputArg(s):
%   - Transceiver.tx: number of transmit antennas
%   - Transceiver.rx: number of receive antennas
%   - Transceiver.txPower: average transmit power
%   - Channel.subbandAmplitude: amplitude of channel impulse response
%   - Channel.mimoAmplitude: equalvalent amplitude of MIMO channel
%
% OutputArg(s):
%   - SolutionSuperposedWaveform: initial amplitude corresponding to the algorithm of superposed waveform
%   - SolutionNoPowerWaveform: initial amplitude corresponding to the algorithm of no power waveform
%
% Comments:
%   - initialize power and information waveforms with matched filers
%
% Author & Date: Yang (i@snowztail.com) - 22 Jul 19


v2struct(Transceiver, {'fieldNames', 'tx', 'rx', 'txPower'});

if rx == 1
    amplitude = Channel.subbandAmplitude;
else
    % initialize all tx to dominant eigenmode transmission
    amplitude = repmat(Channel.mimoAmplitude(:, 1), [1, tx]);
end

% initialize results
rate = NaN;
current = NaN;
% ratio for power transmission
powerSplitRatio = 0.5;
% ratio for information transmission
infoSplitRatio = 1 - powerSplitRatio;

% superposed waveforms
powerAmplitude = amplitude / norm(amplitude, 'fro') * sqrt(txPower);
infoAmplitude = amplitude / norm(amplitude, 'fro') * sqrt(txPower);
SolutionSuperposedWaveform = v2struct(rate, current, powerSplitRatio, infoSplitRatio, powerAmplitude, infoAmplitude);

% no power waveform
powerAmplitude = zeros(size(powerAmplitude));
infoAmplitude = amplitude / norm(amplitude, 'fro') * sqrt(2 * txPower);
SolutionNoPowerWaveform = v2struct(rate, current, powerSplitRatio, infoSplitRatio, powerAmplitude, infoAmplitude);

end

