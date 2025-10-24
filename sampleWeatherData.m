function data = sampleWeatherData()
% sampleWeatherData - returns a demo table with datetime and temperature
% Generates 30 days of daily temperatures with a modest warming trend + noise

n = 30;
endDate = datetime('now');
startDate = endDate - days(n-1);
dt = (startDate:days(1):endDate)';
% linear trend: 15 + 0.05 * dayIndex + seasonal + noise
dayIdx = (0:numel(dt)-1)';
seasonal = 2*sin(2*pi*(dayIdx/30));
temps = 15 + 0.05*dayIdx + seasonal + randn(size(dayIdx))*0.8;

data = table(dt, temps, 'VariableNames',{'datetime','temp'});
end