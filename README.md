# Weather Regression MATLAB App

This small MATLAB app fetches weather data (via OpenWeatherMap) or uses a built-in sample dataset, performs a linear regression of temperature vs time, and plots the result.

<img width="1204" height="827" alt="image" src="https://github.com/user-attachments/assets/79f65924-15da-4e57-bbcf-8a68b0d537be" />

Files added:
- `weatherRegressionApp.m` - main app class (programmatic App Designer-style app)
- `sampleWeatherData.m` - helper to provide demo data when no API key is available

How to run
1. Open MATLAB and add the folder to the path, or change folder to this project directory:

```matlab
cd('c:\\Users\\ydebray\\Downloads\\MCP-test')
```

2. Run the app by creating the app object:

```matlab
app = weatherRegressionApp;
```

3. Use the UI to either check "Use built-in sample data" or provide an OpenWeatherMap API key and city, then press "Fetch & Fit".

Notes
- If you choose to fetch live data, the app uses OpenWeatherMap geocoding and One Call APIs. You need an API key from https://openweathermap.org/.
- If your MATLAB does not have webread or network access, use the sample data option.
- This is a minimal example; extend it with more features (higher-order fits, selection of variables, error handling) as needed.
