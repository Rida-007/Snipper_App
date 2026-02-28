const { chromium } = require('playwright');

(async () => {
    const browser = await chromium.launch({
        channel: 'chrome',  // Uses your installed Chrome
        headless: false     // Opens visible browser
    });

    const page = await browser.newPage();
    await page.goto('https://www.amazon.in');

    console.log("Browser opened successfully!");

})();