classdef weatherRegressionApp < matlab.apps.AppBase
    % A simple MATLAB app that fetches weather data and performs a linear
    % regression (temperature vs time). It supports using OpenWeatherMap
    % (requires API key) or a built-in sample dataset.

    % Public properties that correspond to app components
    properties (Access = public)
        UIFigure             matlab.ui.Figure
        CityEditField        matlab.ui.control.EditField
        ApiKeyEditField      matlab.ui.control.EditField
        FetchButton          matlab.ui.control.Button
        UseSampleCheckBox    matlab.ui.control.CheckBox
        UIAxes               matlab.ui.control.UIAxes
        ResultsTable         matlab.ui.control.Table
        StatusLabel          matlab.ui.control.Label
    end

    methods (Access = private)
        function createComponents(app)
            % Create and configure UI components
            app.UIFigure = uifigure('Name','Weather Regression App','Position',[100 100 800 520]);

            app.CityEditField = uieditfield(app.UIFigure,'text','Position',[20 460 220 24], 'Value','London');
            uilabel(app.UIFigure,'Position',[20 486 200 18],'Text','City (for geocoding):');

            app.ApiKeyEditField = uieditfield(app.UIFigure,'text','Position',[260 460 320 24]);
            uilabel(app.UIFigure,'Position',[260 486 320 18],'Text','OpenWeatherMap API Key (leave empty to use sample data):');

            app.UseSampleCheckBox = uicheckbox(app.UIFigure,'Position',[600 462 160 24],'Text','Use built-in sample data','Value',true);

            app.FetchButton = uibutton(app.UIFigure,'push','Position',[600 490 160 28],'Text','Fetch & Fit');
            % Use anonymous with unused inputs suppressed to avoid static warnings
            app.FetchButton.ButtonPushedFcn = @(~,~)app.onFetchButtonPushed();

            app.UIAxes = uiaxes(app.UIFigure,'Position',[20 120 560 320]);
            title(app.UIAxes,'Temperature vs Time');
            xlabel(app.UIAxes,'Date');
            ylabel(app.UIAxes,'Temperature (°C)');

            app.ResultsTable = uitable(app.UIFigure,'Position',[600 120 180 320]);
            app.ResultsTable.ColumnName = {'Value'};

            app.StatusLabel = uilabel(app.UIFigure,'Position',[20 20 760 60],'Text','Ready.');
            app.StatusLabel.FontSize = 12;
        end

        function onFetchButtonPushed(app)
            app.StatusLabel.Text = 'Fetching data...';
            drawnow;

            try
                if app.UseSampleCheckBox.Value || isempty(strtrim(app.ApiKeyEditField.Value))
                    data = sampleWeatherData();
                else
                    data = app.getWeatherData(app.CityEditField.Value, app.ApiKeyEditField.Value);
                end

                if isempty(data) || height(data) < 2
                    app.StatusLabel.Text = 'Not enough data to fit regression.';
                    return;
                end

                [coeffs, rmse] = app.performRegression(data.datetime, data.temp);
                app.updatePlot(data.datetime, data.temp, coeffs);

                % Show results in table (slope, intercept, RMSE)
                T = table(coeffs(1), coeffs(2), rmse, 'VariableNames',{'Slope','Intercept','RMSE'});
                app.ResultsTable.Data = T;

                app.StatusLabel.Text = sprintf('Fit complete. Slope=%.4g °C/day, RMSE=%.4g',coeffs(1),rmse);
            catch ME
                app.StatusLabel.Text = ['Error: ' ME.message];
            end
        end

        function data = getWeatherData(app, city, apiKey)
            % Get weather data using OpenWeatherMap (geocoding + onecall hourly)
            % Returns table with fields datetime (datetime) and temp (double, °C)

            if isempty(strtrim(apiKey))
                error('API key is required unless using sample data.');
            end

            % Geocode city -> lat/lon
            encCity = matlab.net.URLEncoder.encode(city,'UTF-8');
            geoUrl = sprintf('http://api.openweathermap.org/geo/1.0/direct?q=%s&limit=1&appid=%s',encCity,apiKey);
            opts = weboptions('Timeout',15);
            geo = webread(geoUrl, opts);
            if isempty(geo)
                error('City not found by geocoding service.');
            end
            lat = geo(1).lat; lon = geo(1).lon;

            % Use One Call API to get hourly forecast (requires units=metric)
            callUrl = sprintf('https://api.openweathermap.org/data/2.5/onecall?lat=%.6f&lon=%.6f&exclude=minutely,current,alerts&units=metric&appid=%s',lat,lon,apiKey);
            res = webread(callUrl, opts);

            if isfield(res,'hourly') && ~isempty(res.hourly)
                hours = res.hourly;
                % hours is struct array with fields dt (unix) and temp
                dt = datetime([hours.dt]','ConvertFrom','posixtime','TimeZone','UTC');
                temp = [hours.temp]';
                data = table(dt,temp,'VariableNames',{'datetime','temp'});
            elseif isfield(res,'daily') && ~isempty(res.daily)
                days = res.daily;
                dt = datetime([days.dt]','ConvertFrom','posixtime','TimeZone','UTC');
                temp = [days.temp]';
                % daily.temp can be struct with .day - handle that case
                if isstruct(temp)
                    temp = cellfun(@(s) s.day, num2cell(temp));
                end
                data = table(dt,temp,'VariableNames',{'datetime','temp'});
            else
                error('No hourly or daily data found in API response.');
            end

            % Ensure datetime is local (remove timezone tag for plotting)
            data.datetime = datetime(data.datetime,'TimeZone','');
        end

        function [coeffs, rmse] = performRegression(app, t, y)
            % Fit linear model y = p1*x + p2 where x is days since first timepoint
            x = days(t - t(1));
            if numel(x) < 2
                error('Need at least two points for regression.');
            end
            p = polyfit(x, y, 1);
            yfit = polyval(p, x);
            rmse = sqrt(mean((y - yfit).^2));
            coeffs = p; % [slope intercept]
        end

        function updatePlot(app,t,y,coeffs)
            cla(app.UIAxes);
            plot(app.UIAxes, t, y, 'o','MarkerFaceColor',[0 0.4470 0.7410]);
            hold(app.UIAxes,'on');
            x = days(t - t(1));
            xx = linspace(min(x),max(x),200);
            yy = polyval(coeffs, xx);
            plot(app.UIAxes, t(1)+days(xx), yy, '-r','LineWidth',2);
            hold(app.UIAxes,'off');
            % Use datetime-friendly formatting rather than datetick
            % Use datetime-friendly tick formatting
            app.UIAxes.XLimMode = 'auto';
            xtickformat(app.UIAxes,'dd-MMM');
            grid(app.UIAxes,'on');
            xlabel(app.UIAxes,'Date');
            ylabel(app.UIAxes,'Temperature (°C)');
            title(app.UIAxes,'Temperature vs Time (linear fit)');
        end
    end

    methods (Access = public)
        function app = weatherRegressionApp
            % Construct app
            createComponents(app);

            % Show the figure
            movegui(app.UIFigure,'center');
        end

        function delete(app)
            % Clean up
            if isvalid(app.UIFigure)
                close(app.UIFigure);
            end
        end
    end
end