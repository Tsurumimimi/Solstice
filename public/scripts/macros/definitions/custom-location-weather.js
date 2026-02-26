// 存储数据的变量
let currentLocation = "温暖的家";
let currentWeather = "晴好 25°C";

// 1. 获取位置和天气的核心函数 (这段你之前跑得很成功，保持原样)
async function fetchLocationWeather() {
    try {
        const geoRes = await fetch('https://ipinfo.io/json');
        const geoData = await geoRes.json();
        if (!geoData.city) throw new Error("定位数据为空");

        currentLocation = geoData.city;
        const [lat, lon] = geoData.loc.split(',').map(Number);

        const weatherRes = await fetch(
            `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current_weather=true`
        );
        const weatherData = await weatherRes.json();
        
        const weatherMap = {
            0: '晴', 1: '多云', 2: '少云', 3: '阴',
            45: '雾', 51: '小雨', 61: '中雨', 71: '小雪', 95: '雷暴'
        };
        const desc = weatherMap[weatherData.current_weather.weathercode] || '多云';
        currentWeather = `${desc} ${weatherData.current_weather.temperature}°C`;

        console.log("✅ 成功获取位置和天气:", currentLocation, currentWeather);
    } catch (err) {
        console.log("【天气宏】使用备用值，原因：", err.message);
    }
}

// 2. 动态注册全局宏（完美避开启动冲突，把 callback 改为官方要求的 handler）
async function registerGlobalMacros() {
    try {
        const { macros } = await import('../macro-system.js');

        // 注册 {{location}}
        macros.registry.registerMacro('location', {
            description: '当前所在城市',
            handler: () => currentLocation   // <--- 就是这里！把 callback 改成了 handler
        });

        // 注册 {{weather}}
        macros.registry.registerMacro('weather', {
            description: '当前天气与温度',
            handler: () => currentWeather    // <--- 还有这里！也改成了 handler
        });

        console.log("✅ 位置天气宏已成功写进全局户口本！这次真的一定行！");
    } catch (error) {
        console.error("❌ 宏注册失败:", error);
    }
}

// 3. 初始化执行
fetchLocationWeather();
registerGlobalMacros(); 
setInterval(fetchLocationWeather, 3600000); 
